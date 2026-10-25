import 'dart:convert' show jsonDecode, jsonEncode, utf8;

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agenda_terpadu.dart';
import '../models/keuangan.dart';
import '../utils/format.dart' show formatRupiah;
import '../utils/waktu.dart' show tanggalDariPortal;
import 'api_client.dart';

/// Gerbang notifikasi event — seam untuk [EventDiffService] supaya diff &
/// notifikasi bisa diuji tanpa menyentuh plugin asli. Pola sama dengan
/// [PengingatGateway] di `pengingat_jadwal_service.dart` (salinan kecil,
/// sengaja tidak diekstrak bersama agar file pengingat tidak tersentuh).
abstract class EventDiffGateway {
  /// Izin notifikasi (Android 13+) sudah diberikan?
  Future<bool> izinNotifikasiDiberikan();

  /// Tampilkan satu notifikasi langsung (immediate show).
  Future<void> tampilkan({
    required int id,
    required String title,
    required String body,
    required String payload,
  });
}

/// Implementasi nyata [EventDiffGateway] di atas FlutterLocalNotificationsPlugin
/// dengan instance plugin SENDIRI (terpisah dari pengingat jadwal & push).
/// Channel dibuat lazily sekali per proses — tidak butuh hook `main.dart`.
class FlutterLocalNotificationsEventDiffGateway implements EventDiffGateway {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _channelSiap = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> izinNotifikasiDiberikan() async {
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (e) {
      debugPrint('EventDiff: probe izin gagal (${e.runtimeType})');
      return false;
    }
  }

  @override
  Future<void> tampilkan({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_channelSiap) {
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          EventDiffService.channelId,
          EventDiffService.channelName,
          description: EventDiffService.channelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      );
      _channelSiap = true;
    }
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          EventDiffService.channelId,
          EventDiffService.channelName,
          channelDescription: EventDiffService.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: payload,
    );
  }
}

/// Snapshot ringkas satu jenis data (tagihan / ujian): jumlah item + kunci
/// kanonik tiap item. Dibandingkan nilai-nilai (bukan string mentah) agar
/// keputusan notifikasi stabil, lalu diserialisasi JSON ke SharedPreferences.
@visibleForTesting
class EventSnapshot {
  final int jumlah;
  final int total;
  final List<String> item;

  const EventSnapshot({
    required this.jumlah,
    this.total = 0,
    required this.item,
  });

  String keJson() => jsonEncode({
    'jumlah': jumlah,
    'total': total,
    'item': item,
  });

  static EventSnapshot? dariJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final items = decoded['item'];
    if (items is! List) return null;
    return EventSnapshot(
      jumlah: (decoded['jumlah'] as num?)?.toInt() ?? 0,
      total: (decoded['total'] as num?)?.toInt() ?? 0,
      item: items.whereType<String>().toList(growable: false),
    );
  }

  /// Kunci kanonik gabungan — digunakan id notifikasi deterministik.
  String get kunciGabungan => item.isEmpty ? '-' : item.join('\n');
}

/// Layanan notifikasi event berbasis diff LOKAL (Fase 2c): tanpa perubahan BE.
/// App menyimpan snapshot ringkas dari data yang SUDAH diambil halaman
/// (tagihan dari KeuanganPage, agenda/ujian dari Dashboard) dan menampilkan
/// local notification saat snapshot berubah:
///  * tagihan baru/berubah → "Tagihan baru" / "Tagihan berubah";
///  * jumlah jadwal ujian bertambah → "Jadwal ujian terbit";
///  * KRS di-SKIP (data KRS hanya dimuat di halaman KRS — integrasi butuh
///    fetch/hook tambahan di luar scope fase ini).
///
/// Pola mengikuti [PengingatJadwalService]: singleton + seam gateway,
/// kunci SharedPreferences ber-suffix NIM, id deterministik FNV-1a dengan
/// PREFIX NAMESPACE BERBEDA (`event-diff|`) agar tidak pernah bentrok dengan
/// id pengingat jadwal (`tipe|judul|...`). Seluruh proses fail-open: tidak
/// pernah melempar ke UI dan tidak pernah mengganggu alur halaman.
class EventDiffService {
  EventDiffService._();

  static final instance = EventDiffService._();

  static const channelId = 'event_kampus';
  static const channelName = 'Event Kampus';
  static const channelDescription =
      'Pemberitahuan tagihan baru dan jadwal ujian terbit';

  /// Kunci SharedPreferences (ber-suffix NIM bila tersedia).
  static const _kSnapTagihan = 'event_diff_snap_tagihan';
  static const _kSnapUjian = 'event_diff_snap_ujian';
  static const _kEvalTagihanAt = 'event_diff_eval_tagihan_at';
  static const _kEvalUjianAt = 'event_diff_eval_ujian_at';

  /// Debounce evaluasi per jenis: maksimum 1x per 5 menit.
  static const _debounce = Duration(minutes: 5);

  /// Override debounce hanya untuk pengujian.
  @visibleForTesting
  Duration debounceUntukTest = _debounce;

  /// Prefix namespace id — menjaga id event TIDAK pernah sama dengan id
  /// `PengingatJadwalService.idPengingatDariKunci` (kunci mentah tanpa prefix).
  static const _idNamespace = 'event-diff|';

  /// Single-flight: evaluasi bersamaan (dashboard + keuangan) diabaikan.
  bool _sedangBerjalan = false;

  EventDiffGateway _gateway = FlutterLocalNotificationsEventDiffGateway();

  /// Menyuntikkan gateway palsu untuk pengujian.
  @visibleForTesting
  void setGatewayUntukTest(EventDiffGateway gateway) {
    _gateway = gateway;
  }

  /// Mereset state singleton (single-flight + debounce). Hanya untuk pengujian.
  @visibleForTesting
  void resetUntukTest() {
    _sedangBerjalan = false;
    debounceUntukTest = _debounce;
  }

  /// Evaluasi snapshot TAGIHAN dari data yang sudah dimuat
  /// `KeuanganService.getTagihan()` di `_TagihanPembayaranTab`. Tidak pernah
  /// melempar — dipanggil `unawaited` dari halaman.
  Future<void> evaluasiTagihan(KeuanganTagihanResponse tagihan) async {
    if (_sedangBerjalan) return;
    _sedangBerjalan = true;
    try {
      await _evaluasi(
        prefsKeySnap: _kSnapTagihan,
        prefsKeyAt: _kEvalTagihanAt,
        baru: snapshotTagihan(tagihan),
        putuskan: _putuskanTagihan,
      );
    } catch (e) {
      debugPrint('EventDiff: evaluasi tagihan gagal (${e.runtimeType})');
    } finally {
      _sedangBerjalan = false;
    }
  }

  /// Evaluasi snapshot UJIAN (baris uts/uas agenda terpadu) dari data yang
  /// sudah dimuat `AkademikService.getAgendaTerpadu()` di Dashboard. Tidak
  /// pernah melempar — dipanggil `unawaited` dari halaman.
  Future<void> evaluasiAgenda(AgendaTerpaduData agenda) async {
    if (_sedangBerjalan) return;
    _sedangBerjalan = true;
    try {
      await _evaluasi(
        prefsKeySnap: _kSnapUjian,
        prefsKeyAt: _kEvalUjianAt,
        baru: snapshotUjian(agenda),
        putuskan: _putuskanUjian,
      );
    } catch (e) {
      debugPrint('EventDiff: evaluasi agenda gagal (${e.runtimeType})');
    } finally {
      _sedangBerjalan = false;
    }
  }

  /// Hapus snapshot + timestamp evaluasi milik NIM aktif saat logout. Pola
  /// loop sama dengan [PengingatJadwalService.bersihkanSaatLogout]; wajib
  /// dipanggil SEBELUM `ApiClient.instance.fullLogout`. Tidak pernah melempar.
  Future<void> bersihkanSaatLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suffix = _suffixNim();
      for (final s in [suffix, '']) {
        await prefs.remove('$_kSnapTagihan$s');
        await prefs.remove('$_kSnapUjian$s');
        await prefs.remove('$_kEvalTagihanAt$s');
        await prefs.remove('$_kEvalUjianAt$s');
      }
    } catch (e) {
      debugPrint('EventDiff: pembersihan logout gagal (${e.runtimeType})');
    }
  }

  // ── Inti evaluasi ─────────────────────────────────────────────────────────

  Future<void> _evaluasi({
    required String prefsKeySnap,
    required String prefsKeyAt,
    required EventSnapshot baru,
    required (String, String)? Function(EventSnapshot baru, EventSnapshot lama)
    putuskan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final suffix = _suffixNim();

    // Debounce: evaluasi maksimum 1x per [debounceUntukTest] per jenis.
    final lastAt = prefs.getInt('$prefsKeyAt$suffix') ?? 0;
    final sekarang = DateTime.now().millisecondsSinceEpoch;
    if (lastAt > 0 &&
        Duration(milliseconds: sekarang - lastAt) < debounceUntukTest) {
      return;
    }

    // Snapshot lama: korup → diperlakukan belum-ada (pertama kali: hanya
    // simpan, tidak berisik) — fail-open.
    EventSnapshot? lama;
    final rawLama = prefs.getString('$prefsKeySnap$suffix');
    if (rawLama != null && rawLama.isNotEmpty) {
      try {
        lama = EventSnapshot.dariJson(rawLama);
      } catch (e) {
        debugPrint('EventDiff: snapshot korup (${e.runtimeType})');
      }
    }

    // Timpa snapshot + timestamp SEKARANG: perubahan yang sama tidak akan
    // menotif dua kali, dan debounce mulai dihitung dari siklus ini.
    await prefs.setString('$prefsKeySnap$suffix', baru.keJson());
    await prefs.setInt('$prefsKeyAt$suffix', sekarang);

    // Pertama kali (atau snapshot lama tak terbaca): hanya simpan.
    if (lama == null) return;
    if (_snapshotSetara(lama, baru)) return;

    final keputusan = putuskan(baru, lama);
    if (keputusan == null) return; // jenis tidak memenuhi syarat notifikasi
    final (judul, isi) = keputusan;

    // Izin belum diberikan (atau probe gagal) → skip diam.
    if (!await _gateway.izinNotifikasiDiberikan()) {
      debugPrint('EventDiff: izin notifikasi belum diberikan, dilewati');
      return;
    }

    try {
      await _gateway.tampilkan(
        id: idEventDariJenis(prefsKeySnap),
        title: judul,
        body: isi,
        payload: '',
      );
    } catch (e) {
      debugPrint('EventDiff: gagal menampilkan notif (${e.runtimeType})');
    }
  }

  /// Dua snapshot dianggap setara bila jumlah + total + daftar item sama.
  bool _snapshotSetara(EventSnapshot a, EventSnapshot b) =>
      a.jumlah == b.jumlah && a.total == b.total && a.kunciGabungan == b.kunciGabungan;

  // ── Keputusan notifikasi per jenis ────────────────────────────────────────

  /// Tagihan: setiap perubahan dinotifikasi. Judul "Tagihan baru" bila jumlah
  /// item bertambah, selain itu "Tagihan berubah".
  (String, String)? _putuskanTagihan(EventSnapshot baru, EventSnapshot lama) {
    final judul = baru.jumlah > lama.jumlah
        ? 'Tagihan baru'
        : 'Tagihan berubah';
    final isi = 'Total tagihan sekarang ${formatRupiah(baru.total)} '
        '(${baru.jumlah} item)';
    return (judul, isi);
  }

  /// Ujian: hanya saat jumlah baris ujian BERTAMBAH ("jadwal ujian terbit").
  /// Konten berubah tanpa bertambah / berkurang → tanpa notif (dokumentasi).
  (String, String)? _putuskanUjian(EventSnapshot baru, EventSnapshot lama) {
    if (baru.jumlah <= lama.jumlah) return null;
    return (
      'Jadwal ujian terbit',
      '${baru.jumlah} mata kuliah terjadwal — cek di menu Jadwal',
    );
  }

  // ── Snapshot ringkas (pure, teruji) ───────────────────────────────────────

  /// Tagihan = jumlah tagihan + total_tagihan + daftar `idtrans|nominal`
  /// terurut (urutan server boleh berubah tanpa makna).
  @visibleForTesting
  static EventSnapshot snapshotTagihan(KeuanganTagihanResponse tagihan) {
    final item = [
      for (final t in tagihan.data) '${t.idtrans}|${t.nominal}',
    ]..sort();
    return EventSnapshot(
      jumlah: tagihan.data.length,
      total: tagihan.totalTagihan,
      item: item,
    );
  }

  /// Ujian = jumlah baris uts/uas yang membawa tanggal valid + daftar
  /// `matakuliah|jamMulai|tanggal` terurut (analog `kode|tanggal` — baris
  /// agenda tidak punya kode; jam disertakan agar berubah jam juga terdiff).
  /// Baris tanpa/tanggal tak terbaca dilewati (fail-open, konsisten gerbang
  /// ujian & pengingat).
  @visibleForTesting
  static EventSnapshot snapshotUjian(AgendaTerpaduData agenda) {
    final item = <String>[];
    for (final rows in agenda.agenda.values) {
      for (final it in rows) {
        final tipe = it.tipe.trim().toLowerCase();
        if (tipe != 'uts' && tipe != 'uas') continue;
        final tgl = tanggalDariPortal(it.tanggal ?? '');
        if (tgl == null) continue;
        item.add('${it.matakuliah.trim()}|${it.jamMulai.trim()}|'
            '${tgl.year.toString().padLeft(4, '0')}-'
            '${tgl.month.toString().padLeft(2, '0')}-'
            '${tgl.day.toString().padLeft(2, '0')}');
      }
    }
    item.sort();
    return EventSnapshot(jumlah: item.length, item: item);
  }

  // ── Id deterministik (namespace sendiri) ──────────────────────────────────

  /// Id notifikasi deterministik: FNV-1a 32-bit atas `$idNamespace$jenis`,
  /// dimasker 31 bit (pola `PushService.displayIdDari`). Prefix `event-diff|`
  /// menjaga id ini tidak pernah sama dengan id pengingat jadwal yang memakai
  /// kunci mentah `tipe|judul|tanggal|jam` (salinan kecil `fnv1a32` dari
  /// `PengingatJadwalService` — tidak diekstrak bersama agar file itu
  /// tidak tersentuh).
  @visibleForTesting
  static int idEventDariJenis(String jenis) =>
      fnv1a32('$_idNamespace$jenis') & 0x7fffffff;

  /// FNV-1a 32-bit atas UTF-8 bytes dari [s] — salinan
  /// `PengingatJadwalService.fnv1a32` (lihat komentar di atas).
  @visibleForTesting
  static int fnv1a32(String s) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(s)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  String _suffixNim() {
    final nim = ApiClient.instance.nim;
    return (nim != null && nim.isNotEmpty) ? '_$nim' : '';
  }
}

import 'dart:async' show unawaited;
import 'dart:convert' show jsonDecode, jsonEncode, utf8;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/agenda_terpadu.dart';
import '../models/jadwal_ujian.dart';
import '../utils/format.dart' show dayValue, formatDateApi;
import '../utils/waktu.dart';
import 'akademik_service.dart';
import 'api_client.dart';

/// Gerbang notifikasi terjadwal — seam untuk [PengingatJadwalService] supaya
/// penjadwalan bisa diuji tanpa menyentuh plugin/Firebase asli.
abstract class PengingatGateway {
  /// Membuat channel notifikasi Android (idempotent). Di-iOS no-op.
  Future<void> siapkanChannel();

  /// Izin notifikasi (Android 13+) sudah diberikan?
  Future<bool> izinNotifikasiDiberikan();

  /// Perangkat boleh menjadwalkan alarm EKSAKT (Android 12+: izin alarm).
  Future<bool> canScheduleExact();

  /// Jadwalkan satu notifikasi one-shot pada [scheduledDate].
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  });

  /// Batalkan satu notifikasi terjadwal ber-id [id].
  Future<void> cancel(int id);

  /// Batalkan beberapa notifikasi terjadwal sekaligus.
  Future<void> cancelAllIds(List<int> ids);
}

/// Implementasi nyata [PengingatGateway] di atas FlutterLocalNotificationsPlugin
/// (docs v22: `zonedSchedule` + channel Android + receiver terjadwal di
/// AndroidManifest). iOS: `zonedSchedule` juga tersedia — kode ini siap dipakai
/// bila iOS ditambahkan (channel Android diabaikan otomatis).
class FlutterLocalNotificationsPengingatGateway implements PengingatGateway {
  const FlutterLocalNotificationsPengingatGateway();

  static const _channelId = PengingatJadwalService.channelId;
  static const _channelName = PengingatJadwalService.channelName;
  static const _channelDescription =
      PengingatJadwalService.channelDescription;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> siapkanChannel() async {
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  @override
  Future<bool> izinNotifikasiDiberikan() async {
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (e) {
      debugPrint('PengingatJadwal: probe izin gagal (${e.runtimeType})');
      return false;
    }
  }

  @override
  Future<bool> canScheduleExact() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (e) {
      debugPrint('PengingatJadwal: probe alarm eksak gagal (${e.runtimeType})');
      return false;
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    final exact = await canScheduleExact();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAllIds(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }
}

/// Satu kejadian pengingat: kelas/ujian yang akan mendapat notifikasi lokal
/// 30 menit sebelum jam mulai.
@visibleForTesting
class KejadianPengingat {
  final String tipe; // 'kuliah' | 'asisten' | 'uts' | 'uas'
  final String judul;
  final DateTime tanggal; // tengah malam hari kejadian (waktu lokal)
  final int jamMulaiMins; // menit sejak tengah malam
  final String ruang;

  const KejadianPengingat({
    required this.tipe,
    required this.judul,
    required this.tanggal,
    required this.jamMulaiMins,
    required this.ruang,
  });

  int get notifJam => (jamMulaiMins - 30) ~/ 60;
  int get notifMenit => (jamMulaiMins - 30) % 60;
  String get jamMulaiLabel {
    final h = (jamMulaiMins ~/ 60).toString().padLeft(2, '0');
    final m = (jamMulaiMins % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Konten notifikasi (Bahasa Indonesia), contoh:
  /// "Pemrograman Web mulai 30 menit lagi (08:00, Ruang LT2)".
  String isi() {
    final ruangBersih = ruang.trim();
    final ruangBagian =
        (ruangBersih.isEmpty || ruangBersih == '-') ? '' : ', $ruangBersih';
    return '$judul mulai 30 menit lagi ($jamMulaiLabel$ruangBagian)';
  }

  /// Kunci kanonik untuk hash diff & id deterministik:
  /// `tipe|judul|yyyy-MM-dd|HH:mm` (jam = jam MULAI kejadian).
  String get kunciKanonik =>
      '$tipe|$judul|${formatDateApi(tanggal)}|$jamMulaiLabel';
}

/// Layanan pengingat jadwal: notifikasi lokal one-shot "30 menit sebelum
/// kelas/ujian" untuk SEMUA tipe agenda (kuliah, asisten, UTS/UAS), dijadwalkan
/// untuk 14 hari ke depan, melewati hari libur nasional/cuti bersama,
/// default-on tanpa toggle.
///
/// Pola mengikuti [PushService]: singleton + seam [PengingatGateway] agar
/// unit test tidak menyentuh plugin/Firebase asli. Seluruh proses tidak pernah
/// melempar ke UI — kegagalan hanya dilog.
class PengingatJadwalService {
  PengingatJadwalService._();

  static final instance = PengingatJadwalService._();

  static const channelId = 'pengingat_jadwal';
  static const channelName = 'Pengingat Jadwal';
  static const channelDescription =
      'Pengingat 30 menit sebelum kelas atau ujian dimulai';

  /// Jumlah hari ke depan yang dipetakan (14 hari, termasuk hari ini).
  @visibleForTesting
  static const jendelaHari = 14;

  /// ICS libur nasional Indonesia (Google Calendar publik). Diambil lewat
  /// instance Dio TERPISAH — bukan ApiClient.instance.dio — agar tidak kena
  /// interceptor 401/refresh token.
  static const _icsLiburUrl =
      'https://calendar.google.com/calendar/ical/'
      'id.indonesian%23holiday%40group.v.calendar.google.com/public/basic.ics';

  /// Kunci SharedPreferences (ber-suffix NIM bila tersedia): cache agenda.
  static const _kCacheAgenda = 'pengingat_jadwal_cache_agenda';
  /// Registry id notifikasi terjadwal (daftar angka).
  static const _kRegistry = 'pengingat_jadwal_registry';
  /// Hash kanonik daftar kejadian terakhir yang dijadwalkan.
  static const _kHash = 'pengingat_jadwal_hash';
  /// Cache tanggal libur ('yyyy-MM-dd') + waktu pembaruan (epoch ms).
  static const _kLibur = 'pengingat_jadwal_libur';
  static const _kLiburAt = 'pengingat_jadwal_libur_at';

  /// Umur maksimal cache libur sebelum refresh dipicu (fire-and-forget).
  static const _umurCacheLiburMaks = Duration(days: 7);

  /// Single-flight: bila sudah berjalan, pemanggil kedua diabaikan (melindungi
  /// refresh token single-use dari fetch paralel ganda — dua hook bisa nyaris
  /// bersamaan).
  bool _sedangBerjalan = false;

  PengingatGateway _gateway = const FlutterLocalNotificationsPengingatGateway();

  /// Sumber ICS libur — hanya untuk pengujian (default: fetch Google iCal
  /// dengan Dio terpisah). Test menyuntikkan fetcher yang gagal agar siklus
  /// tidak menyentuh jaringan.
  @visibleForTesting
  Future<String> Function()? ambilIcsLiburUntukTest;

  final Dio _liburDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Membuat channel notifikasi. Dipanggil sekali dari `main.dart` (terpisah
  /// dari blok Firebase supaya pengingat tetap hidup walau push gagal).
  Future<void> init() => _gateway.siapkanChannel();

  /// Menyuntikkan gateway palsu untuk pengujian.
  @visibleForTesting
  void setGatewayUntukTest(PengingatGateway gateway) {
    _gateway = gateway;
  }

  /// Mereset state singleton (single-flight). Hanya untuk pengujian.
  @visibleForTesting
  void resetUntukTest() {
    _sedangBerjalan = false;
  }

  /// Titik masuk utama — hook: setelah login sukses, post-frame [MainPage].
  /// Tidak pernah melempar.
  Future<void> perbaruiPengingat() async {
    if (_sedangBerjalan) return;
    _sedangBerjalan = true;
    try {
      await _perbaruiInternal();
    } catch (e) {
      // Kesalahan tak terduga tidak boleh mengganggu alur login/aplikasi.
      debugPrint('PengingatJadwal: pembaruan gagal (${e.runtimeType})');
    } finally {
      _sedangBerjalan = false;
    }
  }

  Future<void> _perbaruiInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final suffix = _suffixNim();

    // Izin notifikasi belum ada → lewati penjadwalan diam-diam. Cek lebih awal
    // supaya tidak ada fetch/cache yang dikerjakan sia-sia.
    if (!await _gateway.izinNotifikasiDiberikan()) {
      debugPrint('PengingatJadwal: izin notifikasi belum diberikan, dilewati');
      return;
    }

    final tanggalLibur = await _muatLibur(prefs, suffix);

    // Agenda: fetch (dibungkus ApiClient.guard → AppFailure). Gagal → cache;
    // cache juga kosong → pertahankan alarm & registry basi, keluar diam-diam.
    AgendaTerpaduData? agenda;
    try {
      agenda = await AkademikService().getAgendaTerpadu();
    } catch (e) {
      // Termasuk 401 (sesi belum pulih): jangan hapus jadwal lama.
      debugPrint('PengingatJadwal: fetch agenda gagal (${e.runtimeType})');
    }
    if (agenda != null) {
      try {
        await prefs.setString('$_kCacheAgenda$suffix', _agendaKeJson(agenda));
      } catch (e) {
        debugPrint('PengingatJadwal: gagal menyimpan cache agenda (${e.runtimeType})');
      }
    } else {
      agenda = _agendaDariCache(prefs, suffix);
    }
    if (agenda == null) return;

    // Kejadian ujian kini dibangun dari jadwal-ujian (UTS + UAS), bukan lagi
    // regex tanggal pada field `detail` agenda. Fetch paralel; gagal → list
    // kosong (fail-open: tanpa reminder ujian pada siklus ini, sisa jadwal
    // tetap jalan) — konsisten dengan fail-open agenda.
    final ujian = <(JadwalUjian, String)>[];
    try {
      final hasil = await Future.wait([
        AkademikService().getJadwalUjian('uts'),
        AkademikService().getJadwalUjian('uas'),
      ]);
      for (final baris in hasil[0]) {
        ujian.add((baris, 'uts'));
      }
      for (final baris in hasil[1]) {
        ujian.add((baris, 'uas'));
      }
    } catch (e) {
      debugPrint('PengingatJadwal: fetch jadwal-ujian gagal (${e.runtimeType})');
    }

    final kejadian = hitungKejadian(
      agenda: agenda,
      ujianBerjadwal: ujian,
      sekarang: tz.TZDateTime.now(tz.local),
      tanggalLibur: tanggalLibur,
    );
    final hash = hashKejadian(kejadian).toString();
    final hashLama = prefs.getString('$_kHash$suffix');
    final registryLama = _bacaRegistry(prefs, suffix);

    if (hash == hashLama && registryLama.isNotEmpty) {
      // Tidak ada perubahan — jangan reschedule (idempoten).
      return;
    }

    await _gateway.cancelAllIds(registryLama);

    final registryBaru = <int>[];
    for (final k in kejadian) {
      final id = idPengingatDariKunci(k.kunciKanonik);
      final tanggalJadwal = tz.TZDateTime(
        tz.local,
        k.tanggal.year,
        k.tanggal.month,
        k.tanggal.day,
        k.notifJam,
        k.notifMenit,
      );
      try {
        await _gateway.schedule(
          id: id,
          title: channelName,
          body: k.isi(),
          scheduledDate: tanggalJadwal,
          payload: '',
        );
        registryBaru.add(id);
      } catch (e) {
        debugPrint('PengingatJadwal: gagal menjadwalkan (${e.runtimeType})');
      }
    }

    await prefs.setStringList(
      '$_kRegistry$suffix',
      registryBaru.map((e) => e.toString()).toList(),
    );
    await prefs.setString('$_kHash$suffix', hash);
  }

  /// Hapus semua pengingat + cache (agenda/hash/registry/libur) saat logout.
  /// Dipanggil dari titik logout SEBELUM `fullLogout` (urutan yang sama dengan
  /// `PushService.bersihkanSaatLogout`).
  Future<void> bersihkanSaatLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suffix = _suffixNim();
      // Bersihkan kunci milik NIM aktif maupun kunci tanpa suffix.
      for (final s in [suffix, '']) {
        final registry = _bacaRegistry(prefs, s);
        if (registry.isNotEmpty) {
          try {
            await _gateway.cancelAllIds(registry);
          } catch (e) {
            debugPrint('PengingatJadwal: gagal membatalkan alarm (${e.runtimeType})');
          }
        }
        await prefs.remove('$_kCacheAgenda$s');
        await prefs.remove('$_kRegistry$s');
        await prefs.remove('$_kHash$s');
        await prefs.remove('$_kLibur$s');
        await prefs.remove('$_kLiburAt$s');
      }
    } catch (e) {
      debugPrint('PengingatJadwal: pembersihan logout gagal (${e.runtimeType})');
    }
  }

  // ── Komputasi kejadian ────────────────────────────────────────────────────

  /// Hitung daftar kejadian untuk [jendelaHari] hari ke depan:
  ///  * kuliah/asisten → setiap kemunculan hari-nya dalam jendela (mis. Senin
  ///    muncul 2x), diambil dari bucket hari yang cocok;
  ///  * ujian → dibangun dari [ujianBerjadwal] (baris jadwal-ujian + tipe
  ///    'uts'/'uas', ditemparalel-fetch dari perbaruiPengingat): MKL = judul,
  ///    TANGGAL/TGL_UJIAN = tanggal, JAM_MULAI = jam, RUANG = ruang;
  ///  * baris ujian dari agenda (tipe uts/uas) TIDAK lagi menghasilkan
  ///    kejadian — tanggalnya tidak bisa dibaca dari field `detail`;
  ///  * tanggal libur ([tanggalLibur], 'yyyy-MM-dd') dilewati;
  ///  * kejadian hari ini yang waktunya sudah lewat dilewati;
  ///  * item tanpa jam dan baris ujian ber-tanggal tak terbaca dilewati.
  @visibleForTesting
  static List<KejadianPengingat> hitungKejadian({
    required AgendaTerpaduData agenda,
    List<(JadwalUjian, String)> ujianBerjadwal =
        const <(JadwalUjian, String)>[],
    required DateTime sekarang,
    required Set<String> tanggalLibur,
  }) {
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final nowMins = sekarang.hour * 60 + sekarang.minute;
    final akhirJendela = hariIni.add(const Duration(days: jendelaHari - 1));

    final hasil = <int, KejadianPengingat>{};

    void tambah(AgendaItem item, DateTime tanggal) {
      final tipe = item.tipe.trim().toLowerCase();
      final judul = judulPengingat(item);
      if (judul.isEmpty) return;
      // Marker kosong portal ('-' dan string kosong) = tanpa jam — sama
      // dengan aturan tampil jadwal_page; tanpa ini rentang (0,0) palsu bisa
      // terjadwal pada 23:30 hari sebelumnya.
      if (jamChip(item) == '-') return;
      final range = ongoingRange(item);
      if (range == null) return; // item tanpa jam dilewati
      final (start, end) = range;
      if (start == 0 && end == 0) return; // rentang tak terbaca
      // Kelas mulai 00:00–00:29: pengingat -30 menit akan jatuh setelah jam
      // mulai (atau hari sebelumnya) — lebih baik dilewati daripada menyesatkan.
      if (start < 30) return;
      final tgl = DateTime(tanggal.year, tanggal.month, tanggal.day);
      if (tanggalLibur.contains(formatDateApi(tgl))) return;
      if (tgl.isAtSameMomentAs(hariIni) && start <= nowMins) {
        return; // waktunya sudah lewat hari ini
      }
      final k = KejadianPengingat(
        tipe: tipe.isEmpty ? 'kuliah' : tipe,
        judul: judul,
        tanggal: tgl,
        jamMulaiMins: start,
        ruang: item.ruang,
      );
      hasil[idPengingatDariKunci(k.kunciKanonik)] = k;
    }

    for (final entry in agenda.agenda.entries) {
      final dv = dayValue(entry.key);
      final hariBiasa = dv >= 1 && dv <= 7;

      for (final item in entry.value) {
        final tipe = item.tipe.trim().toLowerCase();
        if (tipe == 'uts' || tipe == 'uas') {
          // Ujian dari agenda dilewati: kejadian ujian kini bersumber dari
          // jadwal-ujian ([ujianBerjadwal]), bukan field `detail` agenda.
          continue;
        }
        // Kuliah/asisten: setiap kemunculan hari dalam jendela.
        if (!hariBiasa) continue;
        for (var i = 0; i < jendelaHari; i++) {
          final t = hariIni.add(Duration(days: i));
          if (t.weekday != dv) continue;
          tambah(item, t);
        }
      }
    }

    // Ujian dari jadwal-ujian: satu kejadian per baris, aturan sama seperti
    // kelas (jendela 14 hari, skip libur, skip yang sudah lewat, skip mulai
    // <30 menit).
    for (final (baris, tipe) in ujianBerjadwal) {
      final tgl = tanggalDariDdMmYyyy(baris.tanggal);
      if (tgl == null) continue; // tanggal tak terbaca → dilewati tanpa error
      if (tgl.isBefore(hariIni) || tgl.isAfter(akhirJendela)) continue;
      final jamMulai = baris.jamMulai.trim();
      if (jamMulai.isEmpty || jamMulai == '-') continue;
      final start = timeToMinutes(jamMulai);
      if (start < 30) continue; // sama seperti kelas (termasuk tak terbaca = 0)
      if (tanggalLibur.contains(formatDateApi(tgl))) continue;
      // Sama seperti jalur kelas: ujian hari ini yang jamnya sudah lewat tidak
      // boleh dijadwalkan — alarm exact akan menembak segera di masa lampau.
      if (tgl.isAtSameMomentAs(hariIni) && start <= nowMins) continue;
      final mk = baris.mkl.trim();
      final k = KejadianPengingat(
        tipe: tipe,
        judul: mk.isEmpty ? 'Ujian' : 'Ujian $mk',
        tanggal: tgl,
        jamMulaiMins: start,
        ruang: baris.ruang,
      );
      hasil[idPengingatDariKunci(k.kunciKanonik)] = k;
    }

    final daftar = hasil.values.toList()
      ..sort((a, b) {
        final byTanggal = a.tanggal.compareTo(b.tanggal);
        if (byTanggal != 0) return byTanggal;
        return a.jamMulaiMins.compareTo(b.jamMulaiMins);
      });
    return daftar;
  }

  /// Judul yang dipakai di isi notifikasi: judul matakuliah + komponen
  /// teori/praktek untuk tipe kuliah, dan pil tipe ujian — "Ujian" diikuti
  /// matakuliah — untuk uts/uas.
  @visibleForTesting
  static String judulPengingat(AgendaItem item) {
    final tipe = item.tipe.trim().toLowerCase();
    final mk = item.matakuliah.trim();
    if (tipe == 'uts' || tipe == 'uas') {
      return mk.isEmpty ? 'Ujian' : 'Ujian $mk';
    }
    final komponen = (item.komponen ?? '').trim().toLowerCase();
    if (tipe == 'kuliah' && komponen.isNotEmpty) {
      final label = switch (komponen) {
        'teori' => 'Teori',
        'praktek' => 'Praktek',
        _ => komponen,
      };
      return mk.isEmpty ? label : '$mk · $label';
    }
    return mk;
  }

  // ── Libur (ICS Google Calendar, fire-and-forget) ──────────────────────────

  /// Muat tanggal libur dari cache. Bila cache basi (>7 hari) atau kosong,
  /// refresh dipicu fire-and-forget — hasilnya dipakai siklus BERIKUTNYA,
  /// siklus ini memakai cache yang ada (gagal fetch → cache; cache kosong →
  /// tanpa skip, default aman).
  Future<Set<String>> _muatLibur(SharedPreferences prefs, String suffix) async {
    final cache = prefs.getStringList('$_kLibur$suffix') ?? const [];
    final updatedAt = prefs.getInt('$_kLiburAt$suffix') ?? 0;
    final umur = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
    if (cache.isEmpty || umur > _umurCacheLiburMaks) {
      unawaited(_refreshLibur(prefs, suffix));
    }
    return cache.toSet();
  }

  Future<void> _refreshLibur(SharedPreferences prefs, String suffix) async {
    try {
      final body = ambilIcsLiburUntukTest != null
          ? await ambilIcsLiburUntukTest!()
          : (await _liburDio.get<String>(
              _icsLiburUrl,
              options: Options(responseType: ResponseType.plain),
            ))
                .data;
      final libur = parseIcsLibur(body ?? '');
      // ICS kosong / gagal parse: pertahankan cache lama, jangan dihapus.
      if (libur.isEmpty) return;
      await prefs.setStringList(
        '$_kLibur$suffix',
        libur.map(formatDateApi).toList(),
      );
      await prefs.setInt('$_kLiburAt$suffix', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Gagal jaringan/parse: cache (atau kosong) dipakai — bukan alasan gagal.
      debugPrint('PengingatJadwal: refresh libur gagal (${e.runtimeType})');
    }
  }

  /// Parser ICS minimal untuk daftar libur: unfold lines, ambil DTSTART
  /// (VALUE=DATE maupun datetime) + SUMMARY tiap VEVENT, dan pertahankan HANYA
  /// entri yang SUMMARY-nya mengandung "libur" atau "Cuti Bersama"
  /// (case-insensitive) — filter berbasis SUMMARY, bukan DESCRIPTION.
  @visibleForTesting
  static List<DateTime> parseIcsLibur(String body) {
    if (body.trim().isEmpty) return const [];

    // Unfold lines: baris lanjutan diawali spasi/tab menempel ke baris atas.
    final lines = <String>[];
    for (final raw in body.split('\n')) {
      final line = raw.replaceAll('\r', '');
      if (line.startsWith(' ') || line.startsWith('\t')) {
        if (lines.isNotEmpty) {
          lines[lines.length - 1] += line.substring(1);
        }
      } else {
        lines.add(line);
      }
    }

    final hasil = <DateTime>{};
    DateTime? dtstart;
    String? summary;
    void tutupEvent() {
      final tgl = dtstart;
      final s = (summary ?? '').toLowerCase();
      if (tgl != null && (s.contains('libur') || s.contains('cuti bersama'))) {
        hasil.add(DateTime(tgl.year, tgl.month, tgl.day));
      }
      dtstart = null;
      summary = null;
    }

    for (final line in lines) {
      if (line.startsWith('BEGIN:VEVENT')) {
        dtstart = null;
        summary = null;
        continue;
      }
      if (line.startsWith('DTSTART')) {
        final idx = line.indexOf(':');
        if (idx != -1) {
          final nilai = line.substring(idx + 1).trim();
          final m = RegExp(r'^(\d{8})').firstMatch(nilai);
          if (m != null) {
            final y = int.tryParse(m.group(1)!.substring(0, 4));
            final mo = int.tryParse(m.group(1)!.substring(4, 6));
            final d = int.tryParse(m.group(1)!.substring(6, 8));
            if (y != null && mo != null && d != null) {
              dtstart = DateTime(y, mo, d);
            }
          }
        }
        continue;
      }
      if (line.startsWith('SUMMARY')) {
        final idx = line.indexOf(':');
        if (idx != -1) summary = line.substring(idx + 1).trim();
        continue;
      }
      if (line.startsWith('END:VEVENT')) tutupEvent();
    }

    final daftar = hasil.toList()..sort();
    return daftar;
  }

  // ── Idempotensi, id & cache ───────────────────────────────────────────────

  /// Hash kanonik daftar kejadian untuk diff: FNV-1a atas kunci kanonik yang
  /// diurutkan — deterministik antar proses (bukan String.hashCode).
  @visibleForTesting
  static int hashKejadian(List<KejadianPengingat> kejadian) {
    final kunci = (kejadian.map((k) => k.kunciKanonik).toList()..sort()).join(
      '\n',
    );
    return fnv1a32('pengingat-hash\n$kunci');
  }

  /// Id notifikasi deterministik STABIL: FNV-1a 32-bit atas kunci kanonik
  /// (bukan String.hashCode — tidak stabil antar versi SDK), dimasker ke 31 bit
  /// sesuai pola [PushService.displayIdDari].
  @visibleForTesting
  static int idPengingatDariKunci(String kunciKanonik) =>
      fnv1a32(kunciKanonik) & 0x7fffffff;

  /// FNV-1a 32-bit atas UTF-8 bytes dari [s].
  @visibleForTesting
  static int fnv1a32(String s) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(s)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  List<int> _bacaRegistry(SharedPreferences prefs, String suffix) {
    final raw = prefs.getStringList('$_kRegistry$suffix') ?? const [];
    return raw
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList(growable: false);
  }

  AgendaTerpaduData? _agendaDariCache(SharedPreferences prefs, String suffix) {
    final raw = prefs.getString('$_kCacheAgenda$suffix');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AgendaTerpaduData.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('PengingatJadwal: cache agenda korup (${e.runtimeType})');
    }
    return null;
  }

  /// Serialisasi agenda minimal (map bucket → list item) — bentuk sama dengan
  /// `AgendaTerpaduData.fromJson` sehingga cache bisa dinyah-serialisasi ulang.
  String _agendaKeJson(AgendaTerpaduData agenda) => jsonEncode({
        'total_agenda': agenda.totalAgenda,
        'agenda': {
          for (final entry in agenda.agenda.entries)
            entry.key: [
              for (final item in entry.value)
                {
                  'tipe': item.tipe,
                  'hari': item.hari,
                  'jam': item.jam,
                  'jam_mulai': item.jamMulai,
                  'jam_selesai': item.jamSelesai,
                  'ruang': item.ruang,
                  'matakuliah': item.matakuliah,
                  'detail': item.detail,
                  if (item.komponen != null) 'komponen': item.komponen,
                },
            ],
        },
      });

  String _suffixNim() {
    final nim = ApiClient.instance.nim;
    return (nim != null && nim.isNotEmpty) ? '_$nim' : '';
  }
}

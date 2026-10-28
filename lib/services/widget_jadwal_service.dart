import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:home_widget/home_widget.dart';

import '../models/agenda_terpadu.dart';
import '../utils/waktu.dart';
import 'agenda_cache_service.dart';

/// Seam penyimpanan widget supaya unit test tidak menyentuh plugin
/// home_widget (pola `PengingatGateway` / `EventDiffGateway`).
abstract class WidgetJadwalGateway {
  Future<void> simpanData(String kunci, String? nilai);
  Future<void> perbaruiWidget();
}

class HomeWidgetGateway implements WidgetJadwalGateway {
  @override
  Future<void> simpanData(String kunci, String? nilai) async {
    await HomeWidget.saveWidgetData<String>(kunci, nilai);
  }

  @override
  Future<void> perbaruiWidget() async {
    await HomeWidget.updateWidget(androidName: 'JadwalWidgetProvider');
  }
}

/// Pembaruan widget home screen "Jadwal Hari Ini" (Fase 4).
///
/// Aliran data sesuai kesepakatan user: widget TIDAK pernah fetch dan TIDAK
/// butuh sesi login — ia hanya membaca cache agenda (stale-while-revalidate,
/// [AgendaCacheService]).
///
/// Yang ditulis Dart bukan lagi baris "hari ini" (versi pertama membuat data
/// membeku di hari terakhir kali app dibuka — bug ditemukan pemakaian nyata:
/// seminggu tanpa buka app, widget masih menampilkan jadwal hari pemasangan).
/// Kini Dart menulis SATU kunci `jadwal_json`: peta baris siap-tampil per
/// kunci — nama hari (kuliah/asisten mingguan) dan tanggal ISO `yyyy-MM-dd`
/// (ujian dengan field `tanggal`) — lalu provider native mengambil baris
/// sesuai tanggal perangkat SETIAP kali dirender, termasuk tick periodik
/// `updatePeriodMillis` sehingga pergantian hari terjadi tanpa membuka app.
///
/// Seluruh method publik fail-open: tidak pernah melempar ke pemanggil.
class WidgetJadwalService {
  WidgetJadwalService._();

  static final instance = WidgetJadwalService._();

  /// Nama class provider native — harus cocok dengan receiver di manifest.
  static const namaProviderAndroid = 'JadwalWidgetProvider';

  /// Kunci tunggal yang dibaca provider native (di-null-kan saat logout —
  /// saveWidgetData(nil) menghapus entri di sisi native).
  static const kunciJadwalJson = 'jadwal_json';

  static const _maksBaris = 4;

  /// Tanggal ISO ujian `yyyy-MM-dd` (perjanjian BE 2026-10-25).
  static final _polaTanggalIso = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  WidgetJadwalGateway _gateway = HomeWidgetGateway();

  @visibleForTesting
  void gantiGatewayUntukTest(WidgetJadwalGateway gateway) {
    _gateway = gateway;
  }

  /// Teks satu baris widget: "09:00 · Pemrograman Web · LT2".
  static String _barisItem(AgendaItem item) =>
      '${jamChip(item)} · ${item.matakuliah}'
      '${item.ruang.isEmpty ? '' : ' · ${item.ruang}'}';

  /// Baris siap-tampil untuk [hariIni]: kuliah/asisten dari kunci nama hari,
  /// ujian dari kunci tanggal ISO — digabung (kelas dulu, ujian menyusul),
  /// maks [_maksBaris]. Pure — dipakai test sebagai referensi perilaku native.
  @visibleForTesting
  static List<String> barisHariIni(AgendaTerpaduData? data, DateTime hariIni) {
    if (data == null) return const [];
    final peta = petaMingguan(data);
    return [
      ...(peta[namaHariDariWeekday(hariIni.weekday)] ?? const <String>[]),
      ...(peta[_tanggalIso(hariIni)] ?? const <String>[]),
    ].take(_maksBaris).toList();
  }

  /// Peta baris per kunci dari seluruh [data]: nama hari (Senin..Minggu) untuk
  /// agenda mingguan, tanggal ISO untuk ujian ber-`tanggal`. Tiap daftar
  /// terurut jam mulai (baris tanpa jam paling akhir). Pure.
  @visibleForTesting
  static Map<String, List<String>> petaMingguan(AgendaTerpaduData? data) {
    if (data == null) return const {};
    final berjam = <String, List<(int, AgendaItem)>>{};
    final tanpaJam = <String, List<AgendaItem>>{};
    void tambah(String kunci, AgendaItem item) {
      final chip = jamChip(item);
      if (chip == '-') {
        (tanpaJam[kunci] ??= []).add(item);
      } else {
        (berjam[kunci] ??= []).add((timeToMinutes(chip), item));
      }
    }

    data.agenda.forEach((hari, items) {
      for (final item in items) {
        final tanggal = item.tanggal;
        // Ujian dengan tanggal valid ditempatkan pada kunci tanggalnya;
        // selain itu (kuliah/asisten, atau ujian tanpa tanggal — BE lama)
        // mengikuti bucket nama hari. Fail-open dua arah seperti jadwal page.
        final kunci = (tanggal != null && _polaTanggalIso.hasMatch(tanggal))
            ? tanggal
            : hari;
        tambah(kunci, item);
      }
    });

    final kunciSemua = {...berjam.keys, ...tanpaJam.keys};
    return {
      for (final kunci in kunciSemua)
        kunci: [
          ...((berjam[kunci] ?? const [])
                ..sort((a, b) => a.$1.compareTo(b.$1)))
              .map((x) => _barisItem(x.$2)),
          ...(tanpaJam[kunci] ?? const []).map(_barisItem),
        ],
    };
  }

  static String _tanggalIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Tulis peta mingguan + picu update provider native. [data] null → kunci
  /// dihapus → native merender "tanpa_data" (dipakai saat logout).
  @visibleForTesting
  Future<void> terapkan({AgendaTerpaduData? data}) async {
    final json = data == null ? null : jsonEncode(petaMingguan(data));
    await _gateway.simpanData(kunciJadwalJson, json);
    await _gateway.perbaruiWidget();
  }

  /// Baca cache agenda milik NIM aktif lalu terapkan ke widget. Fail-open.
  Future<void> perbaruiDariCache() async {
    try {
      final data = await AgendaCacheService.instance.baca();
      await terapkan(data: data);
    } catch (e) {
      debugPrint('WidgetJadwal: gagal memperbarui widget (${e.runtimeType})');
    }
  }

  /// Hapus data widget (keadaan "tanpa_data" di native) saat logout —
  /// dipanggil dari hook logout MainPage, urutan setelah pembersih cache lain.
  Future<void> bersihkanSaatLogout() async {
    try {
      await terapkan(data: null);
    } catch (e) {
      debugPrint('WidgetJadwal: pembersihan logout gagal (${e.runtimeType})');
    }
  }
}

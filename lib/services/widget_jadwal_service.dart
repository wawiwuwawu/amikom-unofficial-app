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
/// [AgendaCacheService]) lalu menulis baris siap-tampil ke storage home_widget
/// dan memicu update provider native. Pembaruan terjadi tiap fetch agenda
/// berhasil (dashboard/jadwal) dan tiap app dibuka (main.dart), sehingga user
/// tidak login pun widget tetap menampilkan jadwal terakhir yang diketahui.
///
/// Seluruh method publik fail-open: tidak pernah melempar ke pemanggil.
class WidgetJadwalService {
  WidgetJadwalService._();

  static final instance = WidgetJadwalService._();

  /// Nama class provider native — harus cocok dengan receiver di manifest.
  static const namaProviderAndroid = 'JadwalWidgetProvider';

  static const _kKeadaan = 'keadaan';
  static const _kJudul = 'judul_tanggal';
  static const _kBaris = 'baris';
  static const _maksBaris = 4;

  static const _bulanPendek = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  WidgetJadwalGateway _gateway = HomeWidgetGateway();

  @visibleForTesting
  void gantiGatewayUntukTest(WidgetJadwalGateway gateway) {
    _gateway = gateway;
  }

  /// Judul widget, mis. "Jadwal Hari Ini · Jumat, 24 Okt".
  @visibleForTesting
  static String judulHariIni(DateTime hariIni) =>
      'Jadwal Hari Ini · ${namaHariDariWeekday(hariIni.weekday)}, '
      '${hariIni.day} ${_bulanPendek[hariIni.month - 1]}';

  /// Baris siap-tampil untuk [hariIni] dari [data]: maks [_maksBaris],
  /// terurut jam mulai (baris tanpa jam paling akhir), format
  /// "09:00 · Pemrograman Web · LT2". Pure — dipakai test langsung.
  @visibleForTesting
  static List<String> barisHariIni(AgendaTerpaduData? data, DateTime hariIni) {
    if (data == null) return const [];
    final items = data.agenda[namaHariDariWeekday(hariIni.weekday)];
    if (items == null || items.isEmpty) return const [];
    final berjam = <AgendaItem>[];
    final tanpaJam = <AgendaItem>[];
    for (final item in items) {
      (jamChip(item) == '-' ? tanpaJam : berjam).add(item);
    }
    berjam.sort(
      (a, b) => timeToMinutes(jamChip(a)).compareTo(timeToMinutes(jamChip(b))),
    );
    final terpilih = [...berjam, ...tanpaJam].take(_maksBaris);
    return [
      for (final item in terpilih)
        '${jamChip(item)} · ${item.matakuliah}'
        '${item.ruang.isEmpty ? '' : ' · ${item.ruang}'}',
    ];
  }

  /// Tulis data widget + picu update provider native.
  /// [data] null → keadaan "tanpa_data" (belum pernah memuat jadwal).
  @visibleForTesting
  Future<void> terapkan({AgendaTerpaduData? data, DateTime? hariIni}) async {
    final now = hariIni ?? DateTime.now();
    final baris = barisHariIni(data, now);
    final keadaan = data == null ? 'tanpa_data' : (baris.isEmpty ? 'kosong' : 'ada');
    await _gateway.simpanData(_kKeadaan, keadaan);
    await _gateway.simpanData(_kJudul, judulHariIni(now));
    for (var i = 1; i <= _maksBaris; i++) {
      await _gateway.simpanData('$_kBaris$i', i <= baris.length ? baris[i - 1] : null);
    }
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

  /// Kembalikan widget ke keadaan "tanpa_data" saat logout (dipanggil dari
  /// hook logout MainPage, urutan setelah pembersih cache lain).
  Future<void> bersihkanSaatLogout() async {
    try {
      await terapkan(data: null);
    } catch (e) {
      debugPrint('WidgetJadwal: pembersihan logout gagal (${e.runtimeType})');
    }
  }
}

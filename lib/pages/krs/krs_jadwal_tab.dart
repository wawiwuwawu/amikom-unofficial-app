import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/agenda_terpadu.dart';
import '../../services/akademik_service.dart';
import '../../services/krs_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_kit.dart';

/// Jadwal kuliah KRS — tampilan TERPISAH dari [JadwalPage].
///
/// Bedanya dengan agenda terpadu: di sini hanya mata kuliah KRS mahasiswa
/// (tipe `kuliah`) yang ditampilkan — tanpa filter Asisten/Ujian yang tidak
/// relevan di konteks KRS — plus tombol unduh & bagikan KRS PDF.
///
/// Sumber data tetap `GET /api/v1/agenda/terpadu` (sama seperti JadwalPage),
/// hanya penyajiannya yang berbeda.
class KrsJadwalTab extends StatefulWidget {
  const KrsJadwalTab({super.key});

  @override
  State<KrsJadwalTab> createState() => _KrsJadwalTabState();
}

class _KrsJadwalTabState extends State<KrsJadwalTab> {
  final _akademikService = AkademikService();
  final _krsService = KrsService();

  bool _loading = true;
  String? _error;
  AgendaTerpaduData? _agendaData;
  bool _downloading = false;
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _akademikService.getAgendaTerpadu();
      if (mounted) {
        setState(() {
          _agendaData = res;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = userErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadKrs({bool silent = false}) async {
    setState(() => _downloading = true);
    try {
      final path = await _krsService.downloadKrs((p0, p1) {});
      if (mounted) {
        setState(() => _downloadPath = path);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('KRS tersimpan di $path'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _shareKrs() async {
    String? path = _downloadPath;
    if (path == null) {
      await _downloadKrs(silent: true);
      path = _downloadPath;
      if (path == null) return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Jadwal & KRS Amikom'),
    );
  }

  /// Agenda terpadu disaring ke mata kuliah saja; hari tanpa kuliah dibuang.
  Map<String, List<AgendaItem>> get _jadwalKuliah {
    final data = _agendaData;
    if (data == null) return const {};
    final result = <String, List<AgendaItem>>{};
    data.agenda.forEach((day, items) {
      final kuliah =
          items.where((item) => item.tipe.toLowerCase() == 'kuliah').toList();
      if (kuliah.isNotEmpty) result[day] = kuliah;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading(message: 'Memuat jadwal…');

    final error = _error;
    if (error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: error, onRetry: _load),
        ),
      );
    }

    final jadwal = _jadwalKuliah;
    if (jadwal.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 130,
          ),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            const AppEmptyState(
              title: 'Belum ada jadwal kuliah',
              message: 'Jadwal mata kuliah KRS akan tampil di sini setelah '
                  'mata kuliah KRS terisi. Tarik ke bawah untuk menyegarkan.',
              icon: CupertinoIcons.calendar,
            ),
          ],
        ),
      );
    }

    // Satu kali partisi dari satu sumber: baris hari (punya jam, atau komponen
    // warisan/kosong yang tetap masuk tampilan hari) dipisah dari sesi yang
    // memang belum punya jadwal tetap. Tidak ada baris yang dirender dua kali.
    final dayItems = <String, List<AgendaItem>>{};
    final tanpaPraktikum = <AgendaItem>[];
    final tanpaKelas = <AgendaItem>[];
    for (final entry in jadwal.entries) {
      for (final item in entry.value) {
        if (_hasJam(item)) {
          (dayItems[entry.key] ??= []).add(item);
          continue;
        }
        switch ((item.komponen ?? '').trim().toLowerCase()) {
          case 'praktek':
            tanpaPraktikum.add(item);
          case 'teori':
            tanpaKelas.add(item);
          default:
            (dayItems[entry.key] ??= []).add(item);
        }
      }
    }

    // Toolbar menghitung mata kuliah UNIK (bukan jumlah baris): satu mata
    // kuliah bisa punya baris teori + praktikum.
    final totalKuliah = jadwal.values
        .expand((items) => items)
        .map((i) => i.matakuliah.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet()
        .length;

    final sortedDays = dayItems.keys.toList()
      ..sort((a, b) => dayValue(a).compareTo(dayValue(b)));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + 130,
        ),
        children: [
          _toolbar(totalKuliah),
          for (final day in sortedDays) _daySection(day, dayItems[day]!),
          if (tanpaPraktikum.isNotEmpty)
            _noScheduleSection(
              title: 'Tanpa Praktikum',
              explainer: Text(
                'Tidak ada sesi praktikum di jadwal — mata kuliah ini '
                'dijalankan sebagai kuliah teori. Ini normal untuk semester akhir.',
                style: AppText.bodySm,
              ),
              items: tanpaPraktikum,
            ),
          if (tanpaKelas.isNotEmpty)
            _noScheduleSection(
              title: 'Tanpa Kelas',
              explainer: AppSurface(
                variant: AppSurfaceVariant.warning,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'Belum ada jadwal kelas tetap (biasanya Skripsi atau '
                  'bimbingan). Hubungi dosen pembimbing untuk mengatur '
                  'jadwal bimbingan.',
                  style: AppText.bodySm,
                ),
              ),
              items: tanpaKelas,
            ),
          _ringkasanSection(jadwal),
        ],
      ),
    );
  }

  // ── Baris alat: ringkasan + unduh/bagikan KRS ──────────────────────────────

  Widget _toolbar(int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$total mata kuliah di KRS',
              style: AppText.label.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
          IconButton(
            tooltip: 'Unduh KRS',
            icon: Icon(
              _downloading
                  ? CupertinoIcons.hourglass
                  : CupertinoIcons.cloud_download,
              color: AppColors.primary,
            ),
            onPressed: _downloading ? null : () => _downloadKrs(),
          ),
          IconButton(
            tooltip: 'Bagikan KRS',
            icon: const Icon(CupertinoIcons.share, color: AppColors.primary),
            onPressed: _downloading ? null : _shareKrs,
          ),
        ],
      ),
    );
  }

  // ── Satu seksi per hari ────────────────────────────────────────────────────

  Widget _daySection(String day, List<AgendaItem> items) {
    final isToday = dayValue(day) == DateTime.now().weekday;
    final total = _uniqueMatkul(items);

    return AppSection(
      title: agendaDayLabel(day),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday) ...[
            const AppPill('Hari ini', tone: AppPillTone.info),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            '$total mata kuliah',
            style: AppText.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
      // Hari aktif dibungkus permukaan `hero` supaya paling menonjol.
      child: isToday
          ? AppSurface(
              variant: AppSurfaceVariant.hero,
              radius: AppRadius.lg,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: AppListGroup.from([for (final item in items) _agendaRow(item)]),
            )
          : AppListGroup.from([for (final item in items) _agendaRow(item)]),
    );
  }

  // ── Seksi sesi tanpa jadwal tetap ──────────────────────────────────────────

  /// Sesi yang sudah pasti tidak punya jam (praktek tanpa praktikum, teori
  /// tanpa kelas) dipisah dari tampilan hari supaya tidak jadi baris kosong
  /// yang ramai — dengan penjelasan kenapa kosongnya wajar.
  Widget _noScheduleSection({
    required String title,
    required Widget explainer,
    required List<AgendaItem> items,
  }) {
    return AppSection(
      title: title,
      trailing: Text(
        '${_uniqueMatkul(items)} mata kuliah',
        style: AppText.label.copyWith(fontWeight: FontWeight.w400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          explainer,
          const SizedBox(height: AppSpacing.sm),
          AppListGroup.from([
            for (final item in items) _agendaRow(item, tanpaJadwal: true),
          ]),
        ],
      ),
    );
  }

  // ── Ringkasan mata kuliah (satu baris per mata kuliah) ─────────────────────

  Widget _ringkasanSection(Map<String, List<AgendaItem>> jadwal) {
    final perMatkul = <String, List<AgendaItem>>{};
    for (final item in jadwal.values.expand((items) => items)) {
      final key = item.matakuliah.trim().toLowerCase();
      if (key.isEmpty) continue;
      perMatkul.putIfAbsent(key, () => []).add(item);
    }
    if (perMatkul.isEmpty) return const SizedBox.shrink();

    return AppSection(
      title: 'Ringkasan Mata Kuliah',
      trailing: Text(
        '${perMatkul.length} mata kuliah',
        style: AppText.label.copyWith(fontWeight: FontWeight.w400),
      ),
      child: AppListGroup.from([
        for (final entry in perMatkul.entries)
          AppListRow(
            // Casing asli pertama kali mata kuliah muncul.
            title: entry.value.first.matakuliah,
            subtitle: _statusMatkul(entry.value),
          ),
      ]),
    );
  }

  // ── Turunan data jadwal ────────────────────────────────────────────────────

  /// Jumlah mata kuliah unik (trim + case-insensitive; nama kosong diabaikan).
  int _uniqueMatkul(List<AgendaItem> items) => items
      .map((i) => i.matakuliah.trim().toLowerCase())
      .where((n) => n.isNotEmpty)
      .toSet()
      .length;

  String _komponen(AgendaItem i) => (i.komponen ?? '').trim().toLowerCase();

  /// Jam yang ditampilkan di chip: `jamMulai` lebih tepat daripada parsing
  /// `jam` — portal menulis `'-'` sebagai penanda kosong pada field itu.
  String _jamChip(AgendaItem i) {
    final m = i.jamMulai.trim();
    if (m.isNotEmpty && m != '-') return m;
    final j = i.jam.trim();
    if (j.isEmpty || j == '-') return '-';
    return j.split('-').first.trim();
  }

  bool _hasJam(AgendaItem i) => _jamChip(i) != '-';

  /// Label pil baris di seksi hari. Baris tanpa jam selalu masuk seksi
  /// "Tanpa Praktikum"/"Tanpa Kelas" (tanpa pil), jadi di sini hanya label
  /// baris berjadwal yang terjangkau.
  String _rowLabel(AgendaItem i) {
    switch (_komponen(i)) {
      case 'praktek':
        return 'Praktikum';
      case 'teori':
        return 'Kuliah Teori';
      default:
        return i.detail.isNotEmpty ? i.detail : 'Kuliah';
    }
  }

  AppPillTone _rowTone(AgendaItem i) {
    switch (_komponen(i)) {
      case 'praktek':
      case 'teori':
        return AppPillTone.info;
      default:
        return AppPillTone.neutral;
    }
  }

  /// Status satu mata kuliah di ringkasan — dari komponen & jam barisnya.
  String _statusMatkul(List<AgendaItem> items) {
    final komponen = items.map(_komponen).toSet();
    final adaTeori = komponen.contains('teori');
    final adaPraktek = komponen.contains('praktek');
    if (adaPraktek && adaTeori) return 'Teori & Praktikum';
    if (adaPraktek) {
      final adaJam = items.where((i) => _komponen(i) == 'praktek').any(_hasJam);
      return adaJam ? 'Praktikum' : 'Teori (tanpa praktikum)';
    }
    if (adaTeori) {
      final adaJam = items.where((i) => _komponen(i) == 'teori').any(_hasJam);
      return adaJam ? 'Teori' : 'Tanpa kelas';
    }
    final detail = items.first.detail;
    return detail.isNotEmpty ? detail : '-';
  }

  Widget _agendaRow(AgendaItem item, {bool tanpaJadwal = false}) {
    final keterangan = <String>[
      item.ruang.isEmpty ? '-' : item.ruang,
      if (item.detail.isNotEmpty) item.detail,
    ];

    return AppListRow(
      // Jam jadi info depan: yang dicari pertama saat melihat jadwal.
      leading: Container(
        width: 64,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Text(
          tanpaJadwal ? '-' : _jamChip(item),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: item.matakuliah.isEmpty ? '-' : item.matakuliah,
      subtitle: keterangan.join(' • '),
      // Seksi "tanpa jadwal" sudah menyatakan kondisinya di judul — barisnya
      // tidak perlu pil tambahan.
      trailing: tanpaJadwal
          ? null
          : AppPill(_rowLabel(item), tone: _rowTone(item)),
    );
  }
}

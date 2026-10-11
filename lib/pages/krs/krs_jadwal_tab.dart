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

    final totalKuliah =
        jadwal.values.fold<int>(0, (sum, items) => sum + items.length);
    final sortedDays = jadwal.keys.toList()
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
          for (final day in sortedDays) _daySection(day, jadwal[day]!),
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
              '$total mata kuliah terjadwal',
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
            '${items.length} mata kuliah',
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

  Widget _agendaRow(AgendaItem item) {
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
          item.jam.isEmpty ? '-' : item.jam,
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
    );
  }
}

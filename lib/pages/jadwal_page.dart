import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import '../services/akademik_service.dart';
import '../services/krs_service.dart';
import '../models/agenda_terpadu.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Jadwal perkuliahan (agenda terpadu) — fitur yang dibuka hampir tiap hari,
/// jadi disajikan sebagai DAFTAR PER HARI yang bisa dipindai sekejap:
/// jam (info depan) → mata kuliah (judul) → ruang/dosen (keterangan).
///
/// Hari yang sedang berjalan ditonjolkan lewat `AppSurface` varian `hero`
/// plus label "Hari ini", supaya kelas berikutnya langsung terlihat.
class JadwalPage extends StatefulWidget {
  final bool showDownloadKrs;
  const JadwalPage({super.key, this.showDownloadKrs = false});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _akademikService = AkademikService();
  final _krsService = KrsService();

  bool _loading = true;
  String? _error;
  AgendaTerpaduData? _agendaData;

  String _filterTipe = 'semua'; // 'semua', 'kuliah', 'asisten', 'ujian'
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
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  int _dayValue(String day) {
    switch (day.toLowerCase().trim()) {
      case 'senin':
        return 1;
      case 'selasa':
        return 2;
      case 'rabu':
        return 3;
      case 'kamis':
        return 4;
      case 'jumat':
      case 'jum\'at':
        return 5;
      case 'sabtu':
        return 6;
      case 'minggu':
        return 7;
      default:
        return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    if (!canPop) {
      // Dipakai sebagai isi tab (mis. tab "Cetak & Jadwal" di halaman KRS):
      // kerangka halaman sudah disediakan induknya, jadi tampilkan isinya saja.
      return _buildBody(showInlineTools: true);
    }

    return AppScaffold(
      title: 'Jadwal Perkuliahan',
      subtitle: 'Kuliah, asisten, dan ujian dalam satu agenda',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [_downloadAction(), _shareAction()],
      body: _buildBody(showInlineTools: false),
    );
  }

  Widget _buildBody({required bool showInlineTools}) {
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

    final data = _agendaData;
    if (data == null || data.agenda.isEmpty) {
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
              title: 'Belum ada agenda',
              message: 'Tidak ada jadwal agenda terpadu untuk ditampilkan. '
                  'Tarik ke bawah untuk menyegarkan.',
              icon: CupertinoIcons.calendar,
            ),
          ],
        ),
      );
    }

    final sortedDays = data.agenda.keys.toList()
      ..sort((a, b) => _dayValue(a).compareTo(_dayValue(b)));

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
          _filterRow(showInlineTools: showInlineTools, total: data.totalAgenda),
          for (final day in sortedDays) _daySection(day, data.agenda[day]!),
        ],
      ),
    );
  }

  // ── Baris alat: filter tipe + unduh/bagikan KRS ────────────────────────────

  Widget _filterRow({required bool showInlineTools, required int total}) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('semua', 'Semua ($total)'),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('kuliah', 'Kuliah 📘'),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('asisten', 'Asisten 🟣'),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('ujian', 'Ujian 🔴'),
              ],
            ),
          ),
        ),
        if (showInlineTools) ...[
          _downloadAction(),
          _shareAction(),
        ],
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filterTipe == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: isSelected ? BorderSide.none : const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelStyle: AppText.label.copyWith(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      onSelected: (val) {
        if (val) setState(() => _filterTipe = value);
      },
    );
  }

  Widget _downloadAction() {
    return IconButton(
      tooltip: 'Download KRS',
      icon: Icon(
        _downloading ? CupertinoIcons.hourglass : CupertinoIcons.cloud_download,
        color: AppColors.primary,
      ),
      onPressed: _downloading ? null : () => _downloadKrs(),
    );
  }

  Widget _shareAction() {
    return IconButton(
      tooltip: 'Bagikan KRS',
      icon: const Icon(CupertinoIcons.share, color: AppColors.primary),
      onPressed: _downloading ? null : _shareKrs,
    );
  }

  // ── Satu seksi per hari ────────────────────────────────────────────────────

  Widget _daySection(String day, List<AgendaItem> items) {
    final filteredItems = items.where((item) {
      if (_filterTipe == 'semua') return true;
      if (_filterTipe == 'kuliah') return item.tipe == 'kuliah';
      if (_filterTipe == 'asisten') return item.tipe == 'asisten';
      if (_filterTipe == 'ujian') return item.tipe == 'uts' || item.tipe == 'uas';
      return true;
    }).toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    final isToday = _dayValue(day) == DateTime.now().weekday;
    final rows = [for (final item in filteredItems) _agendaRow(item)];

    return AppSection(
      title: day,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday) ...[
            const AppPill('Hari ini', tone: AppPillTone.info),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            '${filteredItems.length} kegiatan',
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
              child: AppListGroup.from(rows),
            )
          : AppListGroup.from(rows),
    );
  }

  Widget _agendaRow(AgendaItem item) {
    final (label, tone) = _tipeStyle(item.tipe);

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
      trailing: AppPill(label, tone: tone),
    );
  }

  /// Label + warna pil per tipe agenda (kuliah / asisten / ujian).
  (String, AppPillTone) _tipeStyle(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'kuliah':
        return ('Kuliah', AppPillTone.info);
      case 'asisten':
        return ('Asisten', AppPillTone.neutral);
      case 'uts':
      case 'uas':
        return (tipe.toUpperCase(), AppPillTone.danger);
      default:
        return (tipe, AppPillTone.neutral);
    }
  }
}

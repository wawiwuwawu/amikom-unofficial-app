import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transkrip.dart';
import '../services/transkrip_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/histori_ipk_sheet.dart';
import '../widgets/cumlaude_sheet.dart';
import '../widgets/progress_kelulusan_card.dart';
import '../widgets/ringkasan_skpi_widget.dart';
import '../widgets/target_ipk_simulator_sheet.dart';

/// Urutan kualitas huruf mutu — dipakai hanya untuk mengurutkan tampilan
/// distribusi nilai.
const List<String> _gradeOrder = ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E'];

/// Halaman Transkrip Nilai — rekap nilai seluruh semester.
///
/// Hasil redesign: halaman ini tidak lagi berupa tumpukan kartu per mata
/// kuliah (39+ kartu yang harus di-scroll satu per satu). Kini hanya ada SATU
/// bagian yang berbobot kartu — ringkasan total — dan selebihnya baris-baris
/// ringkas yang bisa dipindai sekali lihat:
///
///   1. ringkasan: IPK kumulatif & total SKS (AppSurface + AppStatTile);
///   2. status predikat kelulusan (bila data cumlaude tersedia);
///   3. progress kelulusan & ringkasan SKPI (widget bersama);
///   4. daftar mata kuliah — satu AppListGroup, trailing [AppGradeBadge];
///   5. distribusi nilai — hitungan per huruf mutu dari data yang sama.
///
class TranskripPage extends StatefulWidget {
  const TranskripPage({super.key});

  @override
  State<TranskripPage> createState() => _TranskripPageState();
}

class _TranskripPageState extends State<TranskripPage> {
  final _service = TranskripService();
  List<TranskripItem>? _list;
  CumlaudeData? _cumlaudeData;
  ProgressKelulusanData? _progressKelulusanData;
  SkpiData? _skpiData;
  bool _loading = true;
  bool _downloading = false;
  String? _downloadPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Jalankan [future] dan kembalikan `null` jika gagal (untuk data opsional).
  Future<T?> _safe<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getTranskrip(),
        _safe(_service.getCumlaudeEligibility()),
        _safe(_service.getProgressKelulusan()),
        _safe(_service.getRingkasanSkpi()),
      ]);
      if (!mounted) return;
      setState(() {
        _list = results[0] as List<TranskripItem>?;
        _cumlaudeData = results[1] as CumlaudeData?;
        _progressKelulusanData = results[2] as ProgressKelulusanData?;
        _skpiData = results[3] as SkpiData?;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final path = await _service.download();
      setState(() => _downloadPath = path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tersimpan di $path',
              style: AppText.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: AppText.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share() async {
    String? path = _downloadPath;
    if (path == null) {
      await _download();
      path = _downloadPath;
      if (path == null) return;
    }
    final file = XFile(path);
    await SharePlus.instance.share(
      ShareParams(files: [file], text: 'Transkrip Nilai'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Transkrip Nilai',
      subtitle: 'Rekap nilai seluruh semester',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: _buildActions(),
      body: Padding(
        // Jarak sisi halaman ditahan di sini supaya kartu galat/kosong dari
        // AppAsyncView juga tidak menempel ke tepi layar.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AppAsyncView<List<TranskripItem>>(
          loading: _loading,
          error: _error,
          data: _list,
          isEmpty: (list) => list.isEmpty,
          onRetry: _load,
          loadingMessage: 'Memuat transkrip…',
          emptyTitle: 'Belum ada data transkrip',
          emptyMessage:
              'Nilai akan tampil di sini setelah dosen memasukkan nilai mata kuliah.',
          emptyIcon: CupertinoIcons.doc_text,
          builder: _buildTranskrip,
        ),
      ),
    );
  }

  // ── Aksi di app bar ───────────────────────────────────────────────────────

  List<Widget> _buildActions() {
    if (_list == null || _loading) return const [];

    return [
      IconButton(
        icon: const Icon(CupertinoIcons.scope),
        tooltip: 'Simulasi Target IPK',
        onPressed: () => showTargetIpkSimulatorBottomSheet(context),
      ),
      if (_cumlaudeData != null)
        IconButton(
          icon: const Icon(CupertinoIcons.rosette, color: AppColors.warning),
          tooltip: 'Evaluasi Cumlaude',
          onPressed: () => showCumlaudeBottomSheet(context, _cumlaudeData!),
        ),
      IconButton(
        icon: const Icon(CupertinoIcons.chart_bar_alt_fill),
        tooltip: 'Analitik Tren IPK',
        onPressed: () => showHistoriIpkBottomSheet(context),
      ),
      IconButton(
        icon: _downloading
            ? const CupertinoActivityIndicator(
                radius: 9,
                color: AppColors.primary,
              )
            : const Icon(CupertinoIcons.cloud_download),
        tooltip: 'Download Transkrip',
        onPressed: _downloading ? null : _download,
      ),
      IconButton(
        icon: const Icon(CupertinoIcons.share),
        tooltip: 'Bagikan Transkrip',
        onPressed: _downloading ? null : _share,
      ),
    ];
  }

  // ── Isi halaman ───────────────────────────────────────────────────────────

  Widget _buildTranskrip(List<TranskripItem> list) {
    final totalSks = list.fold<int>(0, (sum, item) => sum + item.sks);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _buildRingkasan(list, totalSks),
          if (_cumlaudeData != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: _buildCumlaudeCard(_cumlaudeData!),
            ),
          if (_progressKelulusanData != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: ProgressKelulusanCard(data: _progressKelulusanData!),
            ),
          if (_skpiData != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: RingkasanSkpiWidget(data: _skpiData!),
            ),
          _buildDaftarMatkul(list),
          _buildDistribusiNilai(list),
        ],
      ),
    );
  }

  /// Ringkasan total: IPK kumulatif + total SKS, satu-satunya bagian halaman
  /// yang berbobot kartu.
  Widget _buildRingkasan(List<TranskripItem> list, int totalSks) {
    final cumlaude = _cumlaudeData;

    return AppSection(
      title: 'Ringkasan',
      topGap: AppSpacing.lg,
      trailing: cumlaude == null
          ? null
          : AppPill(
              cumlaude.predikatSaatIni,
              tone: cumlaude.isCumlaudeEligible
                  ? AppPillTone.success
                  : AppPillTone.info,
            ),
      child: AppSurface(
        variant: AppSurfaceVariant.hero,
        child: Row(
          children: [
            Expanded(
              child: AppStatTile(
                value: _ipkKumulatif(list).toStringAsFixed(2),
                label: 'IPK Kumulatif',
                icon: CupertinoIcons.rosette,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatTile(
                value: '$totalSks',
                label: 'Total SKS',
                icon: CupertinoIcons.book_fill,
                accent: AppColors.info,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// IPK kumulatif: pakai angka resmi dari API bila tersedia; jika tidak,
  /// dihitung dari total bobot dibagi total SKS transkrip yang ditampilkan.
  double _ipkKumulatif(List<TranskripItem> list) {
    final cumlaudeIpk = _cumlaudeData?.ipkTerakhir;
    if (cumlaudeIpk != null && cumlaudeIpk > 0) return cumlaudeIpk;

    final progressIpk =
        _progressKelulusanData?.kelayakanAkademikWisuda.ipkTerakhir;
    if (progressIpk != null && progressIpk > 0) return progressIpk;

    final totalSks = list.fold<int>(0, (sum, item) => sum + item.sks);
    if (totalSks == 0) return 0;
    final totalBobot = list.fold<double>(
      0,
      (sum, item) => sum + item.totalBobot,
    );
    return totalBobot / totalSks;
  }

  /// Status predikat kelulusan — baris ringkas, bukan kartu besar.
  Widget _buildCumlaudeCard(CumlaudeData cumlaude) {
    final isCumlaude = cumlaude.isCumlaudeEligible;
    final accent = isCumlaude ? AppColors.success : AppColors.warning;
    final violatingCount =
        cumlaude.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount;

    final String keterangan;
    if (isCumlaude) {
      keterangan = 'Seluruh syarat Cumlaude terpenuhi. Pertahankan IPK Anda!';
    } else if (violatingCount > 0) {
      keterangan =
          'Terdapat $violatingCount matakuliah bernilai < B- yang perlu diperbaiki.';
    } else {
      keterangan =
          'Status predikat kelulusan berdasarkan analisis 4 syarat akademis.';
    }

    return AppSurface(
      variant: isCumlaude
          ? AppSurfaceVariant.success
          : AppSurfaceVariant.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCumlaude
                    ? CupertinoIcons.rosette
                    : CupertinoIcons.chart_bar_alt_fill,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isCumlaude
                      ? '🎓 Proyeksi: Cumlaude'
                      : 'Proyeksi: ${cumlaude.predikatSaatIni}',
                  style: AppText.h3.copyWith(color: accent),
                ),
              ),
              TextButton.icon(
                onPressed: () => showCumlaudeBottomSheet(context, cumlaude),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: AppText.label.copyWith(fontWeight: FontWeight.w700),
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  CupertinoIcons.chevron_right,
                  size: 12,
                  color: accent,
                ),
                label: const Text('Rincian Syarat'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(keterangan, style: AppText.bodySm),
        ],
      ),
    );
  }

  /// Daftar seluruh mata kuliah — satu baris per mata kuliah, bukan satu kartu.
  Widget _buildDaftarMatkul(List<TranskripItem> list) {
    return AppSection(
      title: 'Mata kuliah',
      trailing: Text(
        '${list.length} mata kuliah',
        style: AppText.label.copyWith(fontWeight: FontWeight.w400),
      ),
      child: AppListGroup.from([
        for (final item in list) _matkulRow(item),
      ]),
    );
  }

  Widget _matkulRow(TranskripItem item) {
    return AppListRow(
      title: item.mkl,
      subtitle:
          '${item.kode.trim()} · ${item.sks} SKS · bobot ${item.bobot.toStringAsFixed(2)}',
      trailing: AppGradeBadge(grade: item.nilai),
    );
  }

  /// Distribusi huruf mutu — dihitung dari data transkrip yang sama.
  Widget _buildDistribusiNilai(List<TranskripItem> list) {
    final counts = <String, int>{};
    for (final item in list) {
      final grade = item.nilai.trim().toUpperCase();
      if (grade.isEmpty) continue;
      counts[grade] = (counts[grade] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final grades = counts.keys.toList()..sort(_compareGrade);

    return AppSection(
      title: 'Distribusi nilai',
      child: AppListGroup.from([
        for (final grade in grades)
          AppListRow(
            leading: AppGradeBadge(grade: grade, size: 30),
            title: 'Nilai $grade',
            subtitle: '${counts[grade]} mata kuliah',
          ),
      ]),
    );
  }

  int _compareGrade(String a, String b) {
    final indexA = _gradeOrder.indexOf(a);
    final indexB = _gradeOrder.indexOf(b);
    if (indexA == -1 && indexB == -1) return a.compareTo(b);
    if (indexA == -1) return 1;
    if (indexB == -1) return -1;
    return indexA.compareTo(indexB);
  }
}

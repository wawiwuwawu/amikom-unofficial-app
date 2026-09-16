import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/khs.dart';
import '../services/khs_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class KhsPage extends StatefulWidget {
  const KhsPage({super.key});

  @override
  State<KhsPage> createState() => _KhsPageState();
}

class _KhsPageState extends State<KhsPage> {
  final _service = KhsService();

  List<KhsOption> _tahunList = [];
  List<KhsOption> _semesterList = [];
  String? _selectedThn;
  String? _selectedSmt;

  KhsDetailResponse? _detail;
  bool _loadingOptions = true;
  bool _loadingDetail = false;
  bool _downloading = false;
  String? _downloadPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    if (!mounted) return;
    setState(() => _loadingOptions = true);
    try {
      final res = await _service.getOptions();
      if (!mounted) return;
      final rawTahun = res['tahun_akademik'] ?? (res['data'] is Map ? res['data']['tahun_akademik'] : null);
      final rawSemester = res['semester'] ?? (res['data'] is Map ? res['data']['semester'] : null);
      setState(() {
        _tahunList = (rawTahun is List)
            ? rawTahun.map((e) => KhsOption.fromJson(e)).toList()
            : <KhsOption>[];
        _semesterList = (rawSemester is List)
            ? rawSemester.map((e) => KhsOption.fromJson(e)).toList()
            : <KhsOption>[];
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _loadDetail() async {
    if (_selectedThn == null || _selectedSmt == null) return;
    if (!mounted) return;
    setState(() {
      _loadingDetail = true;
      _detail = null;
      _downloadPath = null;
    });
    try {
      final res = await _service.getDetail(_selectedThn!, _selectedSmt!);
      if (!mounted) return;
      setState(() {
        _detail = res;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _refresh() async {
    await _loadOptions();
    if (_selectedThn != null && _selectedSmt != null) {
      await _loadDetail();
    }
  }

  Future<void> _download() async {
    if (_selectedThn == null || _selectedSmt == null) return;
    setState(() => _downloading = true);
    try {
      final path = await _service.download(_selectedThn!, _selectedSmt!);
      setState(() => _downloadPath = path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tersimpan di $path'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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
    if (_selectedThn == null || _selectedSmt == null) return;
    String? path = _downloadPath;
    if (path == null) {
      await _download();
      path = _downloadPath;
      if (path == null) return;
    }
    final file = XFile(path);
    await SharePlus.instance.share(
      ShareParams(files: [file], text: 'KHS $_selectedThn Semester $_selectedSmt'),
    );
  }

  // ── Turunan tampilan (read-only, tidak menyentuh service/model) ────────────

  int get _totalSks =>
      (_detail?.data ?? const <KhsItem>[]).fold(0, (sum, e) => sum + e.sks);

  double get _ipk {
    final items = _detail?.data ?? const <KhsItem>[];
    final sks = items.fold<int>(0, (sum, e) => sum + e.sks);
    if (sks == 0) return 0;
    final bobot = items.fold<double>(0, (sum, e) => sum + (e.bobot * e.sks));
    return bobot / sks;
  }

  bool get _canSearch => _selectedThn != null && _selectedSmt != null;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'KHS',
      subtitle: 'Kartu Hasil Studi',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: _buildSections(),
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final sections = <Widget>[_buildFilter()];

    if (_loadingOptions) {
      sections.add(const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxl),
        child: AppLoading(message: 'Memuat tahun akademik…'),
      ));
      return sections;
    }

    if (_loadingDetail) {
      sections.add(const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxl),
        child: AppLoading(message: 'Memuat nilai…'),
      ));
      return sections;
    }

    final detail = _detail;

    if (detail == null) {
      if (_error != null) {
        sections.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: AppErrorState(message: _error!, onRetry: _loadOptions),
        ));
      } else {
        sections.add(const Padding(
          padding: EdgeInsets.only(top: AppSpacing.xl),
          child: AppEmptyState(
            title: 'Belum ada periode dipilih',
            message: 'Pilih tahun akademik dan semester, lalu tekan tombol cari.',
            icon: Icons.school_outlined,
          ),
        ));
      }
      return sections;
    }

    sections.add(_buildSummary(detail));
    sections.add(_buildActions());

    if (detail.data.isEmpty) {
      sections.add(const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs),
        child: AppEmptyState(
          title: 'Tidak ada data nilai',
          message: 'Nilai untuk periode ini belum dipublikasikan.',
          icon: Icons.grading_outlined,
        ),
      ));
    } else {
      sections.add(_buildGrades(detail.data));
    }

    if (_error != null) {
      sections.add(Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: AppErrorState(message: _error!, onRetry: _loadDetail),
      ));
    }

    return sections;
  }

  // ── Filter periode ─────────────────────────────────────────────────────────

  Widget _buildFilter() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Periode Akademik', style: AppText.overline),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedThn,
                  items: _tahunList,
                  hint: 'Tahun',
                  onChanged: (v) => setState(() => _selectedThn = v),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDropdown(
                  value: _selectedSmt,
                  items: _semesterList,
                  hint: 'Semester',
                  onChanged: (v) => setState(() => _selectedSmt = v),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton.filled(
                onPressed: _canSearch ? _loadDetail : null,
                icon: const Icon(Icons.search, size: 20),
                tooltip: 'Cari KHS',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<KhsOption> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: AppDeco.card(
        color: AppColors.surfaceMuted,
        radius: AppRadius.sm,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: AppText.bodySm),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primarySoft,
            size: 18,
          ),
          style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e.value,
                    child: Text(
                      e.label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Ringkasan ──────────────────────────────────────────────────────────────

  Widget _buildSummary(KhsDetailResponse detail) {
    final items = detail.data;
    return AppSection(
      title: 'Ringkasan',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppStatTile(
              value: _ipk.toStringAsFixed(2),
              label: 'IPK Semester',
              icon: Icons.trending_up,
              accent: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppStatTile(
              value: '$_totalSks',
              label: 'Total SKS',
              icon: Icons.menu_book_outlined,
              accent: AppColors.info,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppStatTile(
              value: '${items.length}',
              label: 'Mata Kuliah',
              icon: Icons.list_alt_outlined,
              accent: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status + aksi ──────────────────────────────────────────────────────────

  Widget _buildActions() {
    final detail = _detail!;
    return AppSection(
      title: 'Status & Dokumen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.finishEvaluasi || detail.canViewSkripsi)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (detail.finishEvaluasi)
                    const AppPill(
                      'Evaluasi Selesai',
                      tone: AppPillTone.success,
                    ),
                  if (detail.canViewSkripsi)
                    const AppPill('Lihat Skripsi', tone: AppPillTone.info),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _downloading ? null : _download,
                  icon: _downloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Unduh'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloading ? null : _share,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Bagikan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Daftar nilai (LIST, bukan tumpukan kartu) ──────────────────────────────

  Widget _buildGrades(List<KhsItem> items) {
    return AppSection(
      title: 'Daftar Mata Kuliah',
      trailing: AppPill('${items.length} MK'),
      child: AppListGroup.from([
        for (final item in items)
          AppListRow(
            leading: _kodeChip(item.kode),
            title: item.mkl,
            subtitle: _subtitleFor(item),
            trailing: AppGradeBadge(
              grade: item.nilai.trim().isEmpty ? '–' : item.nilai,
            ),
          ),
      ]),
    );
  }

  Widget _kodeChip(String kode) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDeco.softPrimary(radius: AppRadius.sm),
      child: Text(
        kode,
        style: AppText.label.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _subtitleFor(KhsItem item) {
    final parts = <String>['${item.sks} SKS'];
    if (item.nilai.trim().isNotEmpty) {
      parts.add('Bobot ${item.bobot.toStringAsFixed(2)}');
    }
    if (item.ambilKe.trim().isNotEmpty) {
      parts.add('Ambil ke-${item.ambilKe}');
    }
    return parts.join(' • ');
  }
}

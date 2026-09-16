import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/pkl.dart';
import '../services/pkl_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman PKL & Tugas Mandiri.
///
/// Redesign memakai design system:
///   * dua tab (pendaftaran & riwayat) tetap dipertahankan, tab digambar oleh
///     tema global `AppTheme`;
///   * formulir pendaftaran memakai tema input global, hanya dibungkus
///     [AppSurface]; banner pembatas memakai [AppSurface] danger;
///   * informasi loket BAP disajikan sebagai poin berjarak baca lega;
///   * riwayat pendaftaran jadi baris [AppListRow] di dalam satu [AppListGroup]
///     — bukan satu kartu per pendaftaran — dengan [AppPill] status dan aksi
///     unduh/hapus tetap berfungsi di baris yang sama.
/// Semua panggilan service, state, dan navigasi tidak berubah.
///
class PklPage extends StatefulWidget {

  const PklPage({super.key});

  @override
  State<PklPage> createState() => _PklPageState();
}

class _PklPageState extends State<PklPage> {
  final PklService _service = PklService();

  bool _isLoading = true;
  String _error = '';
  PklData? _data;

  String? _selectedJenis;
  final TextEditingController _judulController = TextEditingController();
  bool _isSubmitting = false;
  final Set<String> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _judulController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getPklData();
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_selectedJenis == null || _selectedJenis!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Jenis Pendaftaran terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Judul Pendaftaran / Laporan'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitPkl(
        _selectedJenis!,
        _judulController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan Berhasil Ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedJenis = null;
          _judulController.clear();
        });
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _downloadPdf(PklItem item) async {
    setState(() => _downloadingIds.add(item.idPengajuan));
    try {
      final path = await _service.downloadFormulirPkl(item.idPengajuan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formulir PDF disimpan ke: $path'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(item.idPengajuan));
      }
    }
  }

  Future<void> _showDeleteConfirmation(PklItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pendaftaran PKL'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pendaftaran (${item.judul}) ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.deletePkl(item.idPengajuan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Pendaftaran PKL berhasil dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'PKL & Tugas Mandiri',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(
                  icon: Icon(CupertinoIcons.doc_plaintext),
                  text: 'Form Pendaftaran',
                ),
                Tab(
                  icon: Icon(CupertinoIcons.clock),
                  text: 'Riwayat Pendaftaran',
                ),
              ],
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoading();

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppErrorState(message: _error, onRetry: _fetchData),
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return TabBarView(
      children: [_buildFormTab(data), _buildRiwayatTab(data)],
    );
  }

  /// Ikon baris dengan latar sorotan lembut — penanda visual untuk tiap item.
  Widget _rowIcon(IconData icon, {Color? tone}) {
    final color = tone ?? AppColors.primary;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  AppPillTone _statusTone(String status) {
    final raw = status.toLowerCase().trim();
    if (raw == 'diajukan') return AppPillTone.warning;
    if (raw == 'diproses') return AppPillTone.info;
    if (raw == 'diterima' || raw == 'acc') return AppPillTone.success;
    if (raw == 'ditolak') return AppPillTone.danger;
    return AppPillTone.neutral;
  }

  Widget _buildFormTab(PklData data) {
    final jenisOptions = data.options.jenis;
    String dynamicLabel = 'Judul Pendaftaran / Kegiatan';
    if (_selectedJenis != null) {
      final selectedOpt = jenisOptions.firstWhere(
        (opt) => opt.value == _selectedJenis,
        orElse: () => PklJenisOption(value: '', label: 'Judul Pendaftaran'),
      );
      if (selectedOpt.label.isNotEmpty) {
        dynamicLabel = selectedOpt.label;
      }
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            // Lebar dibatasi agar formulir tetap nyaman dibaca di layar lebar.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!data.canApply)
                    AppSurface(
                      variant: AppSurfaceVariant.danger,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: AppColors.danger,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pendaftaran Dibatasi',
                                  style: AppText.h3.copyWith(
                                    color: AppColors.danger,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  data.warningMessage ??
                                      'Saudara tidak dapat melakukan pengajuan. Anda belum mengajukan KRS Tugas Praktik.',
                                  style: AppText.body,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    AppSection(
                      title: 'Buat Pendaftaran PKL Baru',
                      topGap: AppSpacing.xs,
                      child: AppSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedJenis,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Pendaftaran',
                                prefixIcon: Icon(
                                  CupertinoIcons.briefcase,
                                  color: AppColors.primarySoft,
                                ),
                              ),
                              items: jenisOptions.map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt.value,
                                  child: Text(
                                    opt.label,
                                    style: AppText.body,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedJenis = val);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextField(
                              controller: _judulController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: dynamicLabel,
                                alignLabelWithHint: true,
                                prefixIcon: const Icon(
                                  CupertinoIcons.book,
                                  color: AppColors.primarySoft,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isSubmitting ? null : _submitForm,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.surface,
                                        ),
                                      )
                                    : const Icon(
                                        CupertinoIcons.paperplane_fill,
                                        size: 18,
                                      ),
                                label: const Text('Ajukan Pendaftaran PKL'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (data.informasi.isNotEmpty)
                    AppSection(
                      title: 'Informasi & Jam Kerja Loket BAP',
                      child: AppSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...data.informasi.map(
                              (info) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Icon(
                                        CupertinoIcons.circle_fill,
                                        size: 6,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(info, style: AppText.body),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatTab(PklData data) {
    final items = data.items;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          padding: AppSpacing.page,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: AppSpacing.xxl),
            AppEmptyState(
              title: 'Belum ada riwayat pendaftaran PKL',
              icon: CupertinoIcons.doc_text_search,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: AppSection(
                title: 'Riwayat Pendaftaran',
                topGap: AppSpacing.xs,
                trailing: AppPill('${items.length} pendaftaran'),
                child: AppListGroup.from([
                  for (final item in items) _buildRiwayatItem(item),
                ]),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Satu pendaftaran = satu [AppListRow]; detail dipadatkan ke subtitle,
  /// status jadi pil, dan aksi unduh/hapus tetap tersedia di baris tersebut.
  Widget _buildRiwayatItem(PklItem item) {
    final isDownloading = _downloadingIds.contains(item.idPengajuan);

    final detail = <String>[
      'Jenis: ${item.jenis}',
      'Tgl Pengajuan: ${item.tglPengajuan}',
      if (item.tglUjian != null || item.ruang != null || item.jam != null)
        'Jadwal Ujian: ${item.tglUjian ?? '-'} (${item.jam ?? '-'}) • Ruang: ${item.ruang ?? '-'}',
    ].join('\n');

    return AppListRow(
      leading: _rowIcon(CupertinoIcons.doc_text_fill),
      title: item.judul,
      subtitle: detail,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill(item.status, tone: _statusTone(item.status)),
          if (item.canDownload)
            IconButton(
              onPressed: isDownloading ? null : () => _downloadPdf(item),
              tooltip: 'Download Formulir PDF',
              visualDensity: VisualDensity.compact,
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.arrow_down_doc, size: 18),
            ),
          if (item.canDelete)
            IconButton(
              onPressed: () => _showDeleteConfirmation(item),
              tooltip: 'Hapus / Batal',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                CupertinoIcons.trash,
                size: 18,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/skmk.dart';
import '../services/skmk_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman Surat Masih Kuliah (SKMK).
///
/// Redesign memakai design system:
///   * dua tab (pengajuan & riwayat) tetap dipertahankan, digambar oleh tema
///     global sehingga tidak ada lagi override warna per-tab;
///   * formulir pengajuan memakai tema input global (border/label/fokus dari
///     `AppTheme`), hanya dibungkus [AppSurface] agar terbaca sebagai satu blok;
///   * riwayat pengajuan disajikan sebagai baris [AppListRow] di dalam satu
///     [AppListGroup] — bukan satu kartu per pengajuan — dengan status sebagai
///     [AppPill] berwarna dan aksi hapus tetap di baris yang sama;
///   * syarat/keluhan BAA dipecah jadi [AppSurface] peringatan + baris kontak.
/// Semua panggilan service, state, dan navigasi tidak berubah.
///
class SkmkPage extends StatefulWidget {

  const SkmkPage({super.key});

  @override
  State<SkmkPage> createState() => _SkmkPageState();
}

class _SkmkPageState extends State<SkmkPage> {
  final SkmkService _service = SkmkService();

  bool _isLoading = true;
  String _error = '';
  SkmkData? _data;

  String? _selectedKeperluan;
  String? _selectedOrtu;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getSkmkData();
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
    if (_selectedKeperluan == null || _selectedOrtu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Keperluan dan Orang Tua terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitSkmk(
        _selectedKeperluan!,
        _selectedOrtu!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan Berhasil Ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedKeperluan = null;
          _selectedOrtu = null;
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

  Future<void> _showDeleteConfirmation(SkmkItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengajuan SKMK'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengajuan SKMK (${item.keperluan}) ini?',
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
        final res = await _service.deleteSkmk(item.idPengajuan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Pengajuan Berhasil Dihapus'),
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
        title: 'Surat Masih Kuliah (SKMK)',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(
                  icon: Icon(CupertinoIcons.doc_plaintext),
                  text: 'Form Pengajuan',
                ),
                Tab(
                  icon: Icon(CupertinoIcons.clock),
                  text: 'Riwayat Pengajuan',
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
    switch (status.toLowerCase().trim()) {
      case 'diajukan':
        return AppPillTone.warning;
      case 'diproses':
        return AppPillTone.info;
      case 'selesai':
        return AppPillTone.success;
      case 'ditolak':
        return AppPillTone.danger;
      default:
        return AppPillTone.neutral;
    }
  }

  Widget _buildFormTab(SkmkData data) {
    final keperluanList = data.options.keperluan;
    final ortuList = data.options.ortu;

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
                  AppSection(
                    title: 'Buat Pengajuan SKMK Baru',
                    topGap: AppSpacing.xs,
                    child: AppSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedKeperluan,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Keperluan',
                              prefixIcon: Icon(
                                CupertinoIcons.briefcase,
                                color: AppColors.primarySoft,
                              ),
                            ),
                            items: keperluanList.map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: AppText.body,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedKeperluan = val);
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedOrtu,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Orang Tua',
                              prefixIcon: Icon(
                                CupertinoIcons.person_2,
                                color: AppColors.primarySoft,
                              ),
                            ),
                            items: ortuList.map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: AppText.body,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedOrtu = val);
                            },
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
                              label: const Text('Ajukan SKMK'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (data.persyaratanInfo.isNotEmpty ||
                      data.kontakBaa.isNotEmpty)
                    AppSection(
                      title: 'Syarat & Catatan Penting',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.persyaratanInfo.isNotEmpty)
                            AppSurface(
                              variant: AppSurfaceVariant.warning,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Layanan SKMK TIDAK DIPROSES untuk:',
                                    style: AppText.h3,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  ...data.persyaratanInfo.map(
                                    (info) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 6),
                                            child: Icon(
                                              CupertinoIcons.circle_fill,
                                              size: 6,
                                              color: AppColors.danger,
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
                          if (data.kontakBaa.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppListGroup(
                              children: [
                                AppListRow(
                                  leading: _rowIcon(
                                    CupertinoIcons.chat_bubble_2_fill,
                                    tone: AppColors.success,
                                  ),
                                  title: 'Kontak Loket BAA',
                                  subtitle: data.kontakBaa,
                                ),
                              ],
                            ),
                          ],
                        ],
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

  Widget _buildRiwayatTab(SkmkData data) {
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
              title: 'Belum ada riwayat pengajuan SKMK',
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
                title: 'Riwayat Pengajuan',
                topGap: AppSpacing.xs,
                trailing: AppPill('${items.length} pengajuan'),
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

  /// Satu pengajuan = satu [AppListRow]; seluruh detailnya dipadatkan ke
  /// subtitle dan statusnya jadi pil berwarna, sehingga daftar mudah dipindai.
  Widget _buildRiwayatItem(SkmkItem item) {
    final detail = <String>[
      'Tgl Pengajuan: ${item.tglPengajuan} • Semester/TA: ${item.thnAjaranSmt}',
      'Tgl Proses: ${item.tglProses ?? '-'}',
      if (item.keterangan.isNotEmpty) 'Keterangan: ${item.keterangan}',
    ].join('\n');

    return AppListRow(
      leading: _rowIcon(CupertinoIcons.doc_text_fill),
      title: item.keperluan,
      subtitle: detail,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill(item.status, tone: _statusTone(item.status)),
          if (item.canDelete)
            IconButton(
              onPressed: () => _showDeleteConfirmation(item),
              tooltip: 'Hapus Pengajuan',
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

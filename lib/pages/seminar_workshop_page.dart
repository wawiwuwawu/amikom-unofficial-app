import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/seminar_workshop.dart';
import '../services/seminar_workshop_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/seminar_workshop_form_sheet.dart';

/// Halaman Seminar & Workshop Mahasiswa.
///
/// Redesign memakai design system:
///   * kerangka halaman memakai [AppScaffold] — tombol kembali otomatis dari
///     route, `onBack` dipertahankan untuk pemanggil lama;
///   * daftar kegiatan jadi baris [AppListRow] dalam satu [AppListGroup]
///     (bukan satu kartu per kegiatan), status verifikasi jadi [AppPill],
///     detail peran/tahun/keterangan lewat [AppKeyValue], aksi Edit/Hapus/Unduh
///     tetap di baris yang sama;
///   * keadaan memuat / galat / kosong memakai [AppLoading], [AppErrorState],
///     [AppEmptyState].
/// Semua panggilan service, state, dan navigasi tidak berubah.
class SeminarWorkshopPage extends StatefulWidget {
  final VoidCallback onBack;

  const SeminarWorkshopPage({super.key, required this.onBack});

  @override
  State<SeminarWorkshopPage> createState() => _SeminarWorkshopPageState();
}

class _SeminarWorkshopPageState extends State<SeminarWorkshopPage> {
  final _service = SeminarWorkshopService();
  List<SeminarWorkshopItem> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getSeminarWorkshop();
      setState(() {
        _list = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _showAddFormSheet([SeminarWorkshopItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SeminarWorkshopFormSheet(
        onSuccess: _loadData,
        itemToEdit: item,
      ),
    );
  }

  Future<void> _deleteItem(SeminarWorkshopItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data "${item.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.hapusSeminarWorkshop(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seminar / Workshop berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _downloadFile(SeminarWorkshopItem item) async {
    if (item.fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File sertifikat tidak tersedia')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengunduh file sertifikat...')),
      );

      final filePath = await _service.downloadFile(
        item.id,
        item.file.isNotEmpty ? item.file : 'seminar_${item.id}.pdf',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File disimpan di: $filePath'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () async {
              final result = await OpenFilex.open(filePath);
              if (result.type != ResultType.done && item.fileUrl.isNotEmpty) {
                final uri = Uri.parse(item.fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    final AppPillTone tone;
    final String label;

    switch (status.toLowerCase()) {
      case 'valid':
        tone = AppPillTone.success;
        label = 'Valid';
      case 'ditolak':
        tone = AppPillTone.danger;
        label = 'Ditolak';
      default:
        tone = AppPillTone.warning;
        label = 'Menunggu';
    }

    return AppPill(label, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Seminar & Workshop Mahasiswa',
      subtitle: 'Kegiatan, peran, dan sertifikat',
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFormSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Tambah Seminar/Workshop'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoading();
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        children: [
          AppErrorState(message: _error!, onRetry: _loadData),
        ],
      );
    }

    if (_list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          const AppEmptyState(
            title: 'Belum ada data seminar & workshop',
            message: 'Tambahkan kegiatan lewat tombol di kanan bawah.',
            icon: CupertinoIcons.doc_plaintext,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + 110,
      ),
      children: [
        AppListGroup(
          children: [
            for (var i = 0; i < _list.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, thickness: 1, color: AppColors.border),
              _buildItemBlock(_list[i]),
            ],
          ],
        ).animate().fadeIn(duration: 220.ms),
      ],
    );
  }

  /// Satu blok kegiatan: baris utama + detail + aksi.
  Widget _buildItemBlock(SeminarWorkshopItem item) {
    final isVerified = item.verifikasi == 1 || item.status.toLowerCase() == 'valid';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          leading: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: AppDeco.softPrimary(radius: AppRadius.sm),
            child: const Icon(
              CupertinoIcons.doc_plaintext,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          title: item.judul,
          subtitle: '${item.tahun} • ${item.jenisAktivitas}',
          trailing: _buildStatusBadge(item.status),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.sebagai.isNotEmpty)
                AppKeyValue(label: 'Sebagai', value: item.sebagai),
              if (item.keterangan.isNotEmpty)
                AppKeyValue(label: 'Keterangan', value: item.keterangan),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isVerified) ...[
                    TextButton.icon(
                      onPressed: () => _showAddFormSheet(item),
                      icon: const Icon(CupertinoIcons.pencil, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteItem(item),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      icon: const Icon(CupertinoIcons.trash, size: 18),
                      label: const Text('Hapus'),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () => _downloadFile(item),
                    icon: const Icon(CupertinoIcons.cloud_download, size: 18),
                    label: const Text('Unduh File'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

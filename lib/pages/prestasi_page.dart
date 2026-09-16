import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/prestasi.dart';
import '../services/prestasi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/prestasi_form_sheet.dart';

class PrestasiPage extends StatefulWidget {
  final VoidCallback onBack;

  const PrestasiPage({super.key, required this.onBack});

  @override
  State<PrestasiPage> createState() => _PrestasiPageState();
}

class _PrestasiPageState extends State<PrestasiPage> {
  final _service = PrestasiService();
  List<PrestasiItem> _list = [];
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
      final data = await _service.getPrestasi();
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

  void _showAddFormSheet([PrestasiItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrestasiFormSheet(
        onSuccess: _loadData,
        itemToEdit: item,
      ),
    );
  }

  Future<void> _deleteItem(PrestasiItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus prestasi "${item.kejuaraan}"?'),
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
      await _service.hapusPrestasi(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prestasi berhasil dihapus'),
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

  Future<void> _downloadFile(PrestasiItem item) async {
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
        item.file.isNotEmpty ? item.file : 'sertifikat_${item.id}.pdf',
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

  /// Label & warna pil status verifikasi prestasi.
  (String, AppPillTone) _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return ('Valid', AppPillTone.success);
      case 'ditolak':
        return ('Ditolak', AppPillTone.danger);
      default:
        return ('Menunggu', AppPillTone.warning);
    }
  }

  bool _isValid(PrestasiItem item) =>
      item.verifikasi == 1 || item.status.toLowerCase() == 'valid';

  ButtonStyle get _compactAction => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  ButtonStyle get _dangerAction => TextButton.styleFrom(
        foregroundColor: AppColors.danger,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Prestasi Mahasiswa',
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FilledButton.icon(
        onPressed: _showAddFormSheet,
        icon: const Icon(CupertinoIcons.add, size: 18),
        label: const Text('Tambah Prestasi'),
      ),
      body: AppAsyncView<List<PrestasiItem>>(
        loading: _loading,
        error: _error,
        data: _list,
        isEmpty: (data) => data.isEmpty,
        onRetry: _loadData,
        loadingMessage: 'Memuat data prestasi…',
        emptyTitle: 'Belum ada data prestasi mahasiswa',
        emptyIcon: CupertinoIcons.star_fill,
        builder: (items) => RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + 96,
            ),
            children: [
              _buildSummary(items),
              AppSection(
                title: 'Daftar Prestasi',
                child: AppListGroup.from([
                  for (final item in items) _buildItem(item),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ringkasan angka dari data yang sudah dimuat (tanpa panggilan service baru).
  Widget _buildSummary(List<PrestasiItem> items) {
    final valid = items.where(_isValid).length;
    final menunggu = items
        .where((e) => e.status.toLowerCase() == 'menunggu')
        .length;

    return Row(
      children: [
        Expanded(
          child: AppStatTile(
            value: '${items.length}',
            label: 'Total',
            icon: CupertinoIcons.star_fill,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '$valid',
            label: 'Valid',
            icon: CupertinoIcons.checkmark_seal_fill,
            accent: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '$menunggu',
            label: 'Menunggu',
            icon: CupertinoIcons.clock_fill,
            accent: AppColors.warning,
          ),
        ),
      ],
    );
  }

  /// Satu baris prestasi: judul, keterangan singkat, status, lalu aksinya.
  Widget _buildItem(PrestasiItem item) {
    final (statusLabel, statusTone) = _statusStyle(item.status);
    final canEdit = !_isValid(item);

    final subtitle = [
      if (item.perolehan.isNotEmpty) item.perolehan,
      if (item.tahun.isNotEmpty) item.tahun,
      if (item.jenisAktivitas.isNotEmpty) item.jenisAktivitas,
      if (item.keterangan.isNotEmpty) item.keterangan,
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          title: item.kejuaraan,
          subtitle: subtitle.isEmpty ? null : subtitle,
          trailing: AppPill(statusLabel, tone: statusTone),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (canEdit) ...[
                TextButton.icon(
                  onPressed: () => _showAddFormSheet(item),
                  style: _compactAction,
                  icon: const Icon(CupertinoIcons.pencil, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteItem(item),
                  style: _dangerAction,
                  icon: const Icon(CupertinoIcons.trash, size: 16),
                  label: const Text('Hapus'),
                ),
              ],
              TextButton.icon(
                onPressed: () => _downloadFile(item),
                style: _compactAction,
                icon: const Icon(CupertinoIcons.cloud_download, size: 16),
                label: const Text('Unduh File'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sertifikasi.dart';
import '../services/sertifikasi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/sertifikasi_form_sheet.dart';

class SertifikasiPage extends StatefulWidget {

  const SertifikasiPage({super.key});

  @override
  State<SertifikasiPage> createState() => _SertifikasiPageState();
}

class _SertifikasiPageState extends State<SertifikasiPage> {
  final _service = SertifikasiService();
  List<SertifikasiItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getSertifikasi();
      if (mounted) {
        setState(() {
          _items = items;
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

  void _showForm([SertifikasiItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SertifikasiFormSheet(
        onSuccess: _load,
        itemToEdit: item,
      ),
    );
  }

  Future<void> _deleteItem(SertifikasiItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Sertifikasi'),
        content: Text('Apakah Anda yakin ingin menghapus sertifikasi "${item.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    // Tampilkan loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menghapus data...')),
    );

    try {
      await _service.hapusSertifikasi(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil dihapus')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _downloadFile(SertifikasiItem item) async {
    if (item.fileUrl.isNotEmpty && item.fileUrl.startsWith('http')) {
      final uri = Uri.parse(item.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh file...')),
    );

    try {
      final filename = item.file.isNotEmpty ? item.file : 'sertifikat_${item.id}.pdf';
      final path = await _service.downloadFile(item.id, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File tersimpan di $path'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () {
                OpenFilex.open(path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  bool _isValid(SertifikasiItem item) =>
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
      title: 'Sertifikasi Kompetensi',
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FilledButton.icon(
        onPressed: _showForm,
        icon: const Icon(CupertinoIcons.add, size: 18),
        label: const Text('Tambah Sertifikasi'),
      ),
      body: AppAsyncView<List<SertifikasiItem>>(
        loading: _loading,
        error: _error,
        data: _items,
        isEmpty: (data) => data.isEmpty,
        onRetry: _load,
        loadingMessage: 'Memuat data sertifikasi…',
        emptyTitle: 'Belum ada data sertifikasi kompetensi',
        emptyIcon: CupertinoIcons.rosette,
        builder: (items) => RefreshIndicator(
          onRefresh: _load,
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
                title: 'Daftar Sertifikasi',
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
  Widget _buildSummary(List<SertifikasiItem> items) {
    final valid = items.where(_isValid).length;

    return Row(
      children: [
        Expanded(
          child: AppStatTile(
            value: '${items.length}',
            label: 'Total',
            icon: CupertinoIcons.doc_text_search,
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
      ],
    );
  }

  /// Satu baris sertifikasi: judul, tahun & nilai, status verifikasi, lalu aksinya.
  Widget _buildItem(SertifikasiItem item) {
    final isValid = _isValid(item);

    final subtitle = [
      'Tahun: ${item.tahun}',
      'Nilai / Grade: ${item.grade}',
      if (item.keterangan.isNotEmpty) 'Catatan: ${item.keterangan}',
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          title: item.judul,
          subtitle: subtitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppPill(
                isValid ? 'Valid' : 'Belum Verifikasi',
                tone: isValid ? AppPillTone.success : AppPillTone.warning,
              ),
              if (item.grade.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                AppGradeBadge(grade: item.grade, size: 30),
              ],
            ],
          ),
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
              if (!isValid) ...[
                TextButton.icon(
                  onPressed: () => _showForm(item),
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

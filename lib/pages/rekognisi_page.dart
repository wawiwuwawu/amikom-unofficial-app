import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/rekognisi.dart';
import '../services/rekognisi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/rekognisi_form_sheet.dart';

/// Halaman Rekognisi Mahasiswa.
///
/// Redesign memakai design system:
///   * kerangka halaman memakai [AppScaffold] — tombol kembali disediakan
///     otomatis mengikuti route, `onBack` dipertahankan untuk pemanggil lama;
///   * daftar rekognisi disajikan sebagai baris [AppListRow] bertumpuk dalam
///     satu [AppListGroup] (bukan satu kartu per item), status verifikasi jadi
///     [AppPill], detail kontribusi/tautan/catatan memakai [AppKeyValue], dan
///     aksi Edit/Hapus/Unduh tetap pada baris yang sama;
///   * keadaan memuat / galat / kosong memakai [AppLoading], [AppErrorState],
///     dan [AppEmptyState].
/// Semua panggilan service, state, dan navigasi tidak berubah.
class RekognisiPage extends StatefulWidget {
  final VoidCallback? onBack;

  const RekognisiPage({super.key, this.onBack});

  @override
  State<RekognisiPage> createState() => _RekognisiPageState();
}

class _RekognisiPageState extends State<RekognisiPage> {
  final _service = RekognisiService();
  List<RekognisiItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getRekognisi();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm([RekognisiItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RekognisiFormSheet(
        onSuccess: _load,
        itemToEdit: item,
      ),
    );
  }

  Future<void> _deleteItem(RekognisiItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rekognisi'),
        content: Text('Apakah Anda yakin ingin menghapus data rekognisi "${item.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menghapus data...')),
    );

    try {
      await _service.hapusRekognisi(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dihapus')),
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

  Future<void> _downloadFile(RekognisiItem item) async {
    if (item.file.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berkas dokumen tidak tersedia')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh berkas...')),
    );

    try {
      final filename = item.file.isNotEmpty ? item.file : 'rekognisi_${item.id}.pdf';
      final path = await _service.downloadFile(item.id, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berkas tersimpan di $path'),
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Rekognisi Mahasiswa',
      subtitle: 'Prestasi & kegiatan yang diakui',
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(CupertinoIcons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return AppAsyncView<List<RekognisiItem>>(
      loading: _loading,
      error: _error,
      data: _items,
      isEmpty: (list) => list.isEmpty,
      onRetry: _load,
      emptyTitle: 'Belum ada data rekognisi mahasiswa',
      emptyMessage: 'Tambahkan rekognisi lewat tombol + di kanan bawah.',
      emptyIcon: CupertinoIcons.rosette,
      builder: (list) => RefreshIndicator(
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
            AppListGroup(
              children: [
                for (var i = 0; i < list.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, thickness: 1, color: AppColors.border),
                  _buildItemBlock(list[i]),
                ],
              ],
            ).animate().fadeIn(duration: 220.ms),
          ],
        ),
      ),
    );
  }

  /// Satu blok data rekognisi: baris utama + detail + aksi.
  Widget _buildItemBlock(RekognisiItem item) {
    final isValid = item.verifikasi == 1 || item.status.toLowerCase() == 'valid';

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
              CupertinoIcons.rosette,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          title: item.judul,
          subtitle: 'Tingkat: ${item.tingkat} • Tahun: ${item.tahun}',
          trailing: AppPill(
            isValid ? 'Valid' : 'Belum Verifikasi',
            tone: isValid ? AppPillTone.success : AppPillTone.warning,
          ),
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
              if (item.kontribusi.isNotEmpty)
                AppKeyValue(label: 'Kontribusi', value: item.kontribusi),
              if (item.link.isNotEmpty)
                InkWell(
                  onTap: () async {
                    final uri = Uri.tryParse(item.link);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.link,
                          size: 14,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            item.link,
                            style: AppText.bodySm.copyWith(
                              color: AppColors.info,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (item.keterangan.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Catatan: ${item.keterangan}',
                    style: AppText.bodySm.copyWith(color: AppColors.danger),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isValid) ...[
                    TextButton.icon(
                      onPressed: () => _showForm(item),
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
                  if (item.file.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _downloadFile(item),
                      icon: const Icon(CupertinoIcons.cloud_download, size: 18),
                      label: const Text('Unduh Berkas'),
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

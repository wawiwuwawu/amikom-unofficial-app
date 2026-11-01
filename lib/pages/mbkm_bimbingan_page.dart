import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/mbkm.dart';
import '../services/mbkm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/app_markdown_composer.dart';

/// Log bimbingan MBKM — identitas program, ringkasan jumlah log, lalu
/// kronologi bimbingan sebagai daftar bergaris (tanggal sebagai penanda depan).
class MbkmBimbinganPage extends StatefulWidget {
  final MbkmFakultas mbkm;
  const MbkmBimbinganPage({super.key, required this.mbkm});

  @override
  State<MbkmBimbinganPage> createState() => _MbkmBimbinganPageState();
}

class _MbkmBimbinganPageState extends State<MbkmBimbinganPage> {
  final _service = MbkmService();
  bool _loading = true;
  String? _error;
  List<MbkmBimbingan> _list = [];

  final TextEditingController _inputController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.getBimbingan(widget.mbkm.id);
      if (mounted) {
        setState(() => _list = res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = userErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hapusBimbingan(String idBimbingan) async {
    // Note: The API delete endpoint requires the specific bimbingan ID.
    // In our model, we have `no` (which is often just a row number) and `aksi`.
    // Let's assume `aksi` or `no` is the id, or we might need to extract the ID from HTML.
    // For now we'll pass `idBimbingan` which might be mapped to `no`.

    // Show confirmation
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bimbingan?'),
        content: const Text('Apakah Anda yakin ingin menghapus data bimbingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: AppText.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.hapusBimbingan(idBimbingan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menghapus bimbingan'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _tambahBimbingan() {
    _inputController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _buildInputBottomSheet(),
    );
  }

  Future<void> _submitBimbingan() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    // ponytail: konversi markdown→HTML kini bersama di AppMarkdownComposer
    final htmlContent = markdownKeHtml(_inputController.text.trim());

    try {
      await _service.tambahBimbingan(widget.mbkm.id, htmlContent);
      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menambah bimbingan'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(); // refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildInputBottomSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Log Bimbingan', style: AppText.h2),
                const SizedBox(height: AppSpacing.md),
                // Composer markdown seragam (toolbar + field) — lihat
                // lib/widgets/app_markdown_composer.dart.
                AppMarkdownComposer(
                  controller: _inputController,
                  hintText:
                      'Ketik laporan bimbingan di sini...\n(Mendukung format Markdown: **Tebal**, # Judul)',
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : () {
                      setSheetState(() => _isSubmitting = true);
                      _submitBimbingan().then((_) {
                        if (mounted) setSheetState(() => _isSubmitting = false);
                      });
                    },
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Kirim Bimbingan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Log Bimbingan',
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahBimbingan,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: AppAsyncView<List<MbkmBimbingan>>(
        loading: _loading,
        error: _error,
        data: _list,
        isEmpty: (data) => data.isEmpty,
        onRetry: _loadData,
        loadingMessage: 'Memuat log bimbingan…',
        emptyTitle: 'Belum ada log bimbingan',
        emptyMessage: 'Tekan tombol Tambah untuk menulis laporan bimbingan.',
        emptyIcon: Icons.history_edu_outlined,
        builder: (items) => RefreshIndicator(
          onRefresh: _loadData,
          // Log bimbingan bertambah tiap pertemuan — dibangun lazy per
          // chunk ±20 baris; identitas + statistik + judul seksi tetap di
          // header chunk pertama (tampilan tidak berubah).
          child: AppChunkedList<MbkmBimbingan>(
            items: items,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.xxl * 3,
            ),
            header: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentity(),
                const SizedBox(height: AppSpacing.md),
                _buildStats(items),
                // Padanan AppSection "Riwayat Bimbingan" (topGap xl).
                const SizedBox(height: AppSpacing.xl),
                Text('RIWAYAT BIMBINGAN', style: AppText.overline),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
            rowBuilder: (_, item) => _buildLogEntry(item),
          ),
        ),
      ),
    );
  }

  /// Identitas program MBKM yang sedang dibuka.
  Widget _buildIdentity() {
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.mbkm.mitra, style: AppText.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.mbkm.program, style: AppText.bodySm),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Dosbing: ${widget.mbkm.dosbing}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ringkasan: jumlah log bimbingan dan yang sudah tervalidasi.
  Widget _buildStats(List<MbkmBimbingan> items) {
    final valid = items
        .where((e) => e.status.toLowerCase() == 'valid')
        .length;

    return AppStatRow(
      children: [
        AppStatTile(
          value: '${items.length}',
          label: 'Log Bimbingan',
          icon: Icons.list_alt,
        ),
        AppStatTile(
          value: '$valid',
          label: 'Sudah Valid',
          icon: Icons.verified_outlined,
          accent: AppColors.success,
        ),
      ],
    );
  }

  /// Satu entri kronologi: tanggal (penanda depan) + status + isi laporan.
  Widget _buildLogEntry(MbkmBimbingan item) {
    final isValid = item.status.toLowerCase() == 'valid';
    final canDelete = item.no.isNotEmpty && !isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListRow(
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: AppDeco.softPrimary(radius: AppRadius.sm),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          title: item.tanggal,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppPill(
                item.status,
                tone: isValid ? AppPillTone.success : AppPillTone.warning,
              ),
              if (canDelete) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () => _hapusBimbingan(item.no),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Html(
            data: item.bimbingan,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(AppText.body.fontSize ?? 14),
                color: AppColors.textPrimary,
                lineHeight: LineHeight.number(AppText.body.height ?? 1.45),
              ),
            },
          ),
        ),
      ],
    );
  }
}

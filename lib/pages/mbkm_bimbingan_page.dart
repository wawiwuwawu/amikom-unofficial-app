import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/mbkm.dart';
import '../services/mbkm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

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
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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

    // ponytail: lightweight native markdown-to-HTML converter without 700KB package:markdown
    final htmlContent = _convertMarkdownToHtml(_inputController.text.trim());

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
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// ponytail: native conversion for the 4 composer toolbar tokens (**bold**, #, ##, -)
  String _convertMarkdownToHtml(String input) {
    String escaped = input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    escaped = escaped.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );

    final lines = escaped.split(RegExp(r'\r?\n'));
    final result = <String>[];
    bool inList = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('## ')) {
        if (inList) {
          result.add('</ul>');
          inList = false;
        }
        result.add('<h2>${trimmed.substring(3)}</h2>');
      } else if (trimmed.startsWith('# ')) {
        if (inList) {
          result.add('</ul>');
          inList = false;
        }
        result.add('<h1>${trimmed.substring(2)}</h1>');
      } else if (trimmed.startsWith('- ')) {
        if (!inList) {
          result.add('<ul>');
          inList = true;
        }
        result.add('<li>${trimmed.substring(2)}</li>');
      } else {
        if (inList) {
          result.add('</ul>');
          inList = false;
        }
        if (trimmed.isNotEmpty) {
          result.add('<p>$trimmed</p>');
        }
      }
    }
    if (inList) {
      result.add('</ul>');
    }
    return result.join();
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _inputController.text;
    final selection = _inputController.selection;
    if (selection.start == -1) {
      _inputController.text = '$text$prefix$suffix';
      return;
    }
    final newText = text.replaceRange(selection.start, selection.end, '$prefix${text.substring(selection.start, selection.end)}$suffix');
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + (selection.end - selection.start)),
    );
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
                // Toolbar Markdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.format_bold, size: 20),
                        onPressed: () => _insertMarkdown('**', '**'),
                        tooltip: 'Tebal',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                      IconButton(
                        icon: const Icon(Icons.title, size: 20), // H1
                        onPressed: () => _insertMarkdown('# ', ''),
                        tooltip: 'Heading 1',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_fields, size: 16), // H2
                        onPressed: () => _insertMarkdown('## ', ''),
                        tooltip: 'Heading 2',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_list_bulleted, size: 20),
                        onPressed: () => _insertMarkdown('- ', ''),
                        tooltip: 'List',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _inputController,
                  maxLines: 8,
                  minLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Ketik laporan bimbingan di sini...\n(Mendukung format Markdown: **Tebal**, # Judul)',
                  ),
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
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.xxl * 3,
            ),
            children: [
              _buildIdentity(),
              const SizedBox(height: AppSpacing.md),
              _buildStats(items),
              AppSection(
                title: 'Riwayat Bimbingan',
                child: AppListGroup.from([
                  for (final item in items) _buildLogEntry(item),
                ]),
              ),
            ],
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

    return Row(
      children: [
        Expanded(
          child: AppStatTile(
            value: '${items.length}',
            label: 'Log Bimbingan',
            icon: Icons.list_alt,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '$valid',
            label: 'Sudah Valid',
            icon: Icons.verified_outlined,
            accent: AppColors.success,
          ),
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

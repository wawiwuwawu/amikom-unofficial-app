import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/mbkm.dart';
import '../services/mbkm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import 'mbkm_bimbingan_page.dart';

/// MBKM internal kampus — ringkasan program + kelengkapan dokumen disajikan
/// sebagai daftar bergaris (AppListGroup/AppListRow), bukan kartu per item.
class MbkmPage extends StatefulWidget {
  final VoidCallback? onBack;
  const MbkmPage({super.key, this.onBack});

  @override
  State<MbkmPage> createState() => _MbkmPageState();
}

class _MbkmPageState extends State<MbkmPage> {
  final _service = MbkmService();
  bool _loading = true;
  String? _error;
  List<MbkmFakultas> _list = [];

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
      final res = await _service.getDaftarMBKM();
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'MBKM Internal Kampus',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: AppAsyncView<List<MbkmFakultas>>(
        loading: _loading,
        error: _error,
        data: _list,
        isEmpty: (data) => data.isEmpty,
        onRetry: _loadData,
        loadingMessage: 'Memuat data MBKM…',
        emptyTitle: 'Anda belum terdaftar di program MBKM',
        emptyIcon: Icons.school_outlined,
        builder: (items) => RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
            ),
            children: [
              _buildSummary(items),
              AppSection(
                title: 'Program MBKM',
                child: Column(
                  children: [
                    for (final (index, item) in items.indexed) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.xl),
                      _buildProgram(item),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ringkasan angka: jumlah program, komitmen, dan luaran yang sudah lengkap.
  Widget _buildSummary(List<MbkmFakultas> items) {
    final komitmen = items.where((e) => e.komitmen == '1').length;
    final luaran = items.where((e) => e.fileLolos.isNotEmpty).length;

    return Row(
      children: [
        Expanded(
          child: AppStatTile(
            value: '${items.length}',
            label: 'Program',
            icon: Icons.school_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '$komitmen',
            label: 'Komitmen',
            icon: Icons.task_alt,
            accent: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '$luaran',
            label: 'Luaran',
            icon: Icons.rocket_launch_outlined,
            accent: AppColors.info,
          ),
        ),
      ],
    );
  }

  /// Satu pendaftaran MBKM: identitas program + baris data + aksi.
  Widget _buildProgram(MbkmFakultas item) {
    final komitmenDone = item.komitmen == '1';
    final luaranDone = item.fileLolos.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(item.mitra, style: AppText.h2)),
            const SizedBox(width: AppSpacing.sm),
            AppPill(item.program, tone: AppPillTone.info),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              '${item.thnAkademik} - ${item.semester}',
              style: AppText.bodySm,
            ),
            const Spacer(),
            if (item.status.isNotEmpty) AppPill(item.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppListGroup.from([
          AppListRow(
            leading: const Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.primarySoft,
            ),
            title: item.nama,
            subtitle: item.prodi.isEmpty ? null : item.prodi,
          ),
          AppListRow(
            leading: const Icon(
              Icons.people_outline,
              size: 18,
              color: AppColors.primarySoft,
            ),
            title: 'Dosbing: ${item.dosbing}',
          ),
          AppListRow(
            leading: const Icon(
              Icons.description_outlined,
              size: 18,
              color: AppColors.primarySoft,
            ),
            title: 'Komitmen',
            trailing: AppPill(
              komitmenDone ? 'Sudah Upload' : 'Belum Upload',
              tone: komitmenDone ? AppPillTone.success : AppPillTone.warning,
            ),
          ),
          AppListRow(
            leading: const Icon(
              Icons.rocket_launch_outlined,
              size: 18,
              color: AppColors.primarySoft,
            ),
            title: 'Luaran',
            trailing: AppPill(
              luaranDone ? 'Sudah Upload' : 'Belum Upload',
              tone: luaranDone ? AppPillTone.success : AppPillTone.warning,
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _buildActions(item),
      ],
    );
  }

  Widget _buildActions(MbkmFakultas item) {
    final komitmenDone = item.komitmen == '1';
    final luaranDone = item.fileLolos.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MbkmBimbinganPage(mbkm: item),
              ),
            ),
            icon: const Icon(Icons.list_alt, size: 18),
            label: const Text('Log Bimbingan'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: komitmenDone
                    ? null
                    : () => _showUploadKomitmen(item),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: Text(komitmenDone ? 'Selesai' : 'Komitmen'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: luaranDone ? null : () => _showUploadLuaran(item),
                icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                label: Text(luaranDone ? 'Selesai' : 'Luaran'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showUploadKomitmen(MbkmFakultas mbkm) {
    String? komitmenPath;
    String? pembayaranPath;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
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
                  Text('Upload Dokumen Komitmen', style: AppText.h2),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFilePicker(
                    label: 'Surat Komitmen (PDF)',
                    path: komitmenPath,
                    onPick: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null) {
                        setSheetState(
                          () => komitmenPath = result.files.single.path,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFilePicker(
                    label: 'Bukti Pembayaran (PDF/JPG/PNG)',
                    path: pembayaranPath,
                    onPick: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      );
                      if (result != null) {
                        setSheetState(
                          () => pembayaranPath = result.files.single.path,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          (isSubmitting ||
                              komitmenPath == null ||
                              pembayaranPath == null)
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              try {
                                await _service.uploadKomitmen(
                                  mbkm.id,
                                  komitmenPath!,
                                  pembayaranPath!,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Berhasil upload dokumen komitmen',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  _loadData();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setSheetState(() => isSubmitting = false);
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Upload'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUploadLuaran(MbkmFakultas mbkm) {
    String? luaranPath;
    String jenis = '';
    final linkController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
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
                  Text('Upload File Luaran', style: AppText.h2),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      labelText: 'Link Laporan (Google Drive)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: jenis.isEmpty ? null : jenis,
                    items: const [
                      DropdownMenuItem(
                        value: 'Proposal PKM',
                        child: Text('Proposal PKM'),
                      ),
                      DropdownMenuItem(value: 'HKI', child: Text('HKI')),
                      DropdownMenuItem(value: 'Jurnal', child: Text('Jurnal')),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => jenis = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Jenis Luaran',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFilePicker(
                    label: 'File Luaran (PDF)',
                    path: luaranPath,
                    onPick: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null) {
                        setSheetState(
                          () => luaranPath = result.files.single.path,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (isSubmitting || luaranPath == null)
                          ? null
                          : () async {
                              if (linkController.text.trim().isEmpty ||
                                  jenis.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Isi semua field'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => isSubmitting = true);
                              try {
                                await _service.uploadLuaran(
                                  mbkm.id,
                                  linkController.text,
                                  jenis,
                                  luaranPath!,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Berhasil upload luaran'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  _loadData();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setSheetState(() => isSubmitting = false);
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Upload'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Pemilih berkas — baris bergaris memakai tema global, bukan kartu sendiri.
  Widget _buildFilePicker({
    required String label,
    required String? path,
    required VoidCallback onPick,
  }) {
    return AppSurface(
      onTap: onPick,
      padding: EdgeInsets.zero,
      child: AppListRow(
        leading: Icon(
          Icons.upload_file,
          color: path == null ? AppColors.textMuted : AppColors.primary,
        ),
        title: label,
        subtitle: path?.split('/').last,
        trailing: path == null
            ? null
            : const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/expandable_html.dart';
import '../../models/pusat_studi.dart';
import '../../services/pusat_studi_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_kit.dart';
import 'pusat_studi_detail_page.dart';

class PusatStudiJoinedPage extends StatefulWidget {
  final PusatStudi pusatStudi;

  const PusatStudiJoinedPage({super.key, required this.pusatStudi});

  @override
  State<PusatStudiJoinedPage> createState() => _PusatStudiJoinedPageState();
}

class _PusatStudiJoinedPageState extends State<PusatStudiJoinedPage> {
  final PusatStudiService _service = PusatStudiService();
  bool _isLoading = true;
  String _error = '';
  List<JoinedDetailTema> _temaList = [];
  PusatStudiJoinedPageData? _pageData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final results = await Future.wait([
        _service.getJoinedDetail(widget.pusatStudi.id),
        _service.getJoinedPage(widget.pusatStudi.detailId),
      ]);
      if (mounted) {
        setState(() {
          _temaList = results[0] as List<JoinedDetailTema>;
          _pageData = results[1] as PusatStudiJoinedPageData?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openWhatsAppGroup() async {
    final url = widget.pusatStudi.grupWa;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link WhatsApp')),
        );
      }
    }
  }

  void _showProposeTemaDialog() {
    if (_pageData?.statusCode == 'diproses') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan Anda sedang diproses. Batalkan ajuan sebelum membuat ajuan baru.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    final rencanaController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Usulkan Tema Baru', style: AppText.h2.copyWith(color: AppColors.primary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: judulController,
                    decoration: const InputDecoration(labelText: 'Judul Tema'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: deskripsiController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Deskripsi Tema'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: rencanaController,
                    decoration: const InputDecoration(labelText: 'Rencana Judul Anda'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (judulController.text.trim().isEmpty || deskripsiController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Judul dan Deskripsi wajib diisi')),
                          );
                          return;
                        }
                        setStateDialog(() => isSubmitting = true);
                        try {
                          final res = await _service.proposeTema(
                            widget.pusatStudi.id,
                            judulController.text,
                            deskripsiController.text,
                            rencanaController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            final msg = res['message'] ?? 'Berhasil mengusulkan tema';
                            final isSuccess = res['success'] != false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
                              ),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setStateDialog(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Usulkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChooseTemaDialog(JoinedDetailTema tema) {
    if (_pageData?.statusCode == 'diproses') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan Anda sedang diproses. Batalkan ajuan sebelum memilih tema baru.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final rencanaController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Pilih Tema', style: AppText.h2.copyWith(color: AppColors.primary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anda akan memilih tema:\n${tema.judulTema}', style: AppText.h3),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: rencanaController,
                    decoration: const InputDecoration(
                      labelText: 'Rencana Judul Anda (Opsional / Wajib)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setStateDialog(() => isSubmitting = true);
                        try {
                          final res = await _service.chooseTema(
                            widget.pusatStudi.id,
                            tema.idTema,
                            tema.judulTema,
                            rencanaController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            final msg = res['message'] ?? 'Berhasil memilih tema';
                            final isSuccess = res['success'] != false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
                              ),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setStateDialog(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Pilih Tema'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCancelAjuanConfirmation() async {
    final idAjuan = _pageData?.idAjuan;
    if (idAjuan == null || idAjuan.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Ajuan', style: AppText.h2.copyWith(color: AppColors.primary)),
        content: const Text('Apakah Anda yakin ingin membatalkan ajuan tema ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.cancelAjuan(idAjuan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Ajuan tema berhasil dibatalkan'),
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
  }

  Widget _buildInfoBanner() {
    final banner = _pageData?.infoBanner;
    if (banner == null || banner.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppSurface(
        variant: AppSurfaceVariant.hero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                banner,
                style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionAlert() {
    if (_pageData?.statusCode.toLowerCase().trim() != 'ditolak') return const SizedBox.shrink();
    final alasan = _pageData?.alasanDitolak;
    if (alasan == null || alasan.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppSurface(
        variant: AppSurfaceVariant.danger,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.danger, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Ajuan Ditolak',
                    style: AppText.h3.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(alasan, style: AppText.body.copyWith(color: AppColors.danger)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Silakan ajukan tema baru atau pilih tema yang tersedia di bawah.',
              style: AppText.bodySm.copyWith(color: AppColors.danger, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_pageData == null || (_pageData!.statusCode.isEmpty && _pageData!.detailPengajuan == null)) {
      return const SizedBox.shrink();
    }

    final String rawStatus = _pageData!.statusCode.toLowerCase().trim();
    final String statusLabel = _pageData!.statusText.isNotEmpty ? _pageData!.statusText : _pageData!.statusCode;

    final AppPillTone tone;
    if (rawStatus == 'diproses' || rawStatus == 'di proses') {
      tone = AppPillTone.info;
    } else if (rawStatus == 'diterima' || rawStatus == 'acc') {
      tone = AppPillTone.success;
    } else if (rawStatus == 'ditolak') {
      tone = AppPillTone.danger;
    } else {
      tone = AppPillTone.neutral;
    }

    final detail = _pageData!.detailPengajuan;
    final bool isDiproses = rawStatus == 'diproses' || rawStatus == 'di proses';
    final bool isDiterima = rawStatus == 'diterima' || rawStatus == 'acc';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppSurface(
        radius: AppRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Status Ajuan Tema',
                    style: AppText.h3.copyWith(color: AppColors.primary),
                  ),
                ),
                AppPill(statusLabel, tone: tone),
              ],
            ),
            if (detail != null) ...[
              const Divider(height: AppSpacing.xl, color: AppColors.border),
              if (detail.rencanaJudul.isNotEmpty)
                AppKeyValue(label: 'Rencana Judul', value: detail.rencanaJudul, emphasize: true),
              if (detail.namaTema.isNotEmpty)
                AppKeyValue(label: 'Tema', value: detail.namaTema),
              if (detail.jenisTema.isNotEmpty)
                AppKeyValue(label: 'Jenis', value: detail.jenisTema),
              if (detail.tanggalPengajuan.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(detail.tanggalPengajuan, style: AppText.label),
                ),
            ],
            if (_pageData!.idAjuan != null && _pageData!.idAjuan!.isNotEmpty && isDiproses) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCancelAjuanConfirmation,
                  icon: const Icon(CupertinoIcons.xmark_circle, size: 18),
                  label: const Text('Batalkan Ajuan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
            ],
            if (_pageData!.canSubmitProposal && isDiterima) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status Ajuan Diterima! Silakan lanjutkan ke pengisian proposal skripsi.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.doc_text_fill, size: 18),
                  label: const Text('Pengisian Judul Proposal Skripsi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Kartu tema = konten panjang (deskripsi HTML + aksi), bukan baris data.
  Widget _buildTemaCard(JoinedDetailTema tema, bool canChooseTema) {
    final bool showPilihButton = tema.canChoose && !tema.isFull && canChooseTema;

    return AppSurface(
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tema.judulTema,
                  style: AppText.h3.copyWith(color: AppColors.primary),
                ),
              ),
              if (tema.isFull)
                const AppPill('Penuh', tone: AppPillTone.danger)
              else if (tema.isProposed)
                const AppPill('Usulan Saya', tone: AppPillTone.info),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ExpandableHtml(htmlData: tema.deskripsi),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(CupertinoIcons.person_solid, size: 14, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(tema.pengusul, style: AppText.bodySm)),
              const SizedBox(width: AppSpacing.sm),
              AppPill('Kuota: ${tema.kuota}', tone: AppPillTone.warning),
            ],
          ),
          if (tema.statusText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSurface(
              radius: AppRadius.sm,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  tema.statusText,
                  style: AppText.bodySm.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
          if (showPilihButton) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showChooseTemaDialog(tema),
                icon: const Icon(CupertinoIcons.check_mark_circled, size: 18),
                label: const Text('Pilih Tema Ini'),
              ),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentStatus = _pageData?.statusCode.toLowerCase().trim() ?? '';
    final bool isDiprosesStatus = currentStatus == 'diproses' || currentStatus == 'di proses';
    final bool canChooseTema = !isDiprosesStatus;

    return AppScaffold(
      title: widget.pusatStudi.nama,
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        if (widget.pusatStudi.grupWa != null && widget.pusatStudi.grupWa!.isNotEmpty)
          IconButton(
            icon: const Icon(CupertinoIcons.chat_bubble_2_fill, color: AppColors.success),
            tooltip: 'Grup WhatsApp',
            onPressed: _openWhatsAppGroup,
          ),
        IconButton(
          icon: const Icon(CupertinoIcons.info_circle_fill),
          tooltip: 'Profil Pusat Studi',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PusatStudiDetailPage(pusatStudi: widget.pusatStudi, isJoined: true),
            ));
          },
        ),
      ],
      floatingActionButton: canChooseTema
          ? FloatingActionButton.extended(
              onPressed: _showProposeTemaDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Usulkan Tema Baru'),
            )
          : null,
      body: _buildBody(canChooseTema),
    );
  }

  Widget _buildBody(bool canChooseTema) {
    if (_isLoading) return const AppLoading();

    if (_error.isNotEmpty) {
      return Padding(
        padding: AppSpacing.page,
        child: Align(
          alignment: Alignment.topCenter,
          child: AppErrorState(message: _error, onRetry: _loadData),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl * 3,
      ),
      children: [
        _buildInfoBanner(),
        _buildRejectionAlert(),
        _buildStatusCard(),
        if (_temaList.isEmpty)
          const AppEmptyState(
            title: 'Belum ada tema tersedia',
            icon: CupertinoIcons.doc_text,
          )
        else
          for (final tema in _temaList)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildTemaCard(tema, canChooseTema),
            ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/notifikasi.dart';
import '../models/pengumuman.dart'; // for Lampiran
import '../services/notifikasi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class NotifikasiDetailPage extends StatefulWidget {
  final String id;

  const NotifikasiDetailPage({super.key, required this.id});

  @override
  State<NotifikasiDetailPage> createState() => _NotifikasiDetailPageState();
}

class _NotifikasiDetailPageState extends State<NotifikasiDetailPage> {
  final _service = NotifikasiService();
  NotifikasiDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getNotifikasiDetail(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openLampiran(Lampiran lampiran) async {
    if (lampiran.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan lampiran tidak tersedia')),
      );
      return;
    }

    try {
      final uri = Uri.parse(lampiran.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Membuka tautan di browser: ${lampiran.url}')),
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka lampiran: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detail Notifikasi',
      subtitle: 'Isi lengkap & lampiran',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: AppAsyncView<NotifikasiDetail>(
        loading: _loading,
        error: _error,
        data: _detail,
        onRetry: _load,
        loadingMessage: 'Memuat detail notifikasi…',
        emptyTitle: 'Tidak ada detail notifikasi',
        emptyMessage: 'Rincian notifikasi ini belum bisa ditampilkan.',
        emptyIcon: CupertinoIcons.doc_text,
        builder: _buildContent,
      ),
    );
  }

  /// Konten utama. Keterbacaan jadi prioritas: judul tegas, meta ringkas,
  /// dan isi paragraf dengan tinggi baris lega (1.7).
  Widget _buildContent(NotifikasiDetail detail) {
    return ListView(
      padding: AppSpacing.page,
      physics: const BouncingScrollPhysics(),
      children: [
        AppSurface(
          variant: AppSurfaceVariant.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.judul.isNotEmpty ? detail.judul : 'Informasi Notifikasi',
                style: AppText.h2,
              ),
              if (detail.oleh.isNotEmpty || detail.pukul.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (detail.oleh.isNotEmpty) ...[
                      const Icon(
                        CupertinoIcons.person_circle,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          detail.oleh,
                          style: AppText.bodySm.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (detail.pukul.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(detail.pukul, style: AppText.label),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < detail.konten.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                if (detail.konten[i].contains('<') &&
                    detail.konten[i].contains('>'))
                  Html(
                    data: detail.konten[i],
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        color: AppColors.textPrimary,
                        lineHeight: LineHeight.number(1.7),
                      ),
                    },
                  )
                else
                  SelectableText(
                    detail.konten[i],
                    style: AppText.body.copyWith(height: 1.7),
                  ),
              ],
              if (detail.konten.isEmpty)
                Text(
                  'Tidak ada rincian teks tambahan.',
                  style: AppText.bodySm.copyWith(color: AppColors.textMuted),
                ),
            ],
          ),
        ),
        if (detail.lampiran.isNotEmpty)
          AppSection(
            title: 'Lampiran Dokumen',
            child: AppListGroup.from([
              for (final lamp in detail.lampiran)
                AppListRow(
                  leading: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: AppDeco.softPrimary(radius: AppRadius.sm),
                    child: const Icon(
                      CupertinoIcons.paperclip,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  title: lamp.nama,
                  trailing: const Icon(
                    CupertinoIcons.arrow_up_right_square,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onTap: () => _openLampiran(lamp),
                ),
            ]),
          ),
      ],
    );
  }
}

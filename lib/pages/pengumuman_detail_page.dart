import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pengumuman.dart';
import '../services/pengumuman_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Detail Pengumuman Akademik — halaman baca.
///
/// Susunannya dibuat mengikuti cara orang membaca dokumen: judul & meta di
/// header, isi paragraf di badan, lampiran sebagai daftar di bagian bawah.
/// Lebar baca dibatasi agar tidak melebar di tablet.
class PengumumanDetailPage extends StatefulWidget {
  final dynamic id;
  final String? detailUrl;

  const PengumumanDetailPage({
    super.key,
    required this.id,
    this.detailUrl,
  });

  @override
  State<PengumumanDetailPage> createState() => _PengumumanDetailPageState();
}

class _PengumumanDetailPageState extends State<PengumumanDetailPage> {
  final _service = PengumumanService();
  PengumumanDetail? _detail;
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
      final target = (widget.detailUrl != null && widget.detailUrl!.isNotEmpty)
          ? widget.detailUrl!
          : widget.id;
      final data = await _service.getDetail(target);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka lampiran: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detail Pengumuman',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: AppAsyncView<PengumumanDetail>(
        loading: _loading,
        error: _error,
        data: _detail,
        onRetry: _load,
        loadingMessage: 'Memuat pengumuman…',
        builder: (detail) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(detail),
                  const SizedBox(height: AppSpacing.lg),
                  _buildKonten(detail),
                  if (detail.lampiran.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildLampiran(detail),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PengumumanDetail detail) {
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.judul.isNotEmpty ? detail.judul : 'Pengumuman Akademik',
            style: AppText.h1,
          ),
          if (detail.oleh.isNotEmpty || detail.pukul.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (detail.oleh.isNotEmpty) ...[
                  const Icon(
                    CupertinoIcons.person_circle,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      detail.oleh,
                      style: AppText.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (detail.pukul.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.md),
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
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06);
  }

  Widget _buildKonten(PengumumanDetail detail) {
    if (detail.konten.isEmpty) {
      return AppSurface(
        child: const Text('Tidak ada rincian teks tambahan.'),
      );
    }

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < detail.konten.length; i++) ...[
            if (detail.konten[i].contains('<') &&
                detail.konten[i].contains('>'))
              Html(
                data: detail.konten[i],
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14.5),
                    color: AppColors.textPrimary,
                    lineHeight: LineHeight.number(1.65),
                  ),
                },
              )
            else
              SelectableText(
                detail.konten[i],
                style: AppText.body.copyWith(fontSize: 14.5, height: 1.65),
              ),
            if (i < detail.konten.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06);
  }

  Widget _buildLampiran(PengumumanDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LAMPIRAN DOKUMEN', style: AppText.overline),
        const SizedBox(height: AppSpacing.sm),
        AppListGroup.from([
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
              subtitle: 'Ketuk untuk membuka',
              trailing: const Icon(
                CupertinoIcons.arrow_up_right_square,
                size: 18,
                color: AppColors.primary,
              ),
              onTap: () => _openLampiran(lamp),
            ),
        ]),
      ],
    ).animate().fadeIn(delay: 220.ms);
  }
}

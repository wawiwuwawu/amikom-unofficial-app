import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/berita.dart';
import '../services/berita_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Detail Berita Kampus — halaman baca.
///
/// Prioritas halaman ini adalah KENYAMANAN MEMBACA: judul besar, meta kecil di
/// bawahnya, lalu isi dengan tinggi baris lega (1.7) dan lebar baca yang tidak
/// melebar di layar besar.
class BeritaDetailPage extends StatefulWidget {
  final String id;

  const BeritaDetailPage({super.key, required this.id});

  @override
  State<BeritaDetailPage> createState() => _BeritaDetailPageState();
}

class _BeritaDetailPageState extends State<BeritaDetailPage> {
  final _service = BeritaService();
  BeritaDetail? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getBeritaById(widget.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Berita Kampus',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: AppAsyncView<BeritaDetail>(
        loading: _loading,
        error: _error,
        data: _data,
        onRetry: _load,
        loadingMessage: 'Memuat berita…',
        builder: (b) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Center(
            // Batasi lebar baca agar baris tidak terlalu panjang di tablet.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (b.gambar.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(
                        b.gambar,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 200,
                          alignment: Alignment.center,
                          color: AppColors.surfaceMuted,
                          child: const Icon(
                            CupertinoIcons.photo,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  Text(b.judul, style: AppText.h1),
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_circle,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          [
                            if (b.author.isNotEmpty) b.author,
                            if (b.tanggal.isNotEmpty) b.tanggal,
                          ].join(' · '),
                          style: AppText.label,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),

                  // Isi berita — tinggi baris lega supaya enak dibaca.
                  Text(
                    b.konten,
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

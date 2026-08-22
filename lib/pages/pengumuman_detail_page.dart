import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pengumuman.dart';
import '../services/pengumuman_service.dart';
import '../widgets/glass_card.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFCFF), // Pearl White
            Color(0xFFE3F2FD), // Ice Blue
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Detail Pengumuman',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF501F66)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(CupertinoIcons.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF501F66),
                  foregroundColor: Colors.white,
                ),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_detail == null) {
      return const Center(child: Text('Tidak ada data pengumuman'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detail!.judul.isNotEmpty
                      ? _detail!.judul
                      : 'Pengumuman Akademik',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF501F66),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_detail!.oleh.isNotEmpty) ...[
                      Icon(CupertinoIcons.person_circle,
                          size: 15, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _detail!.oleh,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (_detail!.pukul.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.clock,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _detail!.pukul,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 16),

          // Konten / Isi Paragraf
          if (_detail!.konten.isNotEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _detail!.konten.length; i++) ...[
                    if (_detail!.konten[i].contains('<') &&
                        _detail!.konten[i].contains('>'))
                      Html(
                        data: _detail!.konten[i],
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(14),
                            color: Colors.black87,
                            lineHeight: LineHeight.number(1.5),
                          ),
                        },
                      )
                    else
                      SelectableText(
                        _detail!.konten[i],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    if (i < _detail!.konten.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1)
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tidak ada rincian teks tambahan.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          // Lampiran File (jika ada)
          if (_detail!.lampiran.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Lampiran Dokumen',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF501F66),
              ),
            ),
            const SizedBox(height: 10),
            for (final lamp in _detail!.lampiran)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _openLampiran(lamp),
                  borderRadius: BorderRadius.circular(12),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    borderRadius: 12,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.paperclip,
                            color: Color(0xFF501F66), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lamp.nama,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.arrow_up_right_square,
                          color: Color(0xFF501F66),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),
          ],
        ],
      ),
    );
  }
}

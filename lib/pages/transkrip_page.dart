import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transkrip.dart';
import '../services/transkrip_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/histori_ipk_sheet.dart';
import '../widgets/cumlaude_sheet.dart';
import '../widgets/progress_kelulusan_card.dart';
import '../widgets/ringkasan_skpi_widget.dart';
import '../widgets/target_ipk_simulator_sheet.dart';

class TranskripPage extends StatefulWidget {
  final VoidCallback? onBack;
  const TranskripPage({super.key, this.onBack});

  @override
  State<TranskripPage> createState() => _TranskripPageState();
}

class _TranskripPageState extends State<TranskripPage> {
  final _service = TranskripService();
  List<TranskripItem>? _list;
  CumlaudeData? _cumlaudeData;
  ProgressKelulusanData? _progressKelulusanData;
  SkpiData? _skpiData;
  bool _loading = true;
  bool _downloading = false;
  String? _downloadPath;
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
      final results = await Future.wait([
        _service.getTranskrip(),
        _service.getCumlaudeEligibility().catchError((_) => null),
        _service.getProgressKelulusan().catchError((_) => null),
        _service.getRingkasanSkpi().catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _list = results[0] as List<TranskripItem>?;
        _cumlaudeData = results[1] as CumlaudeData?;
        _progressKelulusanData = results[2] as ProgressKelulusanData?;
        _skpiData = results[3] as SkpiData?;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final path = await _service.download();
      setState(() => _downloadPath = path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tersimpan di $path', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF501F66),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share() async {
    String? path = _downloadPath;
    if (path == null) {
      await _download();
      path = _downloadPath;
      if (path == null) return;
    }
    final file = XFile(path);
    await SharePlus.instance.share(
      ShareParams(files: [file], text: 'Transkrip Nilai'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: widget.onBack != null ? IconButton(icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)), onPressed: widget.onBack) : null,
        title: const Text('Transkrip Nilai', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_list != null && !_loading) ...[
            IconButton(
              icon: const Icon(CupertinoIcons.scope, color: Color(0xFF501F66)),
              tooltip: 'Simulasi Target IPK',
              onPressed: () => showTargetIpkSimulatorBottomSheet(context),
            ),
            if (_cumlaudeData != null)
              IconButton(
                icon: const Icon(CupertinoIcons.rosette, color: Color(0xFFD89E00)),
                tooltip: 'Evaluasi Cumlaude',
                onPressed: () => showCumlaudeBottomSheet(context, _cumlaudeData!),
              ),
            IconButton(
              icon: const Icon(CupertinoIcons.chart_bar_alt_fill, color: Color(0xFF501F66)),
              tooltip: 'Analitik Tren IPK',
              onPressed: () => showHistoriIpkBottomSheet(context),
            ),
            IconButton(
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF501F66)),
                    )
                  : const Icon(CupertinoIcons.cloud_download, color: Color(0xFF501F66)),
              tooltip: 'Download Transkrip',
              onPressed: _downloading ? null : _download,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.share, color: Color(0xFF501F66)),
              tooltip: 'Bagikan Transkrip',
              onPressed: _downloading ? null : _share,
            ),
          ],
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFCFF), Color(0xFFE3F2FD)], // Pearl White to Ice Blue
          ),
        ),
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: const CircularProgressIndicator(color: Color(0xFFBBDEFB)) // Ice Blue
            .animate()
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, size: 64, color: Colors.redAccent)
                .animate()
                .shake(),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBDEFB),
                foregroundColor: const Color(0xFF501F66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    if (_list == null || _list!.isEmpty) {
      return const Center(child: Text('Tidak ada data transkrip', style: TextStyle(color: Colors.black54)));
    }

    final List<Widget> headerWidgets = [];
    if (_cumlaudeData != null) {
      headerWidgets.add(_buildCumlaudeHeaderCard(_cumlaudeData!));
    }
    if (_progressKelulusanData != null) {
      headerWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ProgressKelulusanCard(data: _progressKelulusanData!),
      ));
    }
    if (_skpiData != null) {
      headerWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: RingkasanSkpiWidget(data: _skpiData!),
      ));
    }

    final totalCount = _list!.length + headerWidgets.length;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF501F66),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 130),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: totalCount,
        itemBuilder: (_, i) {
          if (i < headerWidgets.length) {
            return headerWidgets[i];
          }
          final itemIndex = i - headerWidgets.length;
          return _card(_list![itemIndex], itemIndex);
        },
      ),
    );
  }

  Widget _buildCumlaudeHeaderCard(CumlaudeData cumlaude) {
    final isCumlaude = cumlaude.isCumlaudeEligible;
    final primaryColor = isCumlaude ? const Color(0xFFD89E00) : const Color(0xFF1565C0);
    final cardBgGradient = isCumlaude
        ? const LinearGradient(
            colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardBgGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCumlaude ? CupertinoIcons.rosette : CupertinoIcons.chart_bar_alt_fill,
                color: primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCumlaude ? '🎓 Proyeksi: Cumlaude' : 'Proyeksi: ${cumlaude.predikatSaatIni}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ),
              InkWell(
                onTap: () => showCumlaudeBottomSheet(context, cumlaude),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rincian Syarat',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 2),
                      Icon(CupertinoIcons.chevron_right, color: Colors.white, size: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isCumlaude
                ? 'Seluruh syarat Cumlaude terpenuhi. Pertahankan IPK Anda!'
                : (cumlaude.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount > 0
                    ? 'Terdapat ${cumlaude.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount} matakuliah bernilai < B- yang perlu diperbaiki.'
                    : 'Status predikat kelulusan berdasarkan analisis 4 syarat akademis.'),
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _card(TranskripItem item, int index) {
    Color? nilaiColor;
    switch (item.nilai.toUpperCase()) {
      case 'A':
      case 'A-':
        nilaiColor = Colors.green;
        break;
      case 'B+':
      case 'B':
      case 'B-':
        nilaiColor = Colors.blue;
        break;
      case 'C+':
      case 'C':
        nilaiColor = Colors.orange;
        break;
      case 'D':
      case 'E':
        nilaiColor = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBDEFB).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.kode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF501F66),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.mkl,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip('SKS', item.sks.toString()),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (nilaiColor ?? Colors.grey).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (nilaiColor ?? Colors.grey).withOpacity(0.5), width: 1.5),
                  ),
                  child: Text(
                    item.nilai,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: nilaiColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _infoChip('Bobot', item.bobot.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/khs.dart';
import '../services/khs_service.dart';
import '../widgets/glass_card.dart';

class KhsPage extends StatefulWidget {
  const KhsPage({super.key});

  @override
  State<KhsPage> createState() => _KhsPageState();
}

class _KhsPageState extends State<KhsPage> {
  final _service = KhsService();

  List<KhsOption> _tahunList = [];
  List<KhsOption> _semesterList = [];
  String? _selectedThn;
  String? _selectedSmt;

  KhsDetailResponse? _detail;
  bool _loadingOptions = true;
  bool _loadingDetail = false;
  bool _downloading = false;
  String? _downloadPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    if (!mounted) return;
    setState(() => _loadingOptions = true);
    try {
      final res = await _service.getOptions();
      if (!mounted) return;
      setState(() {
        _tahunList = (res['tahun_akademik'] as List)
            .map((e) => KhsOption.fromJson(e))
            .toList();
        _semesterList = (res['semester'] as List)
            .map((e) => KhsOption.fromJson(e))
            .toList();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _loadDetail() async {
    if (_selectedThn == null || _selectedSmt == null) return;
    if (!mounted) return;
    setState(() {
      _loadingDetail = true;
      _detail = null;
      _downloadPath = null;
    });
    try {
      final res = await _service.getDetail(_selectedThn!, _selectedSmt!);
      if (!mounted) return;
      setState(() {
        _detail = res;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _download() async {
    if (_selectedThn == null || _selectedSmt == null) return;
    setState(() => _downloading = true);
    try {
      final path = await _service.download(_selectedThn!, _selectedSmt!);
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
    if (_selectedThn == null || _selectedSmt == null) return;
    String? path = _downloadPath;
    if (path == null) {
      await _download();
      path = _downloadPath;
      if (path == null) return;
    }
    final file = XFile(path);
    await SharePlus.instance.share(
      ShareParams(files: [file], text: 'KHS $_selectedThn Semester $_selectedSmt'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('KHS (Kartu Hasil Studi)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
    if (_loadingOptions) {
      return Center(
        child: const CircularProgressIndicator(color: Color(0xFFBBDEFB)) // Ice Blue
            .animate()
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
      );
    }
    if (_error != null && _detail == null) {
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
              onPressed: _loadOptions,
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
    return Column(
      children: [
        _buildFilter().animate().slideY(begin: -0.1),
        if (_loadingDetail) 
          Expanded(child: Center(child: const CircularProgressIndicator(color: Color(0xFFBBDEFB)).animate().scale())),
        if (_detail != null && !_loadingDetail) ...[
          _buildStatus().animate().fadeIn(delay: 100.ms),
          Expanded(child: _buildTable()),
        ],
      ],
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: _selectedThn,
                items: _tahunList,
                hint: 'Tahun',
                onChanged: (v) => setState(() => _selectedThn = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _selectedSmt,
                items: _semesterList,
                hint: 'Semester',
                onChanged: (v) => setState(() => _selectedSmt = v),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFBBDEFB).withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: IconButton(
                onPressed: (_selectedThn != null && _selectedSmt != null) ? _loadDetail : null,
                icon: const Icon(CupertinoIcons.search, color: Color(0xFF501F66)),
                tooltip: 'Cari KHS',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<KhsOption> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          isExpanded: true,
          icon: const Icon(CupertinoIcons.chevron_down, color: Color(0xFF501F66), size: 16),
          items: items.map((e) => DropdownMenuItem(
            value: e.value,
            child: Text(e.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_detail!.finishEvaluasi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Evaluasi Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          if (_detail!.canViewSkripsi)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(CupertinoIcons.eye_fill, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('Lihat Skripsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
          const Spacer(),
          if (_detail != null) ...[
            IconButton(
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF501F66)),
                    )
                  : const Icon(CupertinoIcons.cloud_download, color: Color(0xFF501F66)),
              tooltip: 'Download KHS',
              onPressed: _downloading ? null : _download,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.share, color: Color(0xFF501F66)),
              tooltip: 'Bagikan KHS',
              onPressed: _downloading ? null : _share,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    final items = _detail!.data;
    if (items.isEmpty) {
      return const Center(child: Text('Tidak ada data nilai', style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => _khsCard(items[i], i),
    );
  }

  Widget _khsCard(KhsItem item, int index) {
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

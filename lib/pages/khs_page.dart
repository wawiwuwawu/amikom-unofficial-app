import 'package:flutter/material.dart';
import '../models/khs.dart';
import '../services/khs_service.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final res = await _service.getOptions();
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
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _loadDetail() async {
    if (_selectedThn == null || _selectedSmt == null) return;
    setState(() {
      _loadingDetail = true;
      _detail = null;
    });
    try {
      final res = await _service.getDetail(_selectedThn!, _selectedSmt!);
      setState(() {
        _detail = res;
        _error = null;
      });
    } catch (e) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tersimpan di $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KHS')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _detail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOptions,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _buildFilter(),
        if (_loadingDetail) const Expanded(child: Center(child: CircularProgressIndicator())),
        if (_detail != null && !_loadingDetail) ...[
          _buildStatus(),
          Expanded(child: _buildTable()),
        ],
      ],
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedThn,
              decoration: const InputDecoration(
                labelText: 'Tahun',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              items: _tahunList
                  .map((t) => DropdownMenuItem(
                        value: t.value,
                        child: Text(t.label, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedThn = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSmt,
              decoration: const InputDecoration(
                labelText: 'Semester',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              items: _semesterList
                  .map((s) => DropdownMenuItem(
                        value: s.value,
                        child: Text(s.label, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSmt = v),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: (_selectedThn != null && _selectedSmt != null)
                ? _loadDetail
                : null,
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (_detail!.finishEvaluasi)
            Chip(
              avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
              label: const Text('Evaluasi Selesai', style: TextStyle(fontSize: 12)),
            ),
          if (_detail!.canViewSkripsi)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Chip(
                avatar: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                label: const Text('Lihat Skripsi', style: TextStyle(fontSize: 12)),
              ),
            ),
          const Spacer(),
          if (_detail != null)
            IconButton(
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Download KHS',
              onPressed: _downloading ? null : _download,
            ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final items = _detail!.data;
    if (items.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: items.length,
      itemBuilder: (_, i) => _khsCard(items[i]),
    );
  }

  Widget _khsCard(KhsItem item) {
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.kode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.mkl,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip('SKS', item.sks.toString()),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (nilaiColor ?? Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: nilaiColor ?? Colors.grey, width: 1),
                  ),
                  child: Text(
                    item.nilai,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: nilaiColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _infoChip('Bobot', item.bobot.toStringAsFixed(2)),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

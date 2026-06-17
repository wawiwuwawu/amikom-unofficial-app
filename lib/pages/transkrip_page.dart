import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transkrip.dart';
import '../services/transkrip_service.dart';

class TranskripPage extends StatefulWidget {
  const TranskripPage({super.key});

  @override
  State<TranskripPage> createState() => _TranskripPageState();
}

class _TranskripPageState extends State<TranskripPage> {
  final _service = TranskripService();
  List<TranskripItem>? _list;
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
      final data = await _service.getTranskrip();
      if (!mounted) return;
      setState(() {
        _list = data;
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
          SnackBar(content: Text('Tersimpan di $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
      appBar: AppBar(
        title: const Text('Transkrip Nilai'),
        actions: [
          if (_list != null && !_loading) ...[
            IconButton(
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Download Transkrip',
              onPressed: _downloading ? null : _download,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Bagikan Transkrip',
              onPressed: _downloading ? null : _share,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    if (_list == null || _list!.isEmpty) {
      return const Center(child: Text('Tidak ada data transkrip'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _list!.length,
        itemBuilder: (_, i) => _card(_list![i]),
      ),
    );
  }

  Widget _card(TranskripItem item) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (nilaiColor ?? Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: nilaiColor ?? Colors.grey, width: 1),
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

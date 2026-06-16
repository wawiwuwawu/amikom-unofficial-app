import 'package:flutter/material.dart';
import '../models/berita.dart';
import '../services/berita_service.dart';

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
    setState(() => _loading = true);
    try {
      final data = await _service.getBeritaById(widget.id);
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Berita Kampus')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final b = _data!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.gambar.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(b.gambar,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            size: 48, color: Colors.grey),
                      )),
            ),
          if (b.gambar.isNotEmpty) const SizedBox(height: 16),
          Text(b.judul,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${b.author} · ${b.tanggal}',
              style: const TextStyle(color: Colors.grey)),
          const Divider(height: 24),
          Text(b.konten, style: const TextStyle(fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }
}

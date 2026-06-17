import 'package:flutter/material.dart';
import '../models/berita.dart';
import '../services/berita_service.dart';
import 'berita_detail_page.dart';

class BeritaListPage extends StatefulWidget {
  const BeritaListPage({super.key});

  @override
  State<BeritaListPage> createState() => _BeritaListPageState();
}

class _BeritaListPageState extends State<BeritaListPage> {
  final _service = BeritaService();
  final List<Berita> _list = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final offset = (page - 1) * 5;
      final res = await _service.getBerita(offset: offset);
      if (!mounted) return;
      final data = (res['data'] as List)
          .map((e) => Berita.fromJson(e))
          .toList();
      setState(() {
        _list
          ..clear()
          ..addAll(data);
        _hasMore = data.length >= 5;
        _page = page;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Berita Kampus')),
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
            ElevatedButton(
              onPressed: () => _load(1),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_list.isEmpty) {
      return const Center(child: Text('Tidak ada berita'));
    }
    return RefreshIndicator(
      onRefresh: () => _load(1),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _list.length,
              itemBuilder: (_, i) => _beritaCard(_list[i]),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _page > 1 ? () => _load(_page - 1) : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Sebelumnya'),
          ),
          Text(
            'Halaman $_page',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextButton.icon(
            onPressed: _hasMore ? () => _load(_page + 1) : null,
            icon: const SizedBox.shrink(),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selanjutnya'),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _beritaCard(Berita b) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BeritaDetailPage(id: b.id)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b.gambar.isNotEmpty)
              Image.network(
                b.gambar,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (b.excerpt.isNotEmpty)
                      Text(
                        b.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${b.author} · ${b.tanggal}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/panduan.dart';
import '../services/panduan_service.dart';

class PanduanListPage extends StatefulWidget {
  const PanduanListPage({super.key});

  @override
  State<PanduanListPage> createState() => _PanduanListPageState();
}

class _PanduanListPageState extends State<PanduanListPage> {
  final _service = PanduanService();
  final _searchController = TextEditingController();
  List<PanduanItem> _list = [];
  List<PanduanItem> _filteredList = [];
  bool _loading = true;
  String? _error;
  bool _showSearch = false;
  
  String? _downloadingLink;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(_list);
      } else {
        _filteredList = _list.where((item) {
          return item.judul.toLowerCase().contains(query) ||
                 item.tanggal.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getList();
      if (!mounted) return;
      setState(() {
        _list = data;
        _filteredList = List.from(data);
        _error = null;
      });
      _onSearchChanged(); // Re-apply filter if search text exists
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadAndOpen(PanduanItem item) async {
    if (_downloadingLink != null) return; // Prevent multiple downloads at once
    
    setState(() {
      _downloadingLink = item.link;
      _downloadProgress = 0.0;
    });

    try {
      final String filename = item.judul.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
      final savePath = await _service.downloadPanduan(
        item.link,
        filename,
        (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tersimpan di $savePath', style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF501F66),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh: ${e.toString().replaceFirst('Exception: ', '')}', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingLink = null;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16, color: Color(0xFF501F66)),
                decoration: const InputDecoration(
                  hintText: 'Cari panduan...',
                  hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                  border: InputBorder.none,
                ),
              )
            : const Text('Panduan Akademik', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFAFCFF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? CupertinoIcons.xmark : CupertinoIcons.search,
              color: const Color(0xFF501F66),
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFCFF),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: _buildBody(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_list.isEmpty) {
      return const Center(child: Text('Tidak ada panduan akademik', style: TextStyle(color: Colors.black54)));
    }
    if (_filteredList.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ditemukan panduan untuk\n"${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF501F66),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredList.length,
        itemBuilder: (_, i) => _card(_filteredList[i]),
      ),
    );
  }

  Widget _card(PanduanItem item) {
    final bool isDownloading = _downloadingLink == item.link;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isDownloading ? null : () => _downloadAndOpen(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBDEFB).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.book, color: Color(0xFF501F66), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF501F66),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.tanggal,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isDownloading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    strokeWidth: 2.5,
                    color: const Color(0xFF501F66),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF501F66).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.cloud_download, color: Color(0xFF501F66), size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

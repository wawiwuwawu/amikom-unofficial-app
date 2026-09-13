import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/rekognisi.dart';
import '../services/rekognisi_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/rekognisi_form_sheet.dart';

class RekognisiPage extends StatefulWidget {
  final VoidCallback? onBack;

  const RekognisiPage({super.key, this.onBack});

  @override
  State<RekognisiPage> createState() => _RekognisiPageState();
}

class _RekognisiPageState extends State<RekognisiPage> {
  final _service = RekognisiService();
  List<RekognisiItem> _items = [];
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
      final items = await _service.getRekognisi();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm([RekognisiItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RekognisiFormSheet(
        onSuccess: _load,
        itemToEdit: item,
      ),
    );
  }

  Future<void> _deleteItem(RekognisiItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rekognisi'),
        content: Text('Apakah Anda yakin ingin menghapus data rekognisi "${item.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menghapus data...')),
    );

    try {
      await _service.hapusRekognisi(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dihapus')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _downloadFile(RekognisiItem item) async {
    if (item.file.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berkas dokumen tidak tersedia')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh berkas...')),
    );

    try {
      final filename = item.file.isNotEmpty ? item.file : 'rekognisi_${item.id}.pdf';
      final path = await _service.downloadFile(item.id, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berkas tersimpan di $path'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () {
                OpenFilex.open(path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
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
          title: const Text('Rekognisi Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showForm(),
          backgroundColor: const Color(0xFF501F66),
          child: const Icon(CupertinoIcons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.rosette, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data rekognisi mahasiswa',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF501F66),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 130),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final isValid = item.verifikasi == 1 || item.status.toLowerCase() == 'valid';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF501F66),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isValid
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isValid ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Text(
                          isValid ? 'Valid' : 'Belum Verifikasi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isValid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Tingkat: ${item.tingkat}', style: const TextStyle(color: Colors.black87)),
                  Text('Tahun: ${item.tahun}', style: const TextStyle(color: Colors.black87)),
                  if (item.kontribusi.isNotEmpty)
                    Text('Kontribusi: ${item.kontribusi}', style: const TextStyle(color: Colors.black87)),
                  if (item.link.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.tryParse(item.link);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.link, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.link,
                              style: const TextStyle(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.keterangan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Catatan: ${item.keterangan}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isValid) ...[
                        TextButton.icon(
                          onPressed: () => _showForm(item),
                          icon: const Icon(CupertinoIcons.pencil, color: Color(0xFF501F66), size: 18),
                          label: const Text('Edit', style: TextStyle(color: Color(0xFF501F66))),
                        ),
                        TextButton.icon(
                          onPressed: () => _deleteItem(item),
                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 18),
                          label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      if (item.file.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _downloadFile(item),
                          icon: const Icon(CupertinoIcons.cloud_download, color: Color(0xFF501F66), size: 18),
                          label: const Text('Unduh Berkas', style: TextStyle(color: Color(0xFF501F66))),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1, delay: Duration(milliseconds: 50 * index));
        },
      ),
    );
  }
}

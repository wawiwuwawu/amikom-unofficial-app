import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/organisasi.dart';
import '../services/organisasi_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/organisasi_form_sheet.dart';

class OrganisasiPage extends StatefulWidget {
  final VoidCallback onBack;

  const OrganisasiPage({super.key, required this.onBack});

  @override
  State<OrganisasiPage> createState() => _OrganisasiPageState();
}

class _OrganisasiPageState extends State<OrganisasiPage> {
  final _service = OrganisasiService();
  List<OrganisasiItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getOrganisasi();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrganisasiFormSheet(
        onSuccess: _load,
      ),
    );
  }

  Future<void> _deleteItem(OrganisasiItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Apakah Anda yakin ingin menghapus data organisasi "${item.namaOrganisasi}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menghapus data...')),
    );

    try {
      await _service.hapusOrganisasi(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil dihapus')),
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

  Future<void> _downloadFile(OrganisasiItem item) async {
    if (item.fileUrl.isNotEmpty && item.fileUrl.startsWith('http')) {
      final uri = Uri.parse(item.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh file...')),
    );

    try {
      final filename = item.file.isNotEmpty ? item.file : 'organisasi_${item.id}.pdf';
      final path = await _service.downloadFile(item.id, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File tersimpan di $path'),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Organisasi Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
          onPressed: widget.onBack,
        ),
      ),
      body: _buildBody(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: _showForm,
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
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                'Belum ada data organisasi mahasiswa',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
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
                          item.namaOrganisasi,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isValid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
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
                  Text('Jabatan: ${item.jabatan}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  Text('Tahun: ${item.tahun}', style: const TextStyle(color: Colors.black87)),
                  if (item.keterangan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Catatan: ${item.keterangan}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isValid)
                        TextButton.icon(
                          onPressed: () => _deleteItem(item),
                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 18),
                          label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      TextButton.icon(
                        onPressed: () => _downloadFile(item),
                        icon: const Icon(CupertinoIcons.cloud_download, color: Color(0xFF501F66), size: 18),
                        label: const Text('Unduh File', style: TextStyle(color: Color(0xFF501F66))),
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

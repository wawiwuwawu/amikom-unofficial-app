import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/prestasi.dart';
import '../services/prestasi_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/prestasi_form_sheet.dart';

class PrestasiPage extends StatefulWidget {
  final VoidCallback onBack;

  const PrestasiPage({super.key, required this.onBack});

  @override
  State<PrestasiPage> createState() => _PrestasiPageState();
}

class _PrestasiPageState extends State<PrestasiPage> {
  final _service = PrestasiService();
  List<PrestasiItem> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getPrestasi();
      setState(() {
        _list = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _showAddFormSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrestasiFormSheet(
        onSuccess: _loadData,
      ),
    );
  }

  Future<void> _deleteItem(PrestasiItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus prestasi "${item.kejuaraan}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.hapusPrestasi(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prestasi berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadFile(PrestasiItem item) async {
    if (item.fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File sertifikat tidak tersedia')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengunduh file sertifikat...')),
      );

      final filePath = await _service.downloadFile(
        item.id,
        item.file.isNotEmpty ? item.file : 'sertifikat_${item.id}.pdf',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File disimpan di: $filePath'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () async {
              final result = await OpenFilex.open(filePath);
              if (result.type != ResultType.done && item.fileUrl.isNotEmpty) {
                final uri = Uri.parse(item.fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'valid':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        label = 'Valid';
        break;
      case 'ditolak':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        label = 'Ditolak';
        break;
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
          title: const Text('Prestasi Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
            onPressed: widget.onBack,
          ),
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddFormSheet,
          backgroundColor: const Color(0xFF501F66),
          foregroundColor: Colors.white,
          icon: const Icon(CupertinoIcons.add),
          label: const Text('Tambah Prestasi'),
        ),
        body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(CupertinoIcons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _list.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.star_fill, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada data prestasi mahasiswa',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, index) {
                          final item = _list[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                                          item.kejuaraan,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF501F66),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(item.status),
                                    ],
                                  ),
                                  if (item.perolehan.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Perolehan: ${item.perolehan}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (item.tahun.isNotEmpty) ...[
                                        Icon(CupertinoIcons.calendar, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.tahun,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if (item.jenisAktivitas.isNotEmpty) ...[
                                        Icon(CupertinoIcons.tag, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.jenisAktivitas,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (item.keterangan.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      item.keterangan,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (item.status.toLowerCase() != 'valid')
                                        TextButton.icon(
                                          onPressed: () => _deleteItem(item),
                                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 18),
                                          label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                        ),
                                      TextButton.icon(
                                        onPressed: () => _downloadFile(item),
                                        icon: const Icon(CupertinoIcons.cloud_download,
                                            color: Color(0xFF501F66), size: 18),
                                        label: const Text('Unduh File',
                                            style: TextStyle(color: Color(0xFF501F66))),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.1, delay: Duration(milliseconds: 50 * index));
                        },
                      ),
        ),
      ),
    );
  }
}

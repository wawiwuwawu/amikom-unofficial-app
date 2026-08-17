import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/pkl.dart';
import '../services/pkl_service.dart';
import '../widgets/glass_card.dart';

class PklPage extends StatefulWidget {
  final VoidCallback? onBack;

  const PklPage({super.key, this.onBack});

  @override
  State<PklPage> createState() => _PklPageState();
}

class _PklPageState extends State<PklPage> {
  final PklService _service = PklService();

  bool _isLoading = true;
  String _error = '';
  PklData? _data;

  String? _selectedJenis;
  final TextEditingController _judulController = TextEditingController();
  bool _isSubmitting = false;
  final Set<String> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _judulController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getPklData();
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_selectedJenis == null || _selectedJenis!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Jenis Pendaftaran terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Judul Pendaftaran / Laporan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitPkl(_selectedJenis!, _judulController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan Berhasil Ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedJenis = null;
          _judulController.clear();
        });
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _downloadPdf(PklItem item) async {
    setState(() => _downloadingIds.add(item.idPengajuan));
    try {
      final path = await _service.downloadFormulirPkl(item.idPengajuan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formulir PDF disimpan ke: $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(item.idPengajuan));
      }
    }
  }

  Future<void> _showDeleteConfirmation(PklItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pendaftaran PKL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
        content: Text('Apakah Anda yakin ingin menghapus pendaftaran (${item.judul}) ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.deletePkl(item.idPengajuan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Pendaftaran PKL berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFCFF),
        appBar: AppBar(
          title: const Text(
            'PKL & Tugas Mandiri',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF501F66),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF501F66),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(CupertinoIcons.doc_plaintext),
                text: 'Form Pendaftaran',
              ),
              Tab(
                icon: Icon(CupertinoIcons.clock),
                text: 'Riwayat Pendaftaran',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
                          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildFormTab(),
                      _buildRiwayatTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFormTab() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final jenisOptions = data.options.jenis;
    String dynamicLabel = 'Judul Pendaftaran / Kegiatan';
    if (_selectedJenis != null) {
      final selectedOpt = jenisOptions.firstWhere(
        (opt) => opt.value == _selectedJenis,
        orElse: () => PklJenisOption(value: '', label: 'Judul Pendaftaran'),
      );
      if (selectedOpt.label.isNotEmpty) {
        dynamicLabel = selectedOpt.label;
      }
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF501F66),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning Banner jika can_apply == false
          if (!data.canApply)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFD32F2F), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pendaftaran Dibatasi',
                          style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.warningMessage ?? 'Saudara tidak dapat melakukan pengajuan. Anda belum mengajukan KRS Tugas Praktik.',
                          style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn()
          else
            // Form Card
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.doc_append, color: Color(0xFF501F66), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Buat Pendaftaran PKL Baru',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Jenis
                  DropdownButtonFormField<String>(
                    value: _selectedJenis,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Pendaftaran',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.briefcase, color: Color(0xFF501F66)),
                    ),
                    items: jenisOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt.value,
                        child: Text(
                          opt.label,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedJenis = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Textarea Judul
                  TextField(
                    controller: _judulController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: dynamicLabel,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(CupertinoIcons.book, color: Color(0xFF501F66)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF501F66),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 18),
                      label: const Text(
                        'Ajukan Pendaftaran PKL',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          const SizedBox(height: 20),

          // Informasi BAP Card
          if (data.informasi.isNotEmpty)
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF1976D2), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Informasi & Jam Kerja Loket BAP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...data.informasi.map((info) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(info, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildRiwayatTab() {
    final items = _data?.items ?? [];

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchData,
        color: const Color(0xFF501F66),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.doc_text_search, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada riwayat pendaftaran PKL', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF501F66),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          Color badgeBg;
          Color badgeText;
          IconData badgeIcon;

          final rawStatus = item.status.toLowerCase().trim();

          if (rawStatus == 'diajukan') {
            badgeBg = const Color(0xFFFFF3E0);
            badgeText = const Color(0xFFE65100);
            badgeIcon = CupertinoIcons.clock_fill;
          } else if (rawStatus == 'diproses') {
            badgeBg = const Color(0xFFE3F2FD);
            badgeText = const Color(0xFF1565C0);
            badgeIcon = CupertinoIcons.gear_alt_fill;
          } else if (rawStatus == 'diterima' || rawStatus == 'acc') {
            badgeBg = const Color(0xFFE8F5E9);
            badgeText = const Color(0xFF2E7D32);
            badgeIcon = CupertinoIcons.checkmark_seal_fill;
          } else if (rawStatus == 'ditolak') {
            badgeBg = const Color(0xFFFFEBEE);
            badgeText = const Color(0xFFC62828);
            badgeIcon = CupertinoIcons.xmark_octagon_fill;
          } else {
            badgeBg = Colors.grey.shade200;
            badgeText = Colors.black87;
            badgeIcon = CupertinoIcons.info;
          }

          final isDownloading = _downloadingIds.contains(item.idPengajuan);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.judul,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, size: 14, color: badgeText),
                            const SizedBox(width: 4),
                            Text(
                              item.status,
                              style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _buildDetailRow('Jenis:', item.jenis),
                  const SizedBox(height: 4),
                  _buildDetailRow('Tgl Pengajuan:', item.tglPengajuan),
                  if (item.tglUjian != null || item.ruang != null || item.jam != null) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow('Jadwal Ujian:', '${item.tglUjian ?? '-'} (${item.jam ?? '-'}) • Ruang: ${item.ruang ?? '-'}'),
                  ],

                  // Action Buttons Row
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item.canDownload)
                        ElevatedButton.icon(
                          onPressed: isDownloading ? null : () => _downloadPdf(item),
                          icon: isDownloading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(CupertinoIcons.arrow_down_doc_fill, color: Colors.white, size: 15),
                          label: const Text('Download Formulir PDF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      if (item.canDelete) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteConfirmation(item),
                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 16),
                          label: const Text('Hapus / Batal', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (50 * index).ms);
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ],
    );
  }
}

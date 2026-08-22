import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/skmk.dart';
import '../services/skmk_service.dart';
import '../widgets/glass_card.dart';

class SkmkPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SkmkPage({super.key, this.onBack});

  @override
  State<SkmkPage> createState() => _SkmkPageState();
}

class _SkmkPageState extends State<SkmkPage> {
  final SkmkService _service = SkmkService();

  bool _isLoading = true;
  String _error = '';
  SkmkData? _data;

  String? _selectedKeperluan;
  String? _selectedOrtu;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getSkmkData();
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
    if (_selectedKeperluan == null || _selectedOrtu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Keperluan dan Orang Tua terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitSkmk(
        _selectedKeperluan!,
        _selectedOrtu!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan Berhasil Ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedKeperluan = null;
          _selectedOrtu = null;
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

  Future<void> _showDeleteConfirmation(SkmkItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Pengajuan SKMK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF501F66),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengajuan SKMK (${item.keperluan}) ini?',
        ),
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
        final res = await _service.deleteSkmk(item.idPengajuan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Pengajuan Berhasil Dihapus'),
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
            'Surat Masih Kuliah (SKMK)',
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
                text: 'Form Pengajuan',
              ),
              Tab(icon: Icon(CupertinoIcons.clock), text: 'Riwayat Pengajuan'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF501F66)),
              )
            : _error.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_error, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF501F66),
                      ),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            : TabBarView(children: [_buildFormTab(), _buildRiwayatTab()]),
      ),
    );
  }

  Widget _buildFormTab() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final keperluanList = data.options.keperluan;
    final ortuList = data.options.ortu;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF501F66),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Form Card
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      CupertinoIcons.doc_append,
                      color: Color(0xFF501F66),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Buat Pengajuan SKMK Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF501F66),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedKeperluan,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Keperluan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      CupertinoIcons.briefcase,
                      color: Color(0xFF501F66),
                    ),
                  ),
                  items: keperluanList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedKeperluan = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedOrtu,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Orang Tua',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      CupertinoIcons.person_2,
                      color: Color(0xFF501F66),
                    ),
                  ),
                  items: ortuList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedOrtu = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF501F66),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.paperplane_fill,
                            color: Colors.white,
                            size: 18,
                          ),
                    label: const Text(
                      'Ajukan SKMK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          // Information & BAA Contact Card
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      CupertinoIcons.info_circle_fill,
                      color: Color(0xFF1976D2),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Syarat & Catatan Penting',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF501F66),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.persyaratanInfo.isNotEmpty) ...[
                  const Text(
                    'Layanan SKMK TIDAK DIPROSES untuk:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...data.persyaratanInfo.map(
                    (info) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              info,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (data.kontakBaa.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kontak Loket BAA:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.kontakBaa,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                  Icon(
                    CupertinoIcons.doc_text_search,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat pengajuan SKMK',
                    style: TextStyle(color: Colors.black54),
                  ),
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

          switch (item.status.toLowerCase().trim()) {
            case 'diajukan':
              badgeBg = const Color(0xFFFFF3E0);
              badgeText = const Color(0xFFE65100);
              badgeIcon = CupertinoIcons.clock_fill;
              break;
            case 'diproses':
              badgeBg = const Color(0xFFE3F2FD);
              badgeText = const Color(0xFF1565C0);
              badgeIcon = CupertinoIcons.gear_alt_fill;
              break;
            case 'selesai':
              badgeBg = const Color(0xFFE8F5E9);
              badgeText = const Color(0xFF2E7D32);
              badgeIcon = CupertinoIcons.checkmark_seal_fill;
              break;
            case 'ditolak':
              badgeBg = const Color(0xFFFFEBEE);
              badgeText = const Color(0xFFC62828);
              badgeIcon = CupertinoIcons.xmark_octagon_fill;
              break;
            default:
              badgeBg = Colors.grey.shade200;
              badgeText = Colors.black87;
              badgeIcon = CupertinoIcons.info;
          }

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
                          item.keperluan,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF501F66),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
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
                              style: TextStyle(
                                color: badgeText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tgl Pengajuan:', item.tglPengajuan),
                  const SizedBox(height: 4),
                  _buildDetailRow('Semester/TA:', item.thnAjaranSmt),
                  const SizedBox(height: 4),
                  _buildDetailRow('Tgl Proses:', item.tglProses ?? '-'),
                  if (item.keterangan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow('Keterangan:', item.keterangan),
                  ],
                  if (item.canDelete) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteConfirmation(item),
                          icon: const Icon(
                            CupertinoIcons.trash,
                            color: Colors.red,
                            size: 16,
                          ),
                          label: const Text(
                            'Hapus Pengajuan',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

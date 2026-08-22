import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/izin_penelitian.dart';
import '../services/izin_penelitian_service.dart';
import '../widgets/glass_card.dart';

class IzinPenelitianPage extends StatefulWidget {
  final VoidCallback? onBack;

  const IzinPenelitianPage({super.key, this.onBack});

  @override
  State<IzinPenelitianPage> createState() => _IzinPenelitianPageState();
}

class _IzinPenelitianPageState extends State<IzinPenelitianPage> {
  final IzinPenelitianService _service = IzinPenelitianService();

  bool _isLoading = true;
  String _error = '';
  IzinPenelitianData? _data;

  String? _selectedJenis;
  String? _selectedDitujukan;
  final TextEditingController _ditujukanLainnyaController = TextEditingController();
  final TextEditingController _instansiController = TextEditingController();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _topikController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _ditujukanLainnyaController.dispose();
    _instansiController.dispose();
    _judulController.dispose();
    _topikController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getIzinPenelitianData();
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

  String _formatDateApi(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month/$day/${dt.year}';
  }

  String _formatDateDisplay(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedJenis = null;
      _selectedDitujukan = null;
      _ditujukanLainnyaController.clear();
      _instansiController.clear();
      _judulController.clear();
      _topikController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _submitForm() async {
    if (_selectedJenis == null || _selectedDitujukan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi jenis penelitian dan penerima surat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDitujukan == 'Lainnya' && _ditujukanLainnyaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi spesifik penerima surat (Ditujukan Kepada)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_instansiController.text.trim().isEmpty || _judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Instansi Tujuan dan Judul / Mata Kuliah'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedJenis == 'tugas' && _topikController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Topik Tugas / Wawancara'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Tanggal Mulai dan Tanggal Selesai'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final body = {
      'jenis_penelitian': _selectedJenis,
      'ditujukan_penelitian': _selectedDitujukan,
      'ditujukan_penelitian_lainnya': _selectedDitujukan == 'Lainnya' ? _ditujukanLainnyaController.text.trim() : '',
      'instansi': _instansiController.text.trim(),
      'start_date': _formatDateApi(_startDate!),
      'end_date': _formatDateApi(_endDate!),
      'judul_penelitian': _judulController.text.trim(),
      'topik': _selectedJenis == 'tugas' ? _topikController.text.trim() : '',
    };

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitIzinPenelitian(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan Berhasil Ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
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

  Future<void> _showDeleteConfirmation(IzinPenelitianItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengajuan Izin Penelitian', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
        content: Text('Apakah Anda yakin ingin menghapus pengajuan izin penelitian ke ${item.instansi}?'),
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
        final res = await _service.deleteIzinPenelitian(item.idPengajuan);
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
            'Izin Penelitian',
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
              Tab(
                icon: Icon(CupertinoIcons.clock),
                text: 'Riwayat Pengajuan',
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

    final jenisList = data.options.jenisPenelitian;
    final ditujukanList = data.options.ditujukanPenelitian;

    String judulLabel = 'Judul Penelitian';
    if (_selectedJenis == 'tugas') {
      judulLabel = 'Mata Kuliah';
    } else if (_selectedJenis == 'mbkm') {
      judulLabel = 'Program MBKM';
    } else if (_selectedJenis != null) {
      judulLabel = 'Judul Jenis Penelitian';
    }

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
                    Icon(CupertinoIcons.doc_append, color: Color(0xFF501F66), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Buat Pengajuan Izin Penelitian',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dropdown Jenis Penelitian
                DropdownButtonFormField<String>(
                  initialValue: _selectedJenis,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Penelitian',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.square_grid_2x2, color: Color(0xFF501F66)),
                  ),
                  items: jenisList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item.value,
                      child: Text(
                        item.label,
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

                // Dropdown Ditujukan
                DropdownButtonFormField<String>(
                  initialValue: _selectedDitujukan,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ditujukan Kepada',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.person_crop_square, color: Color(0xFF501F66)),
                  ),
                  items: ditujukanList.map((item) {
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
                    setState(() => _selectedDitujukan = val);
                  },
                ),

                // Input Kondisional jika ditujukan == 'Lainnya'
                if (_selectedDitujukan == 'Lainnya') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ditujukanLainnyaController,
                    decoration: const InputDecoration(
                      labelText: 'Ditujukan Kepada (Spesifik)',
                      border: OutlineInputBorder(),
                      hintText: 'Contoh: Koordinator Lapangan / Supervisor',
                      prefixIcon: Icon(CupertinoIcons.person, color: Color(0xFF501F66)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Instansi
                TextField(
                  controller: _instansiController,
                  decoration: const InputDecoration(
                    labelText: 'Instansi / Perusahaan Tujuan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.building_2_fill, color: Color(0xFF501F66)),
                  ),
                ),
                const SizedBox(height: 16),

                // Judul / Matkul / MBKM
                TextField(
                  controller: _judulController,
                  maxLines: _selectedJenis == 'tugas' ? 1 : 2,
                  decoration: InputDecoration(
                    labelText: judulLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(CupertinoIcons.book, color: Color(0xFF501F66)),
                  ),
                ),

                // Input Kondisional Topik jika jenis == 'tugas'
                if (_selectedJenis == 'tugas') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _topikController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Topik Tugas / Wawancara',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.text_quote, color: Color(0xFF501F66)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Date Picker Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Mulai',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(CupertinoIcons.calendar, color: Color(0xFF501F66)),
                          ),
                          child: Text(
                            _startDate != null ? _formatDateDisplay(_startDate!) : 'Pilih Tanggal',
                            style: TextStyle(
                              fontSize: 13,
                              color: _startDate != null ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Selesai',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(CupertinoIcons.calendar, color: Color(0xFF501F66)),
                          ),
                          child: Text(
                            _endDate != null ? _formatDateDisplay(_endDate!) : 'Pilih Tanggal',
                            style: TextStyle(
                              fontSize: 13,
                              color: _endDate != null ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      'Ajukan Izin Penelitian',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          // Keterangan BAA Card
          if (data.keteranganBaa.isNotEmpty)
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF1976D2), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Petunjuk Pengambilan Surat (BAA)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF501F66)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.keteranganBaa,
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                        ),
                      ],
                    ),
                  ),
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
                  Text('Belum ada riwayat pengajuan izin penelitian', style: TextStyle(color: Colors.black54)),
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
                          item.instansi,
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
                  _buildDetailRow('Judul / Kegiatan:', item.judulPenelitian),
                  const SizedBox(height: 4),
                  _buildDetailRow('Tanggal:', '${item.mulai} - ${item.selesai}'),
                  const SizedBox(height: 4),
                  _buildDetailRow('Semester/TA:', item.thnAjaranSmt),
                  const SizedBox(height: 4),
                  _buildDetailRow('Tgl Proses:', item.tglProses ?? 'Proses'),
                  if (item.canDelete) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteConfirmation(item),
                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 16),
                          label: const Text('Hapus Pengajuan', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ],
    );
  }
}

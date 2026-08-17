import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sp.dart';
import '../services/sp_service.dart';
import '../widgets/glass_card.dart';

class SpPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SpPage({super.key, this.onBack});

  @override
  State<SpPage> createState() => _SpPageState();
}

class _SpPageState extends State<SpPage> {
  final SpService _service = SpService();

  bool _isLoadingAvailable = true;
  String _errorAvailable = '';
  SpAvailableData? _availableData;
  final Set<String> _selectedKodes = {};

  bool _isLoadingTaken = true;
  String _errorTaken = '';
  SpTakenData? _takenData;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchAvailable(),
      _fetchTaken(),
    ]);
  }

  Future<void> _fetchAvailable() async {
    setState(() {
      _isLoadingAvailable = true;
      _errorAvailable = '';
    });
    try {
      final data = await _service.getAvailable();
      if (mounted) {
        setState(() {
          _availableData = data;
          _isLoadingAvailable = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorAvailable = e.toString().replaceFirst('Exception: ', '');
          _isLoadingAvailable = false;
        });
      }
    }
  }

  Future<void> _fetchTaken() async {
    setState(() {
      _isLoadingTaken = true;
      _errorTaken = '';
    });
    try {
      final data = await _service.getTaken();
      if (mounted) {
        setState(() {
          _takenData = data;
          _isLoadingTaken = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorTaken = e.toString().replaceFirst('Exception: ', '');
          _isLoadingTaken = false;
        });
      }
    }
  }

  int get _selectedTotalSks {
    if (_availableData == null) return 0;
    int total = 0;
    final allMatkul = [
      ..._availableData!.matkulTahunBerjalan,
      ..._availableData!.matkulTahunLain,
    ];
    for (var m in allMatkul) {
      if (_selectedKodes.contains(m.kode)) {
        total += m.sks;
      }
    }
    return total;
  }

  void _toggleSelection(SpMatkul item) {
    if (item.disabled) return;

    final isCurrentlySelected = _selectedKodes.contains(item.kode);
    if (!isCurrentlySelected) {
      final currentSisa = _availableData?.sisaSks ?? 0;
      if (_selectedTotalSks + item.sks > currentSisa) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total SKS terpilih melebihi sisa kuota ($currentSisa SKS)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() {
        _selectedKodes.add(item.kode);
      });
    } else {
      setState(() {
        _selectedKodes.remove(item.kode);
      });
    }
  }

  Future<void> _showSubmitConfirmation() async {
    if (_selectedKodes.isEmpty || _availableData == null) return;

    final allMatkul = [
      ..._availableData!.matkulTahunBerjalan,
      ..._availableData!.matkulTahunLain,
    ];
    final selectedItems = allMatkul.where((m) => _selectedKodes.contains(m.kode)).toList();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengajuan Semester Pendek', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anda akan mengajukan matakuliah berikut:'),
            const SizedBox(height: 12),
            ...selectedItems.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Color(0xFF501F66)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${m.mkl} (${m.kode}) - ${m.sks} SKS',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 20),
            Text(
              'Total: ${selectedItems.length} Mata Kuliah ($_selectedTotalSks SKS)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
            child: const Text('Ya, Ajukan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      try {
        final res = await _service.submitSp(_selectedKodes.toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Data mata kuliah SP berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          _selectedKodes.clear();
          _loadAllData();
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
  }

  Future<void> _showDeleteConfirmation(SpTakenItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Matakuliah SP', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
        content: Text('Apakah Anda yakin ingin menghapus matakuliah ${item.mkl} (${item.kode})?'),
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
        final res = await _service.deleteSp(item.idKrs);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Data mata kuliah SP berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAllData();
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
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFCFF),
        appBar: AppBar(
          title: const Text(
            'Semester Pendek (SP)',
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
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: Icon(CupertinoIcons.list_bullet),
                text: 'MK Pilihan',
              ),
              Tab(
                icon: Icon(CupertinoIcons.checkmark_seal_fill),
                text: 'MK Dipilih',
              ),
              Tab(
                icon: Icon(CupertinoIcons.calendar),
                text: 'Jadwal SP',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAvailableTab(),
            _buildTakenTab(),
            _buildJadwalTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab() {
    if (_isLoadingAvailable) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    }

    if (_errorAvailable.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorAvailable, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAvailable,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final data = _availableData;
    if (data == null) {
      return const Center(child: Text('Data tidak tersedia'));
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchAvailable,
          color: const Color(0xFF501F66),
          child: ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            children: [
              // Banner Periode Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: data.isOpen ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: data.isOpen ? const Color(0xFF90CAF9) : const Color(0xFFFFCC80),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      data.isOpen ? CupertinoIcons.info_circle_fill : CupertinoIcons.exclamationmark_circle_fill,
                      color: data.isOpen ? const Color(0xFF1976D2) : const Color(0xFFE65100),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.periodeInfo,
                        style: TextStyle(
                          color: data.isOpen ? const Color(0xFF0D47A1) : const Color(0xFFBF360C),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 16),

              // Kuota SKS Card
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuotaInfo('Sisa Kuota', '${data.sisaSks} SKS', Colors.green),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    _buildQuotaInfo('Batas Max', '${data.maxSks} SKS', const Color(0xFF501F66)),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    _buildQuotaInfo('Tahun Ini', '${data.totalSksTahunIni} SKS', Colors.blue),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),

              if (!data.isOpen)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Pendaftaran SP sedang ditutup',
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else ...[
                // Matakuliah Tahun Berjalan
                if (data.matkulTahunBerjalan.isNotEmpty) ...[
                  const Text(
                    'Matakuliah Tahun Berjalan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
                  ),
                  const SizedBox(height: 10),
                  ...data.matkulTahunBerjalan.map((m) => _buildMatkulItemCard(m)),
                  const SizedBox(height: 20),
                ],

                // Matakuliah Tahun Lain / Perbaikan
                if (data.matkulTahunLain.isNotEmpty) ...[
                  const Text(
                    'Matakuliah Perbaikan / Tahun Lain',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
                  ),
                  const SizedBox(height: 10),
                  ...data.matkulTahunLain.map((m) => _buildMatkulItemCard(m)),
                ],

                if (data.matkulTahunBerjalan.isEmpty && data.matkulTahunLain.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Tidak ada matakuliah SP yang tersedia', style: TextStyle(color: Colors.black54)),
                    ),
                  ),
              ],
            ],
          ),
        ),

        // Bottom Action Bar for Submit
        if (data.isOpen && _selectedKodes.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _showSubmitConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF501F66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.paperplane_fill, color: Colors.white),
                label: Text(
                  'Ajuan SP (${_selectedKodes.length} Matkul - $_selectedTotalSks SKS)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ).animate().slideY(begin: 1.0, duration: 300.ms).fadeIn(),
          ),
      ],
    );
  }

  Widget _buildQuotaInfo(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMatkulItemCard(SpMatkul item) {
    final isSelected = _selectedKodes.contains(item.kode);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: item.disabled ? null : () => _toggleSelection(item),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: item.disabled ? null : (_) => _toggleSelection(item),
                activeColor: const Color(0xFF501F66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.mkl,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: item.disabled ? Colors.grey : const Color(0xFF501F66),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Kode: ${item.kode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 12),
                        Text('TA: ${item.thnAjaran} (${item.semester})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF501F66).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.sks} SKS',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
                    ),
                  ),
                  if (item.nilai.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Nilai: ${item.nilai}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTakenTab() {
    if (_isLoadingTaken) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    }

    if (_errorTaken.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorTaken, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTaken,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final data = _takenData;
    if (data == null || data.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchTaken,
        color: const Color(0xFF501F66),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.doc_plaintext, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada matakuliah SP yang diambil', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTaken,
      color: const Color(0xFF501F66),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total SKS Taken Card
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total SKS SP Diambil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF501F66)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF501F66),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.totalSks} SKS',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),

          ...data.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.mkl,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                            ),
                            const SizedBox(height: 4),
                            Text('Kode: ${item.kode} • ${item.sks} SKS', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (item.isActivated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(CupertinoIcons.checkmark_seal_fill, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Teraktivasi', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else if (item.canDelete)
                        IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 20),
                          tooltip: 'Hapus Matakuliah',
                          onPressed: () => _showDeleteConfirmation(item),
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildJadwalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF501F66).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.calendar_today, size: 64, color: Color(0xFF501F66)),
          ).animate().scale(duration: 500.ms),
          const SizedBox(height: 24),
          const Text(
            'Jadwal Perkuliahan SP',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jadwal perkuliahan Semester Pendek akan ditampilkan di sini secara otomatis setelah mata kuliah SP yang Anda ambil teraktivasi oleh Bagian Akademik.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 32),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                Row(
                  children: [
                    Icon(CupertinoIcons.info_circle, color: Color(0xFF501F66), size: 18),
                    SizedBox(width: 8),
                    Text('Catatan Akademik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66))),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Pastikan Anda menyelesaikan pembayaran SP dan memeriksa status "Teraktivasi" pada tab Mata Kuliah Dipilih.',
                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

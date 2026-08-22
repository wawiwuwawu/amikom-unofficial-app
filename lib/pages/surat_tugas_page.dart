import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/surat_tugas.dart';
import '../services/surat_tugas_service.dart';
import '../services/api_client.dart';
import '../widgets/glass_card.dart';

class SuratTugasPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SuratTugasPage({super.key, this.onBack});

  @override
  State<SuratTugasPage> createState() => _SuratTugasPageState();
}

class _SuratTugasPageState extends State<SuratTugasPage> {
  final SuratTugasService _service = SuratTugasService();

  bool _isLoading = true;
  String _error = '';
  SuratTugasData? _data;

  // Form State
  final TextEditingController _namaKegiatanController = TextEditingController();
  final TextEditingController _penyelenggaraController = TextEditingController();
  final TextEditingController _bentukKegiatanController = TextEditingController();
  final TextEditingController _linkKegiatanController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedNikPendamping;
  String _jenisKeg = 'individu'; // 'individu' or 'kelompok'

  // Member Search State
  final TextEditingController _searchMahasiswaController = TextEditingController();
  List<SearchMahasiswaItem> _searchResults = [];
  bool _isSearchingMahasiswa = false;
  Timer? _debounceTimer;
  final List<SearchMahasiswaItem> _selectedMembers = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _namaKegiatanController.dispose();
    _penyelenggaraController.dispose();
    _bentukKegiatanController.dispose();
    _linkKegiatanController.dispose();
    _searchMahasiswaController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getSuratTugasData();
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
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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

  void _onSearchMahasiswaChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearchingMahasiswa = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearchingMahasiswa = true);
      final results = await _service.searchMahasiswa(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchingMahasiswa = false;
        });
      }
    });
  }

  void _addMember(SearchMahasiswaItem item) {
    final currentNim = ApiClient.instance.nim;
    if (currentNim != null && item.npm == currentNim) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak perlu menambahkan NIM sendiri ke dalam anggota'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedMembers.any((m) => m.npm == item.npm)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mahasiswa sudah ada dalam daftar anggota'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedMembers.add(item);
      _searchMahasiswaController.clear();
      _searchResults = [];
    });
  }

  void _removeMember(int index) {
    setState(() {
      _selectedMembers.removeAt(index);
    });
  }

  void _resetForm() {
    setState(() {
      _namaKegiatanController.clear();
      _penyelenggaraController.clear();
      _bentukKegiatanController.clear();
      _linkKegiatanController.clear();
      _startDate = null;
      _endDate = null;
      _selectedNikPendamping = null;
      _jenisKeg = 'individu';
      _selectedMembers.clear();
      _searchMahasiswaController.clear();
      _searchResults.clear();
    });
  }

  Future<void> _submitForm() async {
    if (_namaKegiatanController.text.trim().isEmpty ||
        _penyelenggaraController.text.trim().isEmpty ||
        _bentukKegiatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi Nama Kegiatan, Penyelenggara, dan Bentuk Kegiatan'),
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

    if (_selectedNikPendamping == null || _selectedNikPendamping!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Dosen Pendamping'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final body = <String, dynamic>{
      'nama_kegiatan': _namaKegiatanController.text.trim(),
      'penyelenggara': _penyelenggaraController.text.trim(),
      'tanggal_mulai': _formatDateApi(_startDate!),
      'tanggal_selesai': _formatDateApi(_endDate!),
      'bentuk_kegiatan': _bentukKegiatanController.text.trim(),
      'dosen_pendamping': _selectedNikPendamping,
      'link_kegiatan': _linkKegiatanController.text.trim(),
      'jenis_keg': _jenisKeg,
    };

    if (_jenisKeg == 'kelompok') {
      body['listnpm'] = _selectedMembers.map((m) => m.npm).toList();
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitSuratTugas(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Surat Tugas Berhasil Diajukan'),
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

  Future<void> _showDeleteConfirmation(SuratTugasItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Surat Tugas', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
        content: Text('Apakah Anda yakin ingin menghapus pengajuan surat tugas (${item.namaKegiatan})?'),
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
        final res = await _service.deleteSuratTugas(item.idSurat);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Data surat tugas berhasil dihapus'),
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

  Future<void> _showMembersDialog(SuratTugasItem item) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anggota Kelompok - ${item.namaKegiatan}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66))),
        content: FutureBuilder<List<SuratTugasMember>>(
          future: _service.getMembers(item.idSurat),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF501F66))),
              );
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            }
            final members = snapshot.data ?? [];
            if (members.isEmpty) {
              return const Text('Tidak ada anggota kelompok yang terdaftar.', style: TextStyle(color: Colors.black54));
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: members.map((m) => ListTile(
                  dense: true,
                  leading: const Icon(CupertinoIcons.person_fill, color: Color(0xFF501F66)),
                  title: Text(m.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('NIM: ${m.npm}', style: const TextStyle(fontSize: 12)),
                )).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF501F66))),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditModal(SuratTugasItem item) async {
    final namaKegController = TextEditingController(text: item.namaKegiatan);
    final penyelenggaraEditController = TextEditingController(text: item.penyelenggara);
    final bentukEditController = TextEditingController(text: item.bentukKegiatan);
    final linkEditController = TextEditingController(text: item.linkKegiatan);

    DateTime? editStartDate = DateTime.tryParse(item.tglMulai);
    DateTime? editEndDate = DateTime.tryParse(item.tglSelesai);
    String? editNikPendamping = item.nikPendamping.isNotEmpty ? item.nikPendamping : null;
    String editPendampingNama = item.pendamping;

    bool isUpdating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          final dosenOptions = _data?.options.dosenPendamping ?? [];

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Surat Tugas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: namaKegController,
                    decoration: const InputDecoration(labelText: 'Nama Kegiatan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: penyelenggaraEditController,
                    decoration: const InputDecoration(labelText: 'Penyelenggara', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bentukEditController,
                    decoration: const InputDecoration(labelText: 'Bentuk Kegiatan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkEditController,
                    decoration: const InputDecoration(labelText: 'Link Kegiatan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: editNikPendamping,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Dosen Pendamping', border: OutlineInputBorder()),
                    items: dosenOptions.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.nik,
                        child: Text(
                          d.nama,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateModal(() {
                        editNikPendamping = val;
                        final found = dosenOptions.firstWhere((element) => element.nik == val, orElse: () => DosenPendampingOption(nik: val ?? '', nama: ''));
                        editPendampingNama = found.nama;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setStateModal(() => editStartDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Tanggal Mulai', border: OutlineInputBorder()),
                            child: Text(editStartDate != null ? _formatDateDisplay(editStartDate!) : 'Pilih Tanggal', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editEndDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setStateModal(() => editEndDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Tanggal Selesai', border: OutlineInputBorder()),
                            child: Text(editEndDate != null ? _formatDateDisplay(editEndDate!) : 'Pilih Tanggal', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isUpdating
                          ? null
                          : () async {
                              if (namaKegController.text.trim().isEmpty ||
                                  penyelenggaraEditController.text.trim().isEmpty ||
                                  editStartDate == null ||
                                  editEndDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Harap lengkapi semua field edit')),
                                );
                                return;
                              }

                              final updateBody = {
                                'nama_keg': namaKegController.text.trim(),
                                'penyelenggara': penyelenggaraEditController.text.trim(),
                                'tgl_mulai': _formatDateApi(editStartDate!),
                                'tgl_selesai': _formatDateApi(editEndDate!),
                                'bentuk_keg': bentukEditController.text.trim(),
                                'nik_pendamping': editNikPendamping ?? '',
                                'pendamping': editPendampingNama.isNotEmpty ? editPendampingNama : (editNikPendamping ?? ''),
                                'link_kegiatan': linkEditController.text.trim(),
                              };

                              setStateModal(() => isUpdating = true);
                              try {
                                final res = await _service.updateSuratTugas(item.idSurat, updateBody);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? 'Surat Tugas Berhasil Diperbarui'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _fetchData();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setStateModal(() => isUpdating = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
                      child: isUpdating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link kegiatan')),
        );
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
            'Surat Tugas',
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
                text: 'Riwayat Surat Tugas',
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

    final dosenList = data.options.dosenPendamping;

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
                      'Buat Pengajuan Surat Tugas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nama Kegiatan
                TextField(
                  controller: _namaKegiatanController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kegiatan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.star_fill, color: Color(0xFF501F66)),
                  ),
                ),
                const SizedBox(height: 16),

                // Penyelenggara
                TextField(
                  controller: _penyelenggaraController,
                  decoration: const InputDecoration(
                    labelText: 'Penyelenggara',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.building_2_fill, color: Color(0xFF501F66)),
                  ),
                ),
                const SizedBox(height: 16),

                // Bentuk Kegiatan
                TextField(
                  controller: _bentukKegiatanController,
                  decoration: const InputDecoration(
                    labelText: 'Bentuk Kegiatan (Contoh: Perlombaan / Seminar)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.tag, color: Color(0xFF501F66)),
                  ),
                ),
                const SizedBox(height: 16),

                // Link Kegiatan
                TextField(
                  controller: _linkKegiatanController,
                  decoration: const InputDecoration(
                    labelText: 'Link Website / Brosur Kegiatan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.link, color: Color(0xFF501F66)),
                  ),
                ),
                const SizedBox(height: 16),

                // Dropdown Dosen Pendamping
                DropdownButtonFormField<String>(
                  initialValue: _selectedNikPendamping,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Dosen Pendamping',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.person_crop_circle_fill_badge_checkmark, color: Color(0xFF501F66)),
                  ),
                  items: dosenList.map((d) {
                    return DropdownMenuItem<String>(
                      value: d.nik,
                      child: Text(
                        d.nama,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedNikPendamping = val);
                  },
                ),
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
                const SizedBox(height: 16),

                // Choice Jenis Kegiatan (Individu vs Kelompok)
                const Text('Jenis Kegiatan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_fill, size: 16),
                            SizedBox(width: 6),
                            Text('Individu'),
                          ],
                        ),
                        selected: _jenisKeg == 'individu',
                        selectedColor: const Color(0xFF501F66),
                        labelStyle: TextStyle(
                          color: _jenisKeg == 'individu' ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _jenisKeg = 'individu');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_3_fill, size: 16),
                            SizedBox(width: 6),
                            Text('Kelompok'),
                          ],
                        ),
                        selected: _jenisKeg == 'kelompok',
                        selectedColor: const Color(0xFF501F66),
                        labelStyle: TextStyle(
                          color: _jenisKeg == 'kelompok' ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _jenisKeg = 'kelompok');
                        },
                      ),
                    ),
                  ],
                ),

                // Search & Add Members if Kelompok
                if (_jenisKeg == 'kelompok') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Anggota Kelompok:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66))),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _searchMahasiswaController,
                    onChanged: _onSearchMahasiswaChanged,
                    decoration: InputDecoration(
                      labelText: 'Cari Anggota (Ketik NIM / Nama)',
                      hintText: 'Contoh: 23SA',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF501F66)),
                      suffixIcon: _isSearchingMahasiswa
                          ? const UnconstrainedBox(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF501F66)),
                              ),
                            )
                          : null,
                    ),
                  ),

                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, idx) {
                          final res = _searchResults[idx];
                          return ListTile(
                            dense: true,
                            title: Text(res.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('NIM: ${res.npm}', style: const TextStyle(fontSize: 11)),
                            trailing: const Icon(CupertinoIcons.add_circled_solid, color: Color(0xFF501F66)),
                            onTap: () => _addMember(res),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  if (_selectedMembers.isEmpty)
                    const Text('Belum ada anggota kelompok ditambahkan.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: List.generate(_selectedMembers.length, (idx) {
                        final m = _selectedMembers[idx];
                        return Chip(
                          avatar: const Icon(CupertinoIcons.person_fill, size: 14, color: Color(0xFF501F66)),
                          label: Text('${m.npm} - ${m.nama}', style: const TextStyle(fontSize: 11)),
                          deleteIcon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: Colors.red),
                          onDeleted: () => _removeMember(idx),
                          backgroundColor: const Color(0xFF501F66).withValues(alpha: 0.1),
                        );
                      }),
                    ),
                ],

                const SizedBox(height: 24),

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
                      'Ajukan Surat Tugas',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF1976D2), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Petunjuk & Catatan BAA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...data.keteranganBaa.map((info) => Padding(
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
                  Text('Belum ada riwayat pengajuan surat tugas', style: TextStyle(color: Colors.black54)),
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

          final bool isDiterima = rawStatus == 'diterima' || rawStatus == 'acc';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                          item.namaKegiatan,
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

                  _buildDetailRow('Penyelenggara:', item.penyelenggara),
                  const SizedBox(height: 4),
                  _buildDetailRow('Bentuk Kegiatan:', item.bentukKegiatan),
                  const SizedBox(height: 4),
                  _buildDetailRow('Tanggal:', '${item.tglMulai} s/d ${item.tglSelesai}'),
                  const SizedBox(height: 4),
                  _buildDetailRow('Jenis:', item.jenisKegiatan.toUpperCase()),
                  if (item.pendamping.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow('Pendamping:', item.pendamping),
                  ],
                  if (item.linkKegiatan.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _openLink(item.linkKegiatan),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.link, size: 14, color: Color(0xFF1565C0)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.linkKegiatan,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0), decoration: TextDecoration.underline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Komentar Admin
                  if (item.komentar != null && item.komentar!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(CupertinoIcons.chat_bubble_text_fill, color: Color(0xFFF57F17), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Komentar Admin: ${item.komentar}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFF57F17), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Petunjuk Penyerahan jika Status Diterima
                  if (isDiterima) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF2E7D32), size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pengajuan telah disetujui. Silakan mengambil cetakan Surat Tugas di Loket BAA Kampus pada jam kerja.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Buttons Row
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item.jenisKegiatan.toLowerCase() == 'kelompok')
                        OutlinedButton.icon(
                          onPressed: () => _showMembersDialog(item),
                          icon: const Icon(CupertinoIcons.person_3, color: Color(0xFF501F66), size: 16),
                          label: const Text('Lihat Anggota', style: TextStyle(color: Color(0xFF501F66), fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF501F66)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      if (item.canEdit) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showEditModal(item),
                          icon: const Icon(CupertinoIcons.pencil, color: Colors.blue, size: 16),
                          label: const Text('Edit', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                      if (item.canDelete) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteConfirmation(item),
                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 16),
                          label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/surat_tugas.dart';
import '../services/api_client.dart';
import '../services/surat_tugas_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman Surat Tugas — pengajuan baru & riwayat pengajuan.
///
/// Pola tampilan (design system [AppScaffold] / [AppListGroup]):
///   1. TabBar bertema global di bawah AppBar (Form Pengajuan · Riwayat);
///   2. form pengajuan memakai satu [AppSurface]; seluruh input mengandalkan
///      `inputDecorationTheme` global (tanpa border/warna hardcode);
///   3. riwayat = SATU [AppListGroup]: tiap pengajuan satu [AppListRow]
///      (nama kegiatan · tanggal & bentuk kegiatan · [AppPill] status) yang
///      dapat dibuka untuk rincian [AppKeyValue], komentar admin, petunjuk
///      penyerahan, dan aksi (lihat anggota / edit / hapus);
///   4. petunjuk BAA ditampilkan sebagai [AppSurface] sorotan.
///
class SuratTugasPage extends StatefulWidget {

  const SuratTugasPage({super.key});

  @override
  State<SuratTugasPage> createState() => _SuratTugasPageState();
}

class _SuratTugasPageState extends State<SuratTugasPage> {
  final SuratTugasService _service = SuratTugasService();

  bool _isLoading = true;
  String _error = '';
  SuratTugasData? _data;

  /// Id surat yang rinciannya sedang dibuka (murni state tampilan).
  final Set<String> _expandedIds = <String>{};

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
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedMembers.any((m) => m.npm == item.npm)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mahasiswa sudah ada dalam daftar anggota'),
          backgroundColor: AppColors.warning,
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
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Tanggal Mulai dan Tanggal Selesai'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedNikPendamping == null || _selectedNikPendamping!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Dosen Pendamping'),
          backgroundColor: AppColors.warning,
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
            backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.danger,
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
        title: const Text('Hapus Surat Tugas'),
        content: Text('Apakah Anda yakin ingin menghapus pengajuan surat tugas (${item.namaKegiatan})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
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
              backgroundColor: AppColors.success,
            ),
          );
          _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.danger,
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
        title: Text('Anggota Kelompok - ${item.namaKegiatan}'),
        content: FutureBuilder<List<SuratTugasMember>>(
          future: _service.getMembers(item.idSurat),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: AppLoading());
            }
            if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: AppText.bodySm.copyWith(color: AppColors.danger),
              );
            }
            final members = snapshot.data ?? [];
            if (members.isEmpty) {
              return Text(
                'Tidak ada anggota kelompok yang terdaftar.',
                style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
              );
            }
            return SingleChildScrollView(
              child: AppListGroup.from([
                for (final m in members)
                  AppListRow(
                    leading: const Icon(
                      CupertinoIcons.person_fill,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: m.nama,
                    subtitle: 'NIM: ${m.npm}',
                  ),
              ]),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          final dosenOptions = _data?.options.dosenPendamping ?? [];

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('Edit Surat Tugas', style: AppText.h2),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        color: AppColors.textMuted,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: namaKegController,
                    decoration: const InputDecoration(labelText: 'Nama Kegiatan'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: penyelenggaraEditController,
                    decoration: const InputDecoration(labelText: 'Penyelenggara'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: bentukEditController,
                    decoration: const InputDecoration(labelText: 'Bentuk Kegiatan'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: linkEditController,
                    decoration: const InputDecoration(labelText: 'Link Kegiatan'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: editNikPendamping,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Dosen Pendamping'),
                    items: dosenOptions.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.nik,
                        child: Text(
                          d.nama,
                          style: AppText.bodySm,
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
                  const SizedBox(height: AppSpacing.md),
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
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Tanggal Mulai'),
                            child: Text(
                              editStartDate != null ? _formatDateDisplay(editStartDate!) : 'Pilih Tanggal',
                              style: AppText.bodySm.copyWith(
                                color: editStartDate != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Tanggal Selesai'),
                            child: Text(
                              editEndDate != null ? _formatDateDisplay(editEndDate!) : 'Pilih Tanggal',
                              style: AppText.bodySm.copyWith(
                                color: editEndDate != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
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
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  _fetchData();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setStateModal(() => isUpdating = false);
                              }
                            },
                      child: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Simpan Perubahan'),
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
      child: AppScaffold(
        title: 'Surat Tugas',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            const TabBar(
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
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const AppLoading(message: 'Memuat data surat tugas…');

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: _error, onRetry: _fetchData),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const AppEmptyState(
        title: 'Belum ada data surat tugas',
        icon: CupertinoIcons.doc_text_search,
      );
    }

    return TabBarView(
      children: [
        _buildFormTab(data),
        _buildRiwayatTab(data),
      ],
    );
  }

  // ── Tab 1: form pengajuan ──────────────────────────────────────────────────

  Widget _buildFormTab(SuratTugasData data) {
    final dosenList = data.options.dosenPendamping;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColors.primary,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.doc_append,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Buat Pengajuan Surat Tugas', style: AppText.h2),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Nama Kegiatan
                TextField(
                  controller: _namaKegiatanController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kegiatan',
                    prefixIcon: Icon(CupertinoIcons.star_fill),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Penyelenggara
                TextField(
                  controller: _penyelenggaraController,
                  decoration: const InputDecoration(
                    labelText: 'Penyelenggara',
                    prefixIcon: Icon(CupertinoIcons.building_2_fill),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bentuk Kegiatan
                TextField(
                  controller: _bentukKegiatanController,
                  decoration: const InputDecoration(
                    labelText: 'Bentuk Kegiatan (Contoh: Perlombaan / Seminar)',
                    prefixIcon: Icon(CupertinoIcons.tag),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Link Kegiatan
                TextField(
                  controller: _linkKegiatanController,
                  decoration: const InputDecoration(
                    labelText: 'Link Website / Brosur Kegiatan',
                    prefixIcon: Icon(CupertinoIcons.link),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Dropdown Dosen Pendamping
                DropdownButtonFormField<String>(
                  initialValue: _selectedNikPendamping,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Dosen Pendamping',
                    prefixIcon: Icon(CupertinoIcons.person_crop_circle_fill_badge_checkmark),
                  ),
                  items: dosenList.map((d) {
                    return DropdownMenuItem<String>(
                      value: d.nik,
                      child: Text(
                        d.nama,
                        style: AppText.bodySm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedNikPendamping = val);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date Picker Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'Tanggal Mulai',
                        value: _startDate,
                        onTap: _selectStartDate,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildDateField(
                        label: 'Tanggal Selesai',
                        value: _endDate,
                        onTap: _selectEndDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Choice Jenis Kegiatan (Individu vs Kelompok)
                Text('Jenis Kegiatan:', style: AppText.h3),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_fill, size: 16),
                            SizedBox(width: AppSpacing.sm),
                            Text('Individu'),
                          ],
                        ),
                        selected: _jenisKeg == 'individu',
                        selectedColor: AppColors.primary,
                        labelStyle: AppText.button.copyWith(
                          color: _jenisKeg == 'individu'
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _jenisKeg = 'individu');
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_3_fill, size: 16),
                            SizedBox(width: AppSpacing.sm),
                            Text('Kelompok'),
                          ],
                        ),
                        selected: _jenisKeg == 'kelompok',
                        selectedColor: AppColors.primary,
                        labelStyle: AppText.button.copyWith(
                          color: _jenisKeg == 'kelompok'
                              ? Colors.white
                              : AppColors.textSecondary,
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
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Anggota Kelompok:', style: AppText.h3),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _searchMahasiswaController,
                    onChanged: _onSearchMahasiswaChanged,
                    decoration: InputDecoration(
                      labelText: 'Cari Anggota (Ketik NIM / Nama)',
                      hintText: 'Contoh: 23SA',
                      prefixIcon: const Icon(CupertinoIcons.search),
                      suffixIcon: _isSearchingMahasiswa
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: AppListGroup.from([
                          for (final res in _searchResults)
                            AppListRow(
                              leading: const Icon(
                                CupertinoIcons.person_crop_circle,
                                size: 20,
                                color: AppColors.primarySoft,
                              ),
                              title: res.nama,
                              subtitle: 'NIM: ${res.npm}',
                              trailing: const Icon(
                                CupertinoIcons.add_circled_solid,
                                color: AppColors.primary,
                              ),
                              onTap: () => _addMember(res),
                            ),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (_selectedMembers.isEmpty)
                    Text(
                      'Belum ada anggota kelompok ditambahkan.',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: List.generate(_selectedMembers.length, (idx) {
                        final m = _selectedMembers[idx];
                        return Chip(
                          avatar: const Icon(
                            CupertinoIcons.person_fill,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          label: Text('${m.npm} - ${m.nama}', style: AppText.label),
                          deleteIcon: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 16,
                            color: AppColors.danger,
                          ),
                          onDeleted: () => _removeMember(idx),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        );
                      }),
                    ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(CupertinoIcons.paperplane_fill, size: 18),
                    label: const Text('Ajukan Surat Tugas'),
                  ),
                ),
              ],
            ),
          ),
          if (data.keteranganBaa.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              variant: AppSurfaceVariant.hero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.info_circle_fill,
                        size: 20,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('Petunjuk & Catatan BAA', style: AppText.h2),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final info in data.keteranganBaa)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: AppText.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(child: Text(info, style: AppText.bodySm)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kolom tanggal bergaya input global (label + ikon kalender).
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(CupertinoIcons.calendar),
        ),
        child: Text(
          value != null ? _formatDateDisplay(value) : 'Pilih Tanggal',
          style: AppText.bodySm.copyWith(
            color: value != null ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ── Tab 2: riwayat pengajuan ───────────────────────────────────────────────

  Widget _buildRiwayatTab(SuratTugasData data) {
    final items = data.items;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: ListView(
          padding: AppSpacing.page,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            AppEmptyState(
              title: 'Belum ada riwayat pengajuan surat tugas',
              icon: CupertinoIcons.doc_text_search,
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (i > 0) {
        rows.add(const Divider(height: 1, thickness: 1, color: AppColors.border));
      }
      rows.add(_buildRiwayatRow(item));
      if (_expandedIds.contains(item.idSurat)) {
        rows.add(_buildRiwayatDetail(item));
      }
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColors.primary,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppListGroup(children: rows),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  /// Satu baris riwayat: kegiatan · tanggal & bentuk · status.
  Widget _buildRiwayatRow(SuratTugasItem item) {
    final rawStatus = item.status.toLowerCase().trim();
    final tone = _statusTone(rawStatus);
    final (bg, fg) = _statusColors(tone);
    final expanded = _expandedIds.contains(item.idSurat);

    return AppListRow(
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(_statusIcon(rawStatus), size: 18, color: fg),
      ),
      title: item.namaKegiatan,
      subtitle: '${item.tglMulai} s/d ${item.tglSelesai} · ${item.bentukKegiatan}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill(item.status, tone: tone),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
      onTap: () {
        setState(() {
          if (expanded) {
            _expandedIds.remove(item.idSurat);
          } else {
            _expandedIds.add(item.idSurat);
          }
        });
      },
    );
  }

  /// Rincian surat — pasangan label:nilai, catatan admin, dan aksi.
  Widget _buildRiwayatDetail(SuratTugasItem item) {
    final rawStatus = item.status.toLowerCase().trim();
    final isDiterima = rawStatus == 'diterima' || rawStatus == 'acc';
    final komentar = item.komentar;

    return Container(
      width: double.infinity,
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppKeyValue(label: 'Penyelenggara:', value: item.penyelenggara),
          AppKeyValue(label: 'Bentuk Kegiatan:', value: item.bentukKegiatan),
          AppKeyValue(
            label: 'Tanggal:',
            value: '${item.tglMulai} s/d ${item.tglSelesai}',
          ),
          AppKeyValue(label: 'Jenis:', value: item.jenisKegiatan.toUpperCase()),
          if (item.pendamping.isNotEmpty)
            AppKeyValue(label: 'Pendamping:', value: item.pendamping),
          if (item.linkKegiatan.isNotEmpty) _buildLinkRow(item.linkKegiatan),

          // Komentar Admin
          if (komentar != null && komentar.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              variant: AppSurfaceVariant.warning,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.chat_bubble_text_fill,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Komentar Admin: $komentar',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Petunjuk Penyerahan jika Status Diterima
          if (isDiterima) ...[
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              variant: AppSurfaceVariant.success,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Pengajuan telah disetujui. Silakan mengambil cetakan Surat Tugas di Loket BAA Kampus pada jam kerja.',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons Row
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (item.jenisKegiatan.toLowerCase() == 'kelompok')
                OutlinedButton.icon(
                  onPressed: () => _showMembersDialog(item),
                  icon: const Icon(CupertinoIcons.person_3, size: 16),
                  label: const Text('Lihat Anggota'),
                ),
              if (item.canEdit)
                OutlinedButton.icon(
                  onPressed: () => _showEditModal(item),
                  icon: const Icon(CupertinoIcons.pencil, size: 16),
                  label: const Text('Edit'),
                ),
              if (item.canDelete)
                OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(CupertinoIcons.trash, size: 16),
                  label: const Text('Hapus'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Link kegiatan — tetap bisa dibuka seperti sebelumnya.
  Widget _buildLinkRow(String url) {
    return InkWell(
      onTap: () => _openLink(url),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            const Icon(CupertinoIcons.link, size: 14, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                url,
                style: AppText.bodySm.copyWith(
                  color: AppColors.info,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppPillTone _statusTone(String rawStatus) {
    if (rawStatus == 'diajukan') return AppPillTone.warning;
    if (rawStatus == 'diproses') return AppPillTone.info;
    if (rawStatus == 'diterima' || rawStatus == 'acc') return AppPillTone.success;
    if (rawStatus == 'ditolak') return AppPillTone.danger;
    return AppPillTone.neutral;
  }

  IconData _statusIcon(String rawStatus) {
    if (rawStatus == 'diajukan') return CupertinoIcons.clock_fill;
    if (rawStatus == 'diproses') return CupertinoIcons.gear_alt_fill;
    if (rawStatus == 'diterima' || rawStatus == 'acc') {
      return CupertinoIcons.checkmark_seal_fill;
    }
    if (rawStatus == 'ditolak') return CupertinoIcons.xmark_octagon_fill;
    return CupertinoIcons.info;
  }

  /// (background, foreground) mengikuti token status di design system.
  (Color, Color) _statusColors(AppPillTone tone) {
    return switch (tone) {
      AppPillTone.success => (AppColors.successBg, AppColors.success),
      AppPillTone.warning => (AppColors.warningBg, AppColors.warning),
      AppPillTone.danger => (AppColors.dangerBg, AppColors.danger),
      AppPillTone.info => (AppColors.infoBg, AppColors.info),
      AppPillTone.neutral => (AppColors.surfaceMuted, AppColors.textMuted),
    };
  }
}

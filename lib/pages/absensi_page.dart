import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/absensi.dart';
import '../services/absensi_service.dart';
import '../widgets/glass_card.dart';
import 'absensi_detail_page.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  final _service = AbsensiService();

  List<MakulBelumValidasi> _belumValidasi = [];
  bool _loadingBelumValidasi = true;

  List<OptionItem> _semesterList = [];
  List<OptionItem> _matkulList = [];
  String? _selectedThn;
  String? _selectedSmt;
  String? _selectedMakul;
  bool _loadingSemester = false;
  bool _loadingMatkul = false;

  AbsensiMahasiswa? _mahasiswa;
  bool _loadingMahasiswa = false;

  String? _errorFilter;
  bool _validatingAll = false;

  @override
  void initState() {
    super.initState();
    _initAcademicYear();
    _loadBelumValidasi();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSemesterList());
  }

  void _initAcademicYear() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    if (month >= 8) {
      _selectedThn = '$year/${year + 1}';
    } else {
      _selectedThn = '${year - 1}/$year';
    }
  }

  Future<void> _loadBelumValidasi() async {
    if (!mounted) return;
    setState(() => _loadingBelumValidasi = true);
    try {
      final data = await _service.getMakulBelumValidasi();
      if (!mounted) return;
      setState(() {
        _belumValidasi = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingBelumValidasi = false);
    }
  }



  Future<void> _loadSemesterList() async {
    if (_selectedThn == null || _selectedThn!.isEmpty) return;
    setState(() {
      _loadingSemester = true;
      _selectedSmt = null;
      _matkulList = [];
      _selectedMakul = null;
      _mahasiswa = null;
    });
    try {
      final data = await _service.getSemester(_selectedThn!);
      if (!mounted) return;
      setState(() {
        _semesterList = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingSemester = false);
    }
  }

  Future<void> _loadMatkulList() async {
    if (_selectedThn == null || _selectedSmt == null) return;
    setState(() {
      _loadingMatkul = true;
      _selectedMakul = null;
      _mahasiswa = null;
    });
    try {
      final data = await _service.getMatkul(_selectedThn!, _selectedSmt!);
      if (!mounted) return;
      setState(() {
        _matkulList = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMatkul = false);
    }
  }

  Future<void> _loadMahasiswa() async {
    if (_selectedThn == null || _selectedSmt == null || _selectedMakul == null) return;
    if (!mounted) return;
    setState(() => _loadingMahasiswa = true);
    try {
      final data = await _service.getMahasiswa(_selectedThn!, _selectedSmt!, _selectedMakul!);
      if (!mounted) return;
      setState(() {
        _mahasiswa = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMahasiswa = false);
    }
  }

  Future<void> _validasiSemua(MakulBelumValidasi item) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Validasi Semua'),
        content: Text('Validasi ${item.count} pertemuan "${item.makul}" dengan nilai default?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Validasi')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _validatingAll = true);
    int success = 0;
    int failed = 0;

    for (final idPresensi in item.idPresensiMhs) {
      try {
        final detail = await _service.getPresensiDetail(idPresensi);
        await _service.validasi({
          'jenispilih': detail.keterangan == 'H' ? 'teori' : detail.keterangan,
          'idpresensimhstexs': detail.idPresensiMhs,
          'idpresensidosen': detail.idPresensiDosen,
          'kuliahteori': detail.kuliahTpId,
          'kesesuaian_perkuliahan': '1',
          'kesesuaian_materi': '1',
          'penilaianmhs': '4',
          'kritiksaran': '',
          'asdos_npms': [],
          'asdospenilaian': {
            for (final k in detail.kriterias)
              if (k.nilai.isNotEmpty)
                k.id: k.nilai.reduce((a, b) => a.nilai >= b.nilai ? a : b).id
          },
        });
        success++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validasi: $success berhasil, $failed gagal', style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF501F66),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _loadBelumValidasi();
    setState(() => _validatingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit gradient from MainPage
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Absensi Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadBelumValidasi();
            if (_selectedThn != null && _selectedSmt != null && _selectedMakul != null) {
              await _loadMahasiswa();
            }
          },
          color: const Color(0xFF501F66),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding for dock
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBelumValidasi().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),
                _buildFilter().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                if (_errorFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: GlassCard(
                      child: Column(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          Text(_errorFilter!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                          TextButton(onPressed: _loadBelumValidasi, child: const Text('Coba Lagi')),
                        ],
                      ),
                    ),
                  ).animate().shake(),
                if (_loadingMahasiswa)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFBBDEFB))),
                  ),
                if (_mahasiswa != null && !_loadingMahasiswa)
                  _buildHasil().animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBelumValidasi() {
    if (_loadingBelumValidasi) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFBBDEFB)));
    }
    if (_belumValidasi.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text('Perlu Validasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66))),
            const Spacer(),
            if (_validatingAll)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        ..._belumValidasi.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildBelumValidasiCard(item),
        )),
      ],
    );
  }

  Widget _buildBelumValidasiCard(MakulBelumValidasi item) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      gradient: LinearGradient(
        colors: [Colors.orange.shade50.withOpacity(0.7), Colors.white.withOpacity(0.5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
            child: Center(child: Text('${item.count}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 16))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.makul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(item.kelasgab.isNotEmpty ? item.kelasgab[0] : item.kode, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _validatingAll ? null : () => _validasiSemua(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade100,
              foregroundColor: Colors.deepOrange,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Validasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Presensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGlassDropdown(
                  value: _selectedThn,
                  items: [if (_selectedThn != null) OptionItem(value: _selectedThn!, label: _selectedThn!)], 
                  hint: 'Tahun Akademik',
                  onChanged: null, // Readonly representation
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFBBDEFB).withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF501F66)),
                  tooltip: 'Muat ulang semester',
                  onPressed: () {
                    _initAcademicYear();
                    _loadSemesterList();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingSemester)
            const Center(child: CircularProgressIndicator(color: Color(0xFFBBDEFB)))
          else
            _buildGlassDropdown(
              value: _semesterList.isNotEmpty ? _selectedSmt : null,
              items: _semesterList,
              hint: 'Semester',
              onChanged: _selectedThn != null && _selectedThn!.isNotEmpty
                  ? (v) {
                      setState(() {
                        _selectedSmt = v;
                        _matkulList = [];
                        _selectedMakul = null;
                        _mahasiswa = null;
                      });
                      if (v != null) _loadMatkulList();
                    }
                  : null,
            ),
          const SizedBox(height: 12),
          if (_loadingMatkul)
            const Center(child: CircularProgressIndicator(color: Color(0xFFBBDEFB)))
          else
            _buildGlassDropdown(
              value: _matkulList.isNotEmpty ? _selectedMakul : null,
              items: _matkulList,
              hint: 'Matakuliah',
              onChanged: _selectedSmt != null
                  ? (v) {
                      setState(() => _selectedMakul = v);
                      if (v != null) _loadMahasiswa();
                    }
                  : null,
            ),
          if (_selectedThn != null && _selectedThn!.isNotEmpty && _semesterList.isEmpty && !_loadingSemester)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _loadSemesterList,
                icon: const Icon(CupertinoIcons.search, size: 18, color: Color(0xFF501F66)),
                label: const Text('Cari Semester', style: TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String? value,
    required List<OptionItem> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          isExpanded: true,
          icon: const Icon(CupertinoIcons.chevron_down, color: Color(0xFF501F66), size: 16),
          items: items.map((e) => DropdownMenuItem(
            value: e.value,
            child: Text(e.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHasil() {
    final m = _mahasiswa!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(CupertinoIcons.person_fill, size: 20, color: Color(0xFF501F66)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(m.namaDosen, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66))),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Jenis: ${m.jenisPerkuliahan}', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        _buildStatistik(m.statistik),
        const SizedBox(height: 24),
        const Text('Riwayat Pertemuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66))),
        const SizedBox(height: 12),
        ...m.riwayatPertemuan.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRiwayatCard(r),
        )),
      ],
    );
  }

  Widget _buildStatistik(StatistikAbsensi s) {
    final items = [
      ('Hadir', s.hadir, Colors.green),
      ('Izin', s.izin, Colors.blue),
      ('Sakit', s.sakit, Colors.orange),
      ('Bolos', s.tanpaKeterangan, Colors.red),
      ('Pending', s.belumValidasi, Colors.grey),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(item.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: item.$2 / 100,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        color: item.$3,
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 45,
                    child: Text('${item.$2.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.$3)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(RiwayatPertemuan r) {
    final Color statusColor;
    final String statusLabel;
    switch (r.status.toUpperCase()) {
      case 'H':
        statusColor = Colors.green;
        statusLabel = 'Hadir';
        break;
      case 'B':
        statusColor = Colors.red;
        statusLabel = 'Bolos';
        break;
      case 'I':
        statusColor = Colors.blue;
        statusLabel = 'Izin';
        break;
      case 'S':
        statusColor = Colors.orange;
        statusLabel = 'Sakit';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = r.status;
    }

    return GlassCard(
      padding: EdgeInsets.zero, // Padding is handled by InkWell
      child: InkWell(
        onTap: r.idPresensi != null
            ? () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => AbsensiDetailPage(idPresensi: r.idPresensi!)),
                );
                if (result == true) {
                  _loadBelumValidasi();
                  if (_selectedMakul != null) _loadMahasiswa();
                }
              }
            : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(r.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.tanggal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(r.materi, style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (r.idPresensi != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              if (r.idPresensi != null)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(CupertinoIcons.chevron_right, color: Colors.black26, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

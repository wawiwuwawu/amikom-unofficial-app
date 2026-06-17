import 'package:flutter/material.dart';
import '../models/absensi.dart';
import '../services/absensi_service.dart';
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
      setState(() =>
          _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingBelumValidasi = false);
    }
  }

  Future<void> _onTapBelumValidasi(MakulBelumValidasi item) async {
    setState(() {
      _selectedThn = null;
      _selectedSmt = null;
      _selectedMakul = item.kode;
      _semesterList = [];
      _matkulList = [];
      _mahasiswa = null;
      _errorFilter = null;
    });
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
      setState(() => _errorFilter =
          e.toString().replaceFirst('Exception: ', ''));
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
      final data =
          await _service.getMatkul(_selectedThn!, _selectedSmt!);
      if (!mounted) return;
      setState(() {
        _matkulList = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter =
          e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMatkul = false);
    }
  }

  Future<void> _loadMahasiswa() async {
    if (_selectedThn == null || _selectedSmt == null || _selectedMakul == null) {
      return;
    }
    if (!mounted) return;
    setState(() => _loadingMahasiswa = true);
    try {
      final data = await _service.getMahasiswa(
          _selectedThn!, _selectedSmt!, _selectedMakul!);
      if (!mounted) return;
      setState(() {
        _mahasiswa = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMahasiswa = false);
    }
  }

  Future<void> _validasiSemua(MakulBelumValidasi item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validasi Semua'),
        content: Text(
            'Validasi ${item.count} pertemuan "${item.makul}" dengan nilai default?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Validasi')),
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
          'jenispilih':
              detail.keterangan == 'H' ? 'teori' : detail.keterangan,
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
                k.id: k.nilai
                    .reduce((a, b) => a.nilai >= b.nilai ? a : b)
                    .id
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
          content: Text(
              'Validasi: $success berhasil, $failed gagal'),
        ),
      );
    }
    _loadBelumValidasi();
    setState(() => _validatingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBelumValidasi();
          if (_selectedThn != null &&
              _selectedSmt != null &&
              _selectedMakul != null) {
            await _loadMahasiswa();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBelumValidasi(),
              const Divider(height: 24),
              _buildFilter(),
              if (_errorFilter != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Column(
                      children: [
                        Text(_errorFilter!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        TextButton(
                            onPressed: _loadBelumValidasi,
                            child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                ),
              if (_loadingMahasiswa)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_mahasiswa != null && !_loadingMahasiswa)
                _buildHasil(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBelumValidasi() {
    if (_loadingBelumValidasi) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_belumValidasi.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 6),
            const Text('Perlu Validasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            if (_validatingAll)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 8),
        ..._belumValidasi.map(_buildBelumValidasiCard),
      ],
    );
  }

  Widget _buildBelumValidasiCard(MakulBelumValidasi item) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _onTapBelumValidasi(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                radius: 18,
                child: Text('${item.count}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.makul,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                        item.kelasgab.isNotEmpty
                            ? item.kelasgab[0]
                            : item.kode,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _validatingAll ? null : () => _validasiSemua(item),
                child: const Text('Validasi', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tahun Akademik',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                child: Text(_selectedThn ?? '',
                    style: const TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang semester',
              onPressed: () {
                _initAcademicYear();
                _loadSemesterList();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingSemester)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            key: ValueKey('smt_$_selectedSmt'),
            initialValue: _semesterList.isNotEmpty ? _selectedSmt : null,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
            items: _semesterList
                .map((s) => DropdownMenuItem(
                    value: s.value, child: Text(s.label)))
                .toList(),
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
        const SizedBox(height: 8),
        if (_loadingMatkul)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            key: ValueKey('makul_$_selectedMakul'),
            initialValue: _matkulList.isNotEmpty ? _selectedMakul : null,
            decoration: const InputDecoration(
              labelText: 'Matakuliah',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
            items: _matkulList
                .map((m) => DropdownMenuItem(
                    value: m.value, child: Text(m.label)))
                .toList(),
            onChanged: _selectedSmt != null
                ? (v) {
                    setState(() => _selectedMakul = v);
                    if (v != null) _loadMahasiswa();
                  }
                : null,
          ),
        if (_selectedThn != null &&
            _selectedThn!.isNotEmpty &&
            _semesterList.isEmpty &&
            !_loadingSemester)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: _loadSemesterList,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Cari Semester'),
            ),
          ),
      ],
    );
  }

  Widget _buildHasil() {
    final m = _mahasiswa!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            const Icon(Icons.person, size: 18, color: Colors.indigo),
            const SizedBox(width: 6),
            Text(m.namaDosen,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Jenis: ${m.jenisPerkuliahan}',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        _buildStatistik(m.statistik),
        const SizedBox(height: 12),
        const Text('Riwayat Pertemuan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        ...m.riwayatPertemuan.map(_buildRiwayatCard),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                        width: 60,
                        child: Text(item.$1,
                            style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.$2 / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: item.$3,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text('${item.$2.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
          ],
        ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: r.idPresensi != null
            ? () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AbsensiDetailPage(idPresensi: r.idPresensi!),
                  ),
                );
                if (result == true) {
                  _loadBelumValidasi();
                  if (_selectedMakul != null) _loadMahasiswa();
                }
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(r.status.toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.tanggal,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(r.materi,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (r.idPresensi != null)
                Chip(
                  label: Text(statusLabel,
                      style: TextStyle(fontSize: 11, color: statusColor)),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              if (r.idPresensi != null)
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

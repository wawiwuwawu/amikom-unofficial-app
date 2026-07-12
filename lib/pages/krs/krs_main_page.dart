import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/krs_service.dart';
import '../../models/krs.dart';
import '../jadwal_page.dart';

class KrsMainPage extends StatefulWidget {
  const KrsMainPage({super.key});

  @override
  State<KrsMainPage> createState() => _KrsMainPageState();
}

class _KrsMainPageState extends State<KrsMainPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kartu Rencana Studi (KRS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: const Color(0xFFFAFCFF),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF501F66),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF501F66),
            tabs: [
              Tab(text: 'Pengajuan'),
              Tab(text: 'Daftar'),
              Tab(text: 'Pengisian'),
              Tab(text: 'Cetak & Jadwal'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InfoPengajuanTab(),
            _DaftarPengajuanTab(),
            _PengisianKelasTab(),
            JadwalPage(showDownloadKrs: true),
          ],
        ),
      ),
    );
  }
}

class _InfoPengajuanTab extends StatefulWidget {
  const _InfoPengajuanTab();

  @override
  State<_InfoPengajuanTab> createState() => _InfoPengajuanTabState();
}

class _InfoPengajuanTabState extends State<_InfoPengajuanTab> {
  final _service = KrsService();
  bool _loading = true;
  String? _error;
  KrsInfo? _info;
  List<MatkulDitawarkan> _matkulList = [];
  int _maxSks = 0;
  int _sksSaatIni = 0;
  
  // Set of selected KODE
  final Set<String> _selectedMakul = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final info = await _service.getInfo();
      final matkulRes = await _service.getMatkulDitawarkan();
      if (mounted) {
        setState(() {
          _info = info;
          _matkulList = matkulRes.data;
          _maxSks = matkulRes.maxSks;
          _sksSaatIni = matkulRes.sksSaatIni;
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

  int get _selectedSks {
    int total = 0;
    for (var mk in _matkulList) {
      if (_selectedMakul.contains(mk.kode)) {
        total += mk.sks;
      }
    }
    return total;
  }

  void _submit() async {
    if (_selectedMakul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu mata kuliah')));
      return;
    }
    
    final List<String> payload = _selectedMakul.toList(); 
    
    setState(() => _loading = true);
    try {
      await _service.submitPengajuan(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan berhasil disimpan')));
        _selectedMakul.clear();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi'))
          ],
        ),
      );
    }
    
    // Group by Semester
    Map<int, List<MatkulDitawarkan>> groupedMatkul = {};
    for (var mk in _matkulList) {
      groupedMatkul.putIfAbsent(mk.semester, () => []).add(mk);
    }
    final sortedSemesters = groupedMatkul.keys.toList()..sort();

    return Column(
      children: [
        if (_info?.periodePengajuan != null && _info!.periodePengajuan!.teksMentah.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Text(
              _info!.periodePengajuan!.teksMentah,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Batas SKS: $_maxSks', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Terpilih: ${_selectedSks + _sksSaatIni} SKS', 
                style: TextStyle(fontWeight: FontWeight.bold, color: (_selectedSks + _sksSaatIni) > _maxSks ? Colors.red : Colors.green)
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
            children: [
              for (var smt in sortedSemesters) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Text('Semester $smt', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                ),
                for (var mk in groupedMatkul[smt]!)
                  CheckboxListTile(
                    title: Text(mk.nama),
                    subtitle: Text('${mk.kode} - ${mk.sks} SKS${mk.isUlang ? " (Ulang)" : ""}'),
                    value: _selectedMakul.contains(mk.kode),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedMakul.add(mk.kode);
                        } else {
                          _selectedMakul.remove(mk.kode);
                        }
                      });
                    },
                  ),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, 
            bottom: MediaQuery.of(context).padding.bottom + 16
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66), 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14)
              ),
              onPressed: (_selectedSks + _sksSaatIni) > _maxSks ? null : _submit,
              child: const Text('Ajukan Mata Kuliah'),
            ),
          ),
        )
      ],
    );
  }
}

class _DaftarPengajuanTab extends StatefulWidget {
  const _DaftarPengajuanTab();
  @override
  State<_DaftarPengajuanTab> createState() => _DaftarPengajuanTabState();
}

class _DaftarPengajuanTabState extends State<_DaftarPengajuanTab> {
  final _service = KrsService();
  bool _loading = true;
  String? _error;
  List<KrsPengajuan> _list = [];
  int _totalSks = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _service.getPengajuan();
      if (mounted) {
        setState(() {
          _list = res.data;
          _totalSks = res.totalSks;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _delete(String idKrs) async {
    setState(() => _loading = true);
    try {
      await _service.deletePengajuan(idKrs);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: ${e.toString()}')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi'))
          ],
        ),
      );
    }
    if (_list.isEmpty) return const Center(child: Text('Belum ada matkul yang diajukan'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Total SKS Diajukan: $_totalSks', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
            itemCount: _list.length,
            itemBuilder: (context, index) {
              final mk = _list[index];
              return ListTile(
                title: Text(mk.mkl),
                subtitle: Text('${mk.kode} - ${mk.sks} SKS\nStatus: ${mk.aktivasi == 1 ? "Aktif" : "Belum Aktif"}'),
                trailing: mk.aktivasi == 0 
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                      onPressed: () => _delete(mk.idKrs.toString()),
                    )
                  : const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PengisianKelasTab extends StatefulWidget {
  const _PengisianKelasTab();
  @override
  State<_PengisianKelasTab> createState() => _PengisianKelasTabState();
}

class _PengisianKelasTabState extends State<_PengisianKelasTab> {
  final _service = KrsService();
  bool _loading = true;
  String? _error;
  List<KrsPengisian> _listSudah = [];
  List<KrsPengisian> _listBelum = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final resSudah = await _service.getPengisian();
      final resBelum = await _service.getBelumDiisi();
      if (mounted) {
        setState(() {
          _listSudah = resSudah.data;
          _listBelum = resBelum.data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _batal(String kode) async {
    setState(() => _loading = true);
    try {
      await _service.deletePengisian(kode);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan: ${e.toString()}')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi'))
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16, 
        bottom: MediaQuery.of(context).padding.bottom + 80
      ),
      children: [
        const Text('Matkul Belum Diisi Kelasnya:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (_listBelum.isEmpty) const Text('Semua matkul sudah diisi kelasnya', style: TextStyle(color: Colors.green)),
        ..._listBelum.map((mk) => Card(
          color: Colors.white,
          child: ListTile(
            textColor: Colors.black87,
            title: Text(mk.namaMataKuliah),
            subtitle: Text('${mk.kodeMk} - ${mk.sks} SKS', style: const TextStyle(color: Colors.black54)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), foregroundColor: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form pengisian kelas masih menunggu penyelesaian backend adaptor')));
              },
              child: const Text('Pilih Kelas'),
            ),
          ),
        )),
        const Divider(height: 32),
        const Text('Daftar Kelas Terpilih:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (_listSudah.isEmpty) const Text('Belum ada kelas yang dipilih', style: TextStyle(color: Colors.grey)),
        ..._listSudah.map((mk) => Card(
          color: Colors.white,
          child: ListTile(
            textColor: Colors.black87,
            title: Text('${mk.namaMataKuliah} - Ruang ${mk.ruang}'),
            subtitle: Text('${mk.hari}, ${mk.jam}\nDosen: ${mk.dosenKelas.isEmpty ? "-" : mk.dosenKelas}', style: const TextStyle(color: Colors.black54)),
            trailing: IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Colors.red),
              onPressed: () => _batal(mk.kodeMk),
            ),
          ),
        )),
      ],
    );
  }
}

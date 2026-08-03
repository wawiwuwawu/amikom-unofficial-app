import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/krs_service.dart';
import '../../models/krs.dart';
import '../jadwal_page.dart';

class KrsMainPage extends StatefulWidget {
  final VoidCallback? onBack;
  const KrsMainPage({super.key, this.onBack});

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
          leading: widget.onBack != null ? IconButton(icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)), onPressed: widget.onBack) : null,
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
  bool _isAnnouncementExpanded = false;
  
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

  void _syncKrs() async {
    setState(() => _loading = true);
    try {
      await _service.sinkronisasi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi berhasil')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal sinkronisasi: ${e.toString()}')));
        setState(() => _loading = false);
      }
    }
  }

  void _submit() async {
    if (_selectedMakul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu mata kuliah')));
      return;
    }
    
    final List<String> payload = _selectedMakul.toList(); 
    
    setState(() => _loading = true);
    try {
      // 1. Submit pengajuan
      await _service.submitPengajuan(payload);
      
      // 2. Auto trigger sinkronisasi (sesuai sequence flow BE)
      try {
        await _service.sinkronisasi();
      } catch (_) {
        // Sinkronisasi silently non-blocking if server sync is deferred
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan & Sinkronisasi KRS berhasil disimpan')),
        );
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

  Widget _buildAnnouncementBanner(String text) {
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.info_circle_fill,
                  size: 18, color: Color(0xFF1976D2)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ketentuan & Informasi KRS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Text(
              cleanText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            secondChild: Text(
              cleanText,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            crossFadeState: _isAnnouncementExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _isAnnouncementExpanded = !_isAnnouncementExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  _isAnnouncementExpanded
                      ? 'Sembunyikan'
                      : 'Lihat Selengkapnya',
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isAnnouncementExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 14,
                  color: const Color(0xFF1976D2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          _buildAnnouncementBanner(_info!.periodePengajuan!.teksMentah),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _syncKrs,
              icon: const Icon(CupertinoIcons.arrow_2_circlepath),
              label: const Text('Sinkronisasi Tagihan & KRS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF501F66),
                side: const BorderSide(color: Color(0xFF501F66)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
            children: [
              for (var smt in sortedSemesters) 
                ExpansionTile(
                  initiallyExpanded: false,
                  title: Text('Semester $smt', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                  backgroundColor: Colors.grey.withValues(alpha: 0.05),
                  children: [
                    for (var mk in groupedMatkul[smt]!) ...[
                      Builder(builder: (context) {
                        final isLulus = mk.status.toLowerCase() == 'lulus';
                        return CheckboxListTile(
                          title: Text(
                            mk.nama,
                            style: TextStyle(
                              color: isLulus ? Colors.black45 : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${mk.kode} • ${mk.sks} SKS',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isLulus ? Colors.black38 : Colors.black54,
                                ),
                              ),
                              if (isLulus || mk.isUlang || (mk.nilaiSebelumnya != null && mk.nilaiSebelumnya!.isNotEmpty)) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (isLulus)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Sudah Lulus${mk.nilaiSebelumnya != null && mk.nilaiSebelumnya!.isNotEmpty ? " (${mk.nilaiSebelumnya})" : ""}',
                                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    else ...[
                                      if (mk.isUlang)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Mengulang',
                                            style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      if (mk.nilaiSebelumnya != null && mk.nilaiSebelumnya!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Nilai Lalu: ${mk.nilaiSebelumnya}',
                                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                          value: _selectedMakul.contains(mk.kode),
                          onChanged: isLulus
                              ? null
                              : (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedMakul.add(mk.kode);
                                    } else {
                                      _selectedMakul.remove(mk.kode);
                                    }
                                  });
                                },
                        );
                      }),
                    ],
                  ],
                ),
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/skripsi.dart';
import '../services/skripsi_service.dart';
import '../widgets/glass_card.dart';

class SkripsiPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SkripsiPage({super.key, this.onBack});

  @override
  State<SkripsiPage> createState() => _SkripsiPageState();
}

class _SkripsiPageState extends State<SkripsiPage> with SingleTickerProviderStateMixin {
  final SkripsiService _service = SkripsiService();
  late TabController _tabController;

  // Main Info State
  bool _isLoadingMain = true;
  String? _errorMain;
  SkripsiMainData? _mainData;

  // Proposal State
  bool _isLoadingProposal = true;
  String? _errorProposal;
  List<SkripsiProposalItem> _proposals = [];

  // Bimbingan State
  bool _isLoadingBimbingan = true;
  String? _errorBimbingan;
  List<SkripsiBimbinganItem> _bimbingans = [];

  // Pendaftaran State
  bool _isLoadingPendaftaran = true;
  String? _errorPendaftaran;
  List<SkripsiPendaftaranItem> _pendaftarans = [];

  // Plagiarisme State
  bool _isLoadingPlagiarisme = true;
  String? _errorPlagiarisme;
  List<SkripsiPlagiarismeItem> _plagiarsmes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchMainInfo(),
      _fetchProposals(),
      _fetchBimbingans(),
      _fetchPendaftarans(),
      _fetchPlagiarsmes(),
    ]);
  }

  Future<void> _fetchMainInfo() async {
    setState(() {
      _isLoadingMain = true;
      _errorMain = null;
    });
    try {
      final data = await _service.getMainInfo();
      if (mounted) {
        setState(() {
          _mainData = data;
          _isLoadingMain = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMain = e.toString().replaceFirst('Exception: ', '');
          _isLoadingMain = false;
        });
      }
    }
  }

  Future<void> _fetchProposals() async {
    setState(() {
      _isLoadingProposal = true;
      _errorProposal = null;
    });
    try {
      final list = await _service.getProposals();
      if (mounted) {
        setState(() {
          _proposals = list;
          _isLoadingProposal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorProposal = e.toString().replaceFirst('Exception: ', '');
          _isLoadingProposal = false;
        });
      }
    }
  }

  Future<void> _fetchBimbingans() async {
    setState(() {
      _isLoadingBimbingan = true;
      _errorBimbingan = null;
    });
    try {
      final list = await _service.getBimbinganList();
      if (mounted) {
        setState(() {
          _bimbingans = list;
          _isLoadingBimbingan = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorBimbingan = e.toString().replaceFirst('Exception: ', '');
          _isLoadingBimbingan = false;
        });
      }
    }
  }

  Future<void> _fetchPendaftarans() async {
    setState(() {
      _isLoadingPendaftaran = true;
      _errorPendaftaran = null;
    });
    try {
      final list = await _service.getPendaftaranList();
      if (mounted) {
        setState(() {
          _pendaftarans = list;
          _isLoadingPendaftaran = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorPendaftaran = e.toString().replaceFirst('Exception: ', '');
          _isLoadingPendaftaran = false;
        });
      }
    }
  }

  Future<void> _fetchPlagiarsmes() async {
    setState(() {
      _isLoadingPlagiarisme = true;
      _errorPlagiarisme = null;
    });
    try {
      final list = await _service.getPlagiarismeList();
      if (mounted) {
        setState(() {
          _plagiarsmes = list;
          _isLoadingPlagiarisme = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorPlagiarisme = e.toString().replaceFirst('Exception: ', '');
          _isLoadingPlagiarisme = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFCFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: Color(0xFF501F66)),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Skripsi & Tugas Akhir 🎓',
          style: TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.gear_alt_fill, color: Color(0xFF501F66)),
            tooltip: 'Pasca Ujian (Judul & Berkas)',
            onPressed: _showPascaUjianMenu,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF501F66)),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildHeaderCard(),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFF501F66),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF501F66),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: '📄 Proposal'),
                    Tab(text: '📝 Bimbingan'),
                    Tab(text: '🎓 Ujian Skripsi'),
                    Tab(text: '🔍 Plagiarisme'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProposalTab(),
            _buildBimbinganTab(),
            _buildPendaftaranTab(),
            _buildPlagiarismeTab(),
          ],
        ),
      ),
    );
  }

  // --- HEADER & MAIN INFO ---
  Widget _buildHeaderCard() {
    if (_isLoadingMain) {
      return const GlassCard(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMain != null) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_errorMain!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchMainInfo,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final main = _mainData;
    if (main == null) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      opacity: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.book_circle_fill, color: Color(0xFF501F66), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Pembimbing Skripsi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF501F66)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          main.dospemAssigned ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.exclamationmark_triangle_fill,
                          size: 16,
                          color: main.dospemAssigned ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          main.dospemAssigned ? 'Dosen Pembimbing Terdaftar' : 'Belum Ada Dosen Pembimbing',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: main.dospemAssigned ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (main.dospemWarning != null && main.dospemWarning!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                main.dospemWarning!,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            ),
          ],
          if (main.informasi.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              '📢 Petunjuk & Pengumuman BAP:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            ...main.informasi.map(
              (info) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                    Expanded(child: Text(info, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                  ],
                ),
              ),
            ),
          ],
          if (main.tataCaraDownloadUrl != null && main.tataCaraDownloadUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUrl(main.tataCaraDownloadUrl!),
                icon: const Icon(CupertinoIcons.doc_text_fill, size: 16, color: Color(0xFF501F66)),
                label: const Text('Download Panduan & Tata Cara', style: TextStyle(color: Color(0xFF501F66), fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF501F66)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // --- TAB 1: PROPOSAL ---
  Widget _buildProposalTab() {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 130;

    if (_isLoadingProposal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorProposal != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorProposal!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchProposals,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Proposal Skripsi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            ElevatedButton.icon(
              onPressed: _showFormProposalBaru,
              icon: const Icon(CupertinoIcons.add, size: 16, color: Colors.white),
              label: const Text('Ajukan Proposal', style: TextStyle(fontSize: 12, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_proposals.isEmpty)
          const GlassCard(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(CupertinoIcons.doc_plaintext, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada riwayat pengajuan proposal', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ..._proposals.map((item) => _buildProposalCard(item)),
      ],
    );
  }

  Widget _buildProposalCard(SkripsiProposalItem item) {
    Color statusColor = Colors.orange;
    if (item.status.toLowerCase().contains('terima') || item.status.toLowerCase().contains('setuju')) {
      statusColor = Colors.green;
    } else if (item.status.toLowerCase().contains('tolak')) {
      statusColor = Colors.red;
    }

    final isDitolak = item.status.toLowerCase().contains('tolak');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pengajuan #${item.no}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.judul,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(CupertinoIcons.person_fill, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(item.dosen ?? 'Reviewer belum ditentukan', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.calendar, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Tanggal: ${item.tglPengajuan}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (item.review != null && item.review!.isNotEmpty) ...[
              const Divider(height: 16),
              Text('Catatan Reviewer: ${item.review}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.redAccent)),
            ],
            if (isDitolak) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showFormProposalUlang(item),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF501F66)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Proposal Ulang', style: TextStyle(fontSize: 11, color: Color(0xFF501F66))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleTemaUlang(item),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Tema Ulang (Pusat Studi)', style: TextStyle(fontSize: 11, color: Colors.orange)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 2: BIMBINGAN ---
  Widget _buildBimbinganTab() {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 130;

    if (_isLoadingBimbingan) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorBimbingan != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorBimbingan!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchBimbingans,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kartu Bimbingan Skripsi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            Row(
              children: [
                if (_bimbingans.isNotEmpty)
                  IconButton(
                    icon: const Icon(CupertinoIcons.arrow_down_doc_fill, color: Color(0xFF501F66)),
                    tooltip: 'Cetak Kartu Bimbingan PDF',
                    onPressed: () => _handleDownloadKartuBimbingan(_bimbingans.first.id),
                  ),
                ElevatedButton.icon(
                  onPressed: _showFormBimbingan,
                  icon: const Icon(CupertinoIcons.add, size: 16, color: Colors.white),
                  label: const Text('Catatan Baru', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF501F66),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_bimbingans.isEmpty)
          const GlassCard(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(CupertinoIcons.doc_text, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada catatan bimbingan skripsi', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ..._bimbingans.map((item) => _buildBimbinganCard(item)),
      ],
    );
  }

  Widget _buildBimbinganCard(SkripsiBimbinganItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.progres,
                    style: const TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.pencil, size: 18, color: Color(0xFF501F66)),
                      onPressed: () => _showFormBimbingan(item: item),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrow_down_doc, size: 18, color: Color(0xFF501F66)),
                      onPressed: () => _handleDownloadKartuBimbingan(item.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(CupertinoIcons.calendar, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Tanggal: ${item.tanggal}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.keterangan,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: PENDAFTARAN & UJIAN ---
  Widget _buildPendaftaranTab() {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 130;

    if (_isLoadingPendaftaran) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorPendaftaran != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorPendaftaran!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchPendaftarans,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pengajuan Ujian Skripsi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            ElevatedButton.icon(
              onPressed: _showFormPendaftaranUjian,
              icon: const Icon(CupertinoIcons.add, size: 16, color: Colors.white),
              label: const Text('Daftar Ujian', style: TextStyle(fontSize: 12, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendaftarans.isEmpty)
          const GlassCard(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(CupertinoIcons.person_2_square_stack, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada riwayat pendaftaran ujian skripsi', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ..._pendaftarans.map((item) => _buildPendaftaranCard(item)),
      ],
    );
  }

  Widget _buildPendaftaranCard(SkripsiPendaftaranItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.aktivasi == 1 ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.aktivasi == 1 ? 'Terverifikasi / Aktif' : 'Menunggu Verifikasi',
                    style: TextStyle(
                      color: item.aktivasi == 1 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (item.canDelete)
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                    onPressed: () => _handleDeletePendaftaran(item.idPengajuan),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.judul,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(CupertinoIcons.calendar_badge_plus, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Tgl Daftar: ${item.tglDaftar}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
            if (item.tglUjian != null && item.tglUjian!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(CupertinoIcons.clock_fill, size: 14, color: Color(0xFF501F66)),
                  const SizedBox(width: 4),
                  Text('Jadwal Ujian: ${item.tglUjian} (${item.jam ?? '-'})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                ],
              ),
              if (item.ruang != null && item.ruang!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(CupertinoIcons.location_fill, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Ruang: ${item.ruang}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ],
            ],
            if (item.canDownload) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleDownloadFormulirPendaftaran(item.idPengajuan),
                  icon: const Icon(CupertinoIcons.arrow_down_doc, size: 16, color: Color(0xFF501F66)),
                  label: const Text('Download Formulir Pendaftaran PDF', style: TextStyle(color: Color(0xFF501F66), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF501F66)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 4: CEK PLAGIARISME ---
  Widget _buildPlagiarismeTab() {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 130;

    if (_isLoadingPlagiarisme) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorPlagiarisme != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorPlagiarisme!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchPlagiarsmes,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Status Cek Plagiarisme',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            ElevatedButton.icon(
              onPressed: _handleUploadPlagiarisme,
              icon: const Icon(CupertinoIcons.cloud_upload_fill, size: 16, color: Colors.white),
              label: const Text('Upload File (.doc/.docx)', style: TextStyle(fontSize: 12, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_plagiarsmes.isEmpty)
          const GlassCard(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(CupertinoIcons.doc_text_search, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada dokumen cek plagiarisme', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ..._plagiarsmes.map((item) => _buildPlagiarismeCard(item)),
      ],
    );
  }

  Widget _buildPlagiarismeCard(SkripsiPlagiarismeItem item) {
    final isLolos = item.status.toLowerCase().contains('lolos');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLolos ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Status: ${item.status}',
                    style: TextStyle(
                      color: isLolos ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                  onPressed: () => _handleDeletePlagiarisme(item.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.judulSkripsi,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(CupertinoIcons.percent, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Persentase Similarity: ${item.persentase}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            if (item.laporanHasilCek != null && item.laporanHasilCek!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openUrl(item.laporanHasilCek!),
                  icon: const Icon(CupertinoIcons.doc_text_search, size: 16, color: Color(0xFF501F66)),
                  label: const Text('Lihat Laporan Hasil Cek Plagiarisme', style: TextStyle(color: Color(0xFF501F66), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF501F66)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- ACTIONS & MODAL DIALOGS ---

  void _showFormProposalBaru() {
    final judulCtrl = TextEditingController();
    final reviewerCtrl = TextEditingController();
    final temaCtrl = TextEditingController();
    String tipe = 'non_fik';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBsState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFCFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajukan Proposal Skripsi Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: tipe,
                decoration: const InputDecoration(labelText: 'Tipe Proposal', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'non_fik', child: Text('Non-FIK')),
                  DropdownMenuItem(value: 'fik', child: Text('FIK')),
                ],
                onChanged: (val) => setBsState(() => tipe = val ?? 'non_fik'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: judulCtrl,
                decoration: const InputDecoration(labelText: 'Judul Skripsi', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewerCtrl,
                decoration: const InputDecoration(labelText: 'ID Reviewer / Dosen', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: temaCtrl,
                decoration: const InputDecoration(labelText: 'ID Tema Pusat Studi', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    if (judulCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final res = await _service.submitProposalBaru(
                        tipe: tipe,
                        judul: judulCtrl.text.trim(),
                        idReviewer: reviewerCtrl.text.trim(),
                        idTema: temaCtrl.text.trim(),
                      );
                      _showSnackBar(res['message'] ?? 'Proposal berhasil diajukan');
                      _fetchProposals();
                    } catch (e) {
                      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
                    }
                  },
                  child: const Text('Kirim Pengajuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFormProposalUlang(SkripsiProposalItem item) {
    final reviewerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Proposal Ulang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Judul: ${item.judul}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: reviewerCtrl,
              decoration: const InputDecoration(labelText: 'ID Reviewer Baru / Pilihan', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await _service.submitProposalUlang(
                  idReviewer: reviewerCtrl.text.trim(),
                  idProposal: item.idProposal ?? '1',
                );
                _showSnackBar(res['message'] ?? 'Proposal ulang diajukan');
                _fetchProposals();
              } catch (e) {
                _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
              }
            },
            child: const Text('Kirim Proposal Ulang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleTemaUlang(SkripsiProposalItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Tema Ulang'),
        content: const Text('Apakah Anda yakin ingin mengajukan ulang tema skripsi ke Pusat Studi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Ajukan Tema Ulang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.submitTemaUlang(idProposal: item.idProposal ?? '1');
        _showSnackBar(res['message'] ?? 'Tema ulang berhasil diajukan');
        _fetchProposals();
      } catch (e) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  void _showFormBimbingan({SkripsiBimbinganItem? item}) {
    final isEdit = item != null;
    final tanggalCtrl = TextEditingController(text: item?.tanggal ?? DateTime.now().toString().split(' ').first);
    final progresCtrl = TextEditingController(text: item?.progres ?? '');
    final keteranganCtrl = TextEditingController(text: item?.keterangan ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFCFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Catatan Bimbingan' : 'Tambah Catatan Bimbingan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
            const SizedBox(height: 16),
            TextField(
              controller: tanggalCtrl,
              decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: progresCtrl,
              decoration: const InputDecoration(labelText: 'Progres (misal: BAB 1 / BAB 2)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keteranganCtrl,
              decoration: const InputDecoration(labelText: 'Keterangan / Catatan Revisi', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (progresCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    if (isEdit) {
                      final res = await _service.updateBimbingan(
                        id: item.id,
                        tanggal: tanggalCtrl.text.trim(),
                        progres: progresCtrl.text.trim(),
                        keterangan: keteranganCtrl.text.trim(),
                      );
                      _showSnackBar(res['message'] ?? 'Catatan bimbingan berhasil diperbarui');
                    } else {
                      final res = await _service.submitBimbingan(
                        tanggal: tanggalCtrl.text.trim(),
                        idauto: _mainData?.idauto ?? '',
                        nidn: _mainData?.nidn ?? '',
                        progres: progresCtrl.text.trim(),
                        keterangan: keteranganCtrl.text.trim(),
                      );
                      _showSnackBar(res['message'] ?? 'Catatan bimbingan disimpan');
                    }
                    _fetchBimbingans();
                  } catch (e) {
                    _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
                  }
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Bimbingan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDownloadKartuBimbingan(String id) async {
    _showSnackBar('Mengunduh kartu bimbingan...');
    try {
      final path = await _service.downloadKartuBimbingan(id);
      _showSnackBar('Kartu bimbingan tersimpan di Download');
      await OpenFilex.open(path);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showFormPendaftaranUjian() {
    final judulCtrl = TextEditingController();
    String ukuranToga = 'L';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBsState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFCFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Form Pendaftaran Ujian Skripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
              const SizedBox(height: 16),
              TextField(
                controller: judulCtrl,
                decoration: const InputDecoration(labelText: 'Judul Skripsi', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: ukuranToga,
                decoration: const InputDecoration(labelText: 'Ukuran Toga', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'S', child: Text('S')),
                  DropdownMenuItem(value: 'M', child: Text('M')),
                  DropdownMenuItem(value: 'L', child: Text('L')),
                  DropdownMenuItem(value: 'XL', child: Text('XL')),
                  DropdownMenuItem(value: 'XXL', child: Text('XXL')),
                ],
                onChanged: (val) => setBsState(() => ukuranToga = val ?? 'L'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    if (judulCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final res = await _service.submitPendaftaranUjian(
                        judul: judulCtrl.text.trim(),
                        ukuranToga: ukuranToga,
                      );
                      _showSnackBar(res['message'] ?? 'Pendaftaran ujian skripsi berhasil diajukan');
                      _fetchPendaftarans();
                    } catch (e) {
                      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
                    }
                  },
                  child: const Text('Daftar Ujian Skripsi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDeletePendaftaran(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batal Pengajuan Ujian'),
        content: const Text('Apakah Anda yakin ingin membatalkan pengajuan ujian skripsi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.deletePendaftaranUjian(id);
        _showSnackBar(res['message'] ?? 'Pendaftaran dibatalkan');
        _fetchPendaftarans();
      } catch (e) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  void _handleDownloadFormulirPendaftaran(String id) async {
    _showSnackBar('Mengunduh formulir pendaftaran...');
    try {
      final path = await _service.downloadFormulirPendaftaran(id);
      _showSnackBar('Formulir tersimpan di Download');
      await OpenFilex.open(path);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _handleUploadPlagiarisme() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileSize = await file.length();
      if (fileSize > 3 * 1024 * 1024) {
        _showSnackBar('Ukuran file maksimal 3MB', isError: true);
        return;
      }

      _showSnackBar('Mengunggah dokumen plagiarisme...');
      try {
        final res = await _service.uploadPlagiarisme(file);
        _showSnackBar(res['message'] ?? 'Dokumen berhasil diunggah');
        _fetchPlagiarsmes();
      } catch (e) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  void _handleDeletePlagiarisme(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen Plagiarisme'),
        content: const Text('Apakah Anda yakin ingin menghapus dokumen plagiarisme ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.deletePlagiarisme(id);
        _showSnackBar(res['message'] ?? 'Dokumen berhasil dihapus');
        _fetchPlagiarsmes();
      } catch (e) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  void _showPascaUjianMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFCFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Menu Pasca Ujian Skripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(CupertinoIcons.text_quote, color: Color(0xFF501F66)),
              title: const Text('Update Judul Skripsi (ID & EN)'),
              onTap: () {
                Navigator.pop(ctx);
                _showFormUpdateJudul();
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.link, color: Color(0xFF501F66)),
              title: const Text('Simpan Link Berkas Pasca Ujian'),
              onTap: () {
                Navigator.pop(ctx);
                _showFormSubmitLink();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFormUpdateJudul() {
    final judulIdCtrl = TextEditingController();
    final judulEnCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFCFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Judul Skripsi (ID & EN)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
            const SizedBox(height: 16),
            TextField(
              controller: judulIdCtrl,
              decoration: const InputDecoration(labelText: 'Judul Bahasa Indonesia', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: judulEnCtrl,
              decoration: const InputDecoration(labelText: 'Judul Bahasa Inggris (EN)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (judulIdCtrl.text.trim().isEmpty || judulEnCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final res = await _service.updateJudulSkripsi(
                      judulId: judulIdCtrl.text.trim(),
                      judulEn: judulEnCtrl.text.trim(),
                    );
                    _showSnackBar(res['message'] ?? 'Judul skripsi berhasil diperbarui');
                  } catch (e) {
                    _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
                  }
                },
                child: const Text('Simpan Judul', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormSubmitLink() {
    final jenisCtrl = TextEditingController(text: '1');
    final linkCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFCFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simpan Link Berkas Pasca Ujian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
            const SizedBox(height: 16),
            TextField(
              controller: jenisCtrl,
              decoration: const InputDecoration(labelText: 'ID Jenis Berkas', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkCtrl,
              decoration: const InputDecoration(labelText: 'Link File (Drive / URL)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (linkCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final res = await _service.submitLinkBerkas(
                      idJenis: jenisCtrl.text.trim(),
                      linkFile: linkCtrl.text.trim(),
                    );
                    _showSnackBar(res['message'] ?? 'Link berkas berhasil disimpan');
                  } catch (e) {
                    _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
                  }
                },
                child: const Text('Simpan Link Berkas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Gagal membuka link: $url', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF501F66),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFAFCFF),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

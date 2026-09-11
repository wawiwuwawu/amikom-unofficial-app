import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/nilai_rincian.dart';
import '../services/nilai_service.dart';
import '../widgets/glass_card.dart';

class NilaiRincianPage extends StatefulWidget {
  final VoidCallback? onBack;

  const NilaiRincianPage({
    super.key,
    this.onBack,
  });

  @override
  State<NilaiRincianPage> createState() => _NilaiRincianPageState();
}

class _NilaiRincianPageState extends State<NilaiRincianPage> {
  final _service = NilaiService();

  List<NilaiOpsiItem> _tahunList = [];
  List<NilaiOpsiItem> _semesterList = [];
  String? _selectedThn;
  String? _selectedSmt;

  RincianNilaiResponse? _rincian;
  bool _loadingOptions = true;
  bool _loadingRincian = false;
  String? _error;
  bool _isRentangExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _loadingOptions = true;
      _error = null;
    });

    try {
      // 1. Ambil opsi tahun akademik dan semester
      final tahunFuture = _service.getTahunAkademikList().catchError((_) => <NilaiOpsiItem>[]);
      final semesterFuture = _service.getSemesterList().catchError((_) => <NilaiOpsiItem>[]);
      final rincianFuture = _service.getRincianNilai().catchError((_) => const RincianNilaiResponse(
            thnAkademik: '',
            semesterId: '',
            semesterLabel: '',
            thnAktif: '',
            kelompok: [],
            rentangNilai: [],
          ));

      final results = await Future.wait([tahunFuture, semesterFuture, rincianFuture]);
      if (!mounted) return;

      final tahunResult = results[0] as List<NilaiOpsiItem>;
      final semesterResult = results[1] as List<NilaiOpsiItem>;
      final rincianResult = results[2] as RincianNilaiResponse;

      String? activeThn;
      String? activeSmt;

      if (rincianResult.thnAkademik.isNotEmpty) {
        activeThn = rincianResult.thnAkademik;
      } else if (tahunResult.isNotEmpty) {
        activeThn = tahunResult.first.value;
      }

      if (rincianResult.semesterId.isNotEmpty) {
        activeSmt = rincianResult.semesterId;
      } else if (semesterResult.isNotEmpty) {
        activeSmt = semesterResult.first.value;
      }
      if (tahunResult.isEmpty && semesterResult.isEmpty && rincianResult.thnAkademik.isEmpty) {
        setState(() {
          _error = 'Tidak dapat memuat data. Periksa koneksi internet Anda.';
          _loadingOptions = false;
        });
        return;
      }

      setState(() {
        _tahunList = tahunResult;
        _semesterList = semesterResult;
        _selectedThn = activeThn;
        _selectedSmt = activeSmt;
        _rincian = (rincianResult.kelompok.isNotEmpty || rincianResult.thnAkademik.isNotEmpty)
            ? rincianResult
            : null;
        _loadingOptions = false;
      });

      // Jika rincian awal belum termuat dan opsi ada, muat data rincian spesifik
      if (_rincian == null && _selectedThn != null && _selectedSmt != null) {
        await _fetchRincian();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingOptions = false;
      });
    }
  }

  Future<void> _fetchRincian() async {
    if (!mounted) return;
    setState(() {
      _loadingRincian = true;
      _error = null;
    });

    try {
      final res = await _service.getRincianNilai(
        thnAkademik: _selectedThn,
        semester: _selectedSmt,
      );
      if (!mounted) return;
      setState(() {
        _rincian = res;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRincian = false);
      }
    }
  }

  Color _getGradeColor(String grade) {
    final clean = grade.trim().toUpperCase();
    if (clean.startsWith('A')) return const Color(0xFF2E7D32); // Emerald Green
    if (clean.startsWith('B')) return const Color(0xFF1565C0); // Sapphire Blue
    if (clean.startsWith('C')) return const Color(0xFFE65100); // Amber Orange
    if (clean.startsWith('D') || clean.startsWith('E')) {
      return const Color(0xFFC62828); // Crimson Red
    }
    return const Color(0xFF501F66); // Amikom Deep Purple
  }

  void _showRentangNilaiSheet(BuildContext context) {
    final rentangList = _rincian?.rentangNilai ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFCFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Icon(
                    CupertinoIcons.chart_bar_square_fill,
                    color: Color(0xFF501F66),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Pedoman Rentang Nilai',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF501F66),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (rentangList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Informasi rentang nilai belum tersedia.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(1.2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: const Color(0xFF501F66).withValues(alpha: 0.08),
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              child: Text(
                                'Rentang Skor',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              child: Center(
                                child: Text(
                                  'Huruf',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              child: Center(
                                child: Text(
                                  'Bobot',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...rentangList.map((r) {
                          final color = _getGradeColor(r.huruf);
                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.shade200)),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                child: Text(
                                  r.rentang,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      r.huruf,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Center(
                                  child: Text(
                                    r.bobot,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rincian Nilai',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF501F66),
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF501F66),
          ),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.info_circle_fill,
              color: Color(0xFF501F66),
            ),
            tooltip: 'Pedoman Rentang Nilai',
            onPressed: () => _showRentangNilaiSheet(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFCFF), // Pearl White
              Color(0xFFE3F2FD), // Ice Blue
            ],
          ),
        ),
        child: SafeArea(
          child: _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_loadingOptions) {
      return Center(
        child: const CircularProgressIndicator(
          color: Color(0xFF501F66),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      );
    }

    // WAJIB menerapkan bottom padding: MediaQuery.of(context).padding.bottom + 130
    final bottomNavPadding = MediaQuery.of(context).padding.bottom + 130;

    return RefreshIndicator(
      onRefresh: _fetchRincian,
      color: const Color(0xFF501F66),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomNavPadding),
        children: [
          _buildFilterCard().animate().slideY(begin: -0.1),
          const SizedBox(height: 14),
          if (_rincian != null && _rincian!.rentangNilai.isNotEmpty) ...[
            _buildExpandableRentangCard(),
            const SizedBox(height: 14),
          ],
          if (_loadingRincian) ...[
            const SizedBox(height: 60),
            Center(
              child: const CircularProgressIndicator(
                color: Color(0xFF501F66),
              ).animate().scale(),
            ),
          ] else if (_error != null) ...[
            _buildErrorState(),
          ] else if (_rincian != null) ...[
            _buildRincianList(_rincian!),
          ] else ...[
            _buildEmptyState('Pilih tahun akademik dan semester untuk melihat rincian nilai.'),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                CupertinoIcons.slider_horizontal_3,
                size: 18,
                color: Color(0xFF501F66),
              ),
              SizedBox(width: 8),
              Text(
                'Filter Semester',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF501F66),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildDropdown(
                  value: _selectedThn,
                  items: _tahunList,
                  hint: 'Tahun Akademik',
                  onChanged: (v) {
                    setState(() => _selectedThn = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  value: _selectedSmt,
                  items: _semesterList,
                  hint: 'Semester',
                  onChanged: (v) {
                    setState(() => _selectedSmt = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF501F66), Color(0xFF7B2CBF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF501F66).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: (_selectedThn != null || _selectedSmt != null)
                      ? _fetchRincian
                      : null,
                  icon: const Icon(
                    CupertinoIcons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Tampilkan Nilai',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<NilaiOpsiItem> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.any((e) => e.value == value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
          isExpanded: true,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            color: Color(0xFF501F66),
            size: 14,
          ),
          items: items.map((e) {
            return DropdownMenuItem<String>(
              value: e.value,
              child: Text(
                e.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildExpandableRentangCard() {
    final rentangList = _rincian?.rentangNilai ?? [];

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _isRentangExpanded = !_isRentangExpanded);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.chart_pie_fill,
                    size: 18,
                    color: Color(0xFF501F66),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Informasi Rentang Nilai (A, B, C, D, E)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF501F66),
                      ),
                    ),
                  ),
                  Icon(
                    _isRentangExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 16,
                    color: const Color(0xFF501F66),
                  ),
                ],
              ),
            ),
          ),
          if (_isRentangExpanded) ...[
            const Divider(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rentangList.map((r) {
                final color = _getGradeColor(r.huruf);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.huruf,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${r.rentang})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (r.bobot.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• ${r.bobot}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ).animate().fadeIn(duration: 250.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildRincianList(RincianNilaiResponse rincian) {
    if (rincian.kelompok.isEmpty) {
      return _buildEmptyState('Tidak ada data rincian nilai untuk semester ini.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rincian.kelompok.map((kelompok) {
        return _buildKelompokSection(kelompok);
      }).toList(),
    );
  }

  Widget _buildKelompokSection(KelompokNilaiItem kelompok) {
    final isReguler = kelompok.jenis.toLowerCase() == 'reguler';
    final sectionTitle = isReguler ? 'Mata Kuliah Reguler' : 'Mata Kuliah MBKM';
    final sectionIcon = isReguler
        ? CupertinoIcons.book_fill
        : CupertinoIcons.star_circle_fill;
    final sectionColor = isReguler
        ? const Color(0xFF501F66)
        : const Color(0xFFE65100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
          child: Row(
            children: [
              Icon(sectionIcon, size: 18, color: sectionColor),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: sectionColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${kelompok.matkul.length} Matkul',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: sectionColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (kelompok.matkul.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'Tidak ada mata kuliah pada kategori ini.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          )
        else
          ...kelompok.matkul.map((matkul) {
            return _buildMatkulCard(matkul, kelompok.kolom);
          }),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMatkulCard(MatkulNilaiItem matkul, List<String> kolomList) {
    final gradeColor = _getGradeColor(matkul.nilaiHuruf);

    // Dapatkan daftar komponen nilai yang valid
    final dynamicColumns = <MapEntry<String, dynamic>>[];
    if (kolomList.isNotEmpty) {
      for (final col in kolomList) {
        final val = matkul.nilai[col] ?? matkul.nilai[col.toLowerCase()] ?? '-';
        dynamicColumns.add(MapEntry(col, val));
      }
    } else if (matkul.nilai.isNotEmpty) {
      matkul.nilai.forEach((k, v) {
        dynamicColumns.add(MapEntry(k, v));
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Header: Kode & Nama + Badge Nilai Huruf & Akhir
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (matkul.kode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF501F66).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            matkul.kode,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF501F66),
                            ),
                          ),
                        ),
                      Text(
                        matkul.nama.isNotEmpty ? matkul.nama : 'Tanpa Nama Mata Kuliah',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Badge Nilai Akhir & Nilai Huruf
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradeColor.withValues(alpha: 0.9),
                        gradeColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        matkul.nilaiHuruf.isNotEmpty ? matkul.nilaiHuruf : '-',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (matkul.nilaiAkhir.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'NA: ${matkul.nilaiAkhir}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Tabel / Kartu Komponen Penilaian Dinamis
            if (dynamicColumns.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: dynamicColumns.map((entry) {
                      return Container(
                        constraints: const BoxConstraints(minWidth: 68),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFCFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.value?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF501F66),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Komponen rincian nilai belum diumumkan.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              size: 64,
              color: const Color(0xFF501F66).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 54,
              color: Colors.redAccent,
            ).animate().shake(),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Terjadi kesalahan saat memuat nilai',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchRincian,
              icon: const Icon(CupertinoIcons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

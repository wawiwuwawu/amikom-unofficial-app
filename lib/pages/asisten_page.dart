import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/asisten.dart';
import '../services/asisten_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/glass_card.dart';

class AsistenPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AsistenPage({super.key, this.onBack});

  @override
  State<AsistenPage> createState() => _AsistenPageState();
}

class _AsistenPageState extends State<AsistenPage> {
  final _service = AsistenService();

  bool _loading = true;
  String? _error;

  AsistenInfo? _info;
  AsistenLaporan? _laporan;

  // Jadwal
  List<AsistenTahunAkademik> _tahunAkademikList = [];
  AsistenTahunAkademik? _selectedTahun;
  List<AsistenJadwal> _jadwalList = [];
  bool _loadingJadwal = false;
  String? _errorJadwal;
  String? _selectedHari;
  String _fotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final info = await _service.getInfo();
      final laporan = await _service.getLaporan();
      final thnResponse = await _service.getTahunAkademik();

      String fetchedFoto = '';
      try {
        final dash = await DashboardService().getDashboard();
        fetchedFoto = dash.profile.fotoUrl;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _info = info;
          _laporan = laporan;
          _tahunAkademikList = thnResponse.data;
          _fotoUrl = fetchedFoto;

          if (_tahunAkademikList.isNotEmpty) {
            _selectedTahun = _getDefaultTahun(_tahunAkademikList);
            _loadJadwal();
          }
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

  AsistenTahunAkademik? _getDefaultTahun(List<AsistenTahunAkademik> list) {
    if (list.isEmpty) return null;
    final now = DateTime.now();
    // Tahun ajaran baru umumnya dimulai di bulan September
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    final expectedSemester = now.month >= 9 || now.month < 3 ? 1 : 2;

    // Coba cari yang pas (Tahun + Semester)
    for (var t in list) {
      if (t.thnAkademik.startsWith('$startYear/')) {
        if (t.semester == expectedSemester) return t;
      }
    }

    // Jika tidak ketemu yang pas smt-nya, cari tahunnya saja
    for (var t in list) {
      if (t.thnAkademik.startsWith('$startYear/')) return t;
    }

    return list.first; // Fallback ke elemen pertama
  }

  Future<void> _loadJadwal() async {
    if (_selectedTahun == null) return;
    setState(() {
      _loadingJadwal = true;
      _errorJadwal = null;
    });

    try {
      final res = await _service.getJadwal(
        tahun: _selectedTahun!.idTahun.toString(),
      );
      if (mounted) {
        setState(() {
          _jadwalList = res.data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorJadwal = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingJadwal = false);
    }
  }

  Future<void> _submitBebasKp() async {
    try {
      await _service.pengajuanBebasKp();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan Bebas KP berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengajukan: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  Color _hexToColor(String code) {
    if (code.startsWith('#')) code = code.substring(1);
    if (code.length == 6) code = 'FF$code';
    return Color(int.tryParse(code, radix: 16) ?? 0xFF501F66);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Asisten Praktikum',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.5),
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF501F66)),
              )
            : _error != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    bool isNotAsisten =
        _error!.toLowerCase().contains('bukan asisten') ||
        _error!.toLowerCase().contains('not found');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNotAsisten
                ? CupertinoIcons.person_crop_circle_badge_xmark
                : CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: isNotAsisten ? Colors.grey : Colors.redAccent,
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            isNotAsisten ? 'Kamu bukan asisten praktikum.' : _error!,
            style: TextStyle(
              color: isNotAsisten ? Colors.grey.shade700 : Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!isNotAsisten)
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildBebasKpSection(),
          const SizedBox(height: 24),
          if (_laporan != null && _laporan!.labels.isNotEmpty) ...[
            const Text(
              'Grafik Kinerja',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF501F66),
              ),
            ),
            const SizedBox(height: 12),
            _buildModernChart(),
            const SizedBox(height: 24),
          ],
          const Text(
            'Jadwal Asisten',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF501F66),
            ),
          ),
          const SizedBox(height: 12),
          _buildJadwalSection(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final mhs = _info!.mahasiswa;

    return GlassCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _fotoUrl.isNotEmpty
                ? Image.network(
                    _fotoUrl,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 80,
                      color: const Color(0xFF501F66).withValues(alpha: 0.1),
                      child: const Icon(
                        CupertinoIcons.person_alt,
                        size: 40,
                        color: Color(0xFF501F66),
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 80,
                    color: const Color(0xFF501F66).withValues(alpha: 0.1),
                    child: const Icon(
                      CupertinoIcons.person_alt,
                      size: 40,
                      color: Color(0xFF501F66),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mhs.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${mhs.npm} • ${mhs.namaDept}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsRow() {
    final s = _info!.stats;
    return Row(
          children: [
            Expanded(
              child: _buildStatItem('Hadir', s.hadir.toString(), Colors.green),
            ),
            Expanded(
              child: _buildStatItem('Izin', s.izin.toString(), Colors.orange),
            ),
            Expanded(
              child: _buildStatItem(
                'Ganti',
                s.pengganti.toString(),
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem('Alpa', s.alpa.toString(), Colors.red),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildBebasKpSection() {
    final s = _info!.stats;
    final int totalKehadiran = s.hadir + s.pengganti;
    final int targetKehadiran = 200; // Minimal 200 kali mengajar

    double progress = (totalKehadiran / targetKehadiran).clamp(0.0, 1.0);
    bool isEligible = _info!.bisaAjukanBebasKP;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF501F66), const Color(0xFF8B4FA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF501F66).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Bebas KP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Untuk mengajukan Bebas KP, asisten harus mencapai target minimum kehadiran dan rata-rata evaluasi.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kehadiran', style: const TextStyle(color: Colors.white)),
              Text(
                '$totalKehadiran / $targetKehadiran',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.greenAccent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEligible ? _submitBebasKp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF501F66),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                disabledForegroundColor: const Color(
                  0xFF501F66,
                ).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEligible ? 'Ajukan Bebas KP' : 'Syarat Belum Terpenuhi',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLineChart() {
    if (_laporan == null || _laporan!.datasets.isEmpty) return const SizedBox();

    List<LineChartBarData> lines = [];
    double maxY = 0;

    final brightColors = [
      Colors.blueAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
    ];
    int datasetIndex = 0;

    for (var dataset in _laporan!.datasets) {
      if (dataset.type != 'line') continue;

      Color color = brightColors[datasetIndex % brightColors.length];
      datasetIndex++;
      List<FlSpot> spots = [];

      for (int i = 0; i < dataset.data.length; i++) {
        spots.add(FlSpot(i.toDouble(), dataset.data[i]));
        if (dataset.data[i] > maxY) maxY = dataset.data[i];
      }

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    // Adjust Y axis
    maxY = maxY > 0 ? maxY + 10 : 100;
    if (maxY > 100) maxY = 100; // Cap at 100 if it's a percentage

    return Container(
      height: 300,
      padding: const EdgeInsets.only(right: 16, left: 0, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < _laporan!.labels.length) {
                    // Extract only the part before the dash or short version to fit
                    String label = _laporan!.labels[idx];
                    if (label.contains('-')) {
                      // e.g. "2024/2025 - Ganjil" -> "24/25 Gjl"
                      var parts = label.split('-');
                      var thn = parts[0].trim().replaceAll('20', '');
                      var smt = parts[1].trim().substring(0, 3);
                      label = '$thn $smt';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (_laporan!.labels.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: lines,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              // getTooltipColor was changed to getTooltipColor in newer fl_chart versions, using the correct parameter for current version
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = TextStyle(
                    color: touchedSpot.bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  return LineTooltipItem('${touchedSpot.y}', textStyle);
                }).toList();
              },
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildModernChart() {
    return Column(
      children: [
        _buildLineChart(),
        const SizedBox(height: 16),
        _buildChartLegend(),
      ],
    );
  }

  Widget _buildChartLegend() {
    if (_laporan == null || _laporan!.datasets.isEmpty) return const SizedBox();

    final brightColors = [
      Colors.blueAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
    ];
    int datasetIndex = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _laporan!.datasets.where((d) => d.type == 'line').map((d) {
        final color = brightColors[datasetIndex % brightColors.length];
        datasetIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              d.label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildJadwalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tahunAkademikList.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AsistenTahunAkademik>(
                isExpanded: true,
                value: _selectedTahun,
                icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                items: _tahunAkademikList.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      '${t.thnAkademik} - ${t.semester == 1
                          ? 'Ganjil'
                          : t.semester == 2
                          ? 'Genap'
                          : 'Pendek'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedTahun) {
                    setState(() => _selectedTahun = val);
                    _loadJadwal();
                  }
                },
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

        const SizedBox(height: 16),

        if (_loadingJadwal)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF501F66)),
            ),
          )
        else if (_errorJadwal != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _errorJadwal!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (_jadwalList.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Tidak ada jadwal untuk periode ini',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ..._buildGroupedJadwal(),
      ],
    );
  }

  int _getHariWeight(String hari) {
    switch (hari.toUpperCase()) {
      case 'SENIN':
        return 1;
      case 'SELASA':
        return 2;
      case 'RABU':
        return 3;
      case 'KAMIS':
        return 4;
      case 'JUMAT':
        return 5;
      case 'SABTU':
        return 6;
      case 'MINGGU':
        return 7;
      default:
        return 99;
    }
  }

  Future<void> _addToGoogleCalendar(AsistenJadwal item) async {
    final title = Uri.encodeComponent('Asisten: ${item.mkl}');
    final details = Uri.encodeComponent(
      'Dosen: ${item.dosen}\\nSKS: ${item.sks}\\nHari: ${item.hari}, Jam: ${item.jam}',
    );
    final location = Uri.encodeComponent(item.ruang);

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&details=$details&location=$location',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Calendar')),
        );
      }
    }
  }

  List<Widget> _buildGroupedJadwal() {
    final grouped = <String, List<AsistenJadwal>>{};
    for (var j in _jadwalList) {
      grouped.putIfAbsent(j.hari.toUpperCase(), () => []).add(j);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _getHariWeight(a).compareTo(_getHariWeight(b)));

    if (sortedKeys.isEmpty) return [];
    if (_selectedHari == null || !sortedKeys.contains(_selectedHari)) {
      _selectedHari = sortedKeys.first;
    }

    List<Widget> widgets = [];

    widgets.add(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sortedKeys.map((hari) {
            final isSelected = hari == _selectedHari;
            return GestureDetector(
              onTap: () => setState(() => _selectedHari = hari),
              child: AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.only(right: 8, bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF501F66) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF501F66)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF501F66,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  hari,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ).animate().fadeIn(delay: 400.ms),
    );

    int delayIdx = 0;
    final items = grouped[_selectedHari] ?? [];

    for (var item in items) {
      widgets.add(
        Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF501F66,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.kode,
                            style: const TextStyle(
                              color: Color(0xFF501F66),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.sks} SKS',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.mkl,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.clock,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.jam,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          CupertinoIcons.location,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.ruang,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _addToGoogleCalendar(item),
                      icon: const Icon(
                        CupertinoIcons.calendar_badge_plus,
                        size: 16,
                        color: Color(0xFF501F66),
                      ),
                      label: const Text(
                        'Add to Google Calendar',
                        style: TextStyle(
                          color: Color(0xFF501F66),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (400 + (delayIdx * 50)).ms)
            .slideY(begin: 0.1, end: 0),
      );
      delayIdx++;
    }
    return widgets;
  }
}

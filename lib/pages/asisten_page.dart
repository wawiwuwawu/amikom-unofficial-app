import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/asisten.dart';
import '../services/asisten_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Asisten Praktikum — identitas asisten, rekap kehadiran, status Bebas KP,
/// grafik kinerja, dan jadwal mengajar.
///
/// Susunan tampilan (dari atas ke bawah), supaya terbaca sekali gulir:
///   1. identitas (kartu sorotan);
///   2. ringkasan kehadiran sebagai [AppStatTile] — angka, bukan kartu;
///   3. status Bebas KP (banner + progres + aksi);
///   4. grafik kinerja per semester;
///   5. jadwal mengajar: pemilih tahun akademik → pemilih hari → daftar kelas
///      dalam satu grup ([AppListGroup] + [AppListRow]), bukan satu kartu per
///      mata kuliah.
///
/// Tombol kembali disediakan otomatis oleh [AppScaffold] mengikuti route,
/// sehingga `onBack` hanya dipertahankan untuk kompatibilitas pemanggil lama.
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

  /// Warna seri grafik — diambil dari token semantik, bukan warna Material mentah.
  static const List<Color> _chartColors = [
    AppColors.primary,
    AppColors.info,
    AppColors.warning,
    AppColors.success,
  ];

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
        final dash = await ApiClient.instance.getDashboard();
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
            backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Asisten Praktikum',
      subtitle: 'Rekap kehadiran & jadwal mengajar',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(message: 'Memuat data asisten…');

    final error = _error;
    if (error != null) return _buildErrorState(error);

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          _buildProfileCard(),
          _buildStatsSection(),
          _buildBebasKpSection(),
          if (_laporan != null && _laporan!.labels.isNotEmpty)
            AppSection(title: 'Grafik Kinerja', child: _buildModernChart()),
          AppSection(title: 'Jadwal Asisten', child: _buildJadwalSection()),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isNotAsisten =
        error.toLowerCase().contains('bukan asisten') ||
        error.toLowerCase().contains('not found');

    if (isNotAsisten) {
      return const AppEmptyState(
        title: 'Kamu bukan asisten praktikum.',
        message: 'Menu ini hanya bisa dibuka oleh mahasiswa '
            'yang terdaftar sebagai asisten praktikum.',
        icon: CupertinoIcons.person_crop_circle_badge_xmark,
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.page,
        child: AppErrorState(message: error, onRetry: _loadAllData),
      ),
    );
  }

  // ── Identitas asisten ──────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    final mhs = _info!.mahasiswa;

    return AppSurface(
      variant: AppSurfaceVariant.hero,
      radius: AppRadius.lg,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: _fotoUrl.isNotEmpty
                ? Image.network(
                    _fotoUrl,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _fotoPlaceholder(),
                  )
                : _fotoPlaceholder(),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mhs.nama, style: AppText.h2),
                const SizedBox(height: AppSpacing.xs),
                Text('${mhs.npm} • ${mhs.namaDept}', style: AppText.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      width: 60,
      height: 80,
      alignment: Alignment.center,
      decoration: AppDeco.card(radius: AppRadius.sm),
      child: const Icon(
        CupertinoIcons.person_alt,
        size: 36,
        color: AppColors.primary,
      ),
    );
  }

  // ── Ringkasan kehadiran (angka, bukan kartu per item) ──────────────────────

  Widget _buildStatsSection() {
    final s = _info!.stats;

    return AppSection(
      title: 'Ringkasan Kehadiran',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppStatTile(
              value: s.hadir.toString(),
              label: 'Hadir',
              icon: Icons.check_circle_outline,
              accent: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppStatTile(
              value: s.izin.toString(),
              label: 'Izin',
              icon: Icons.event_busy_outlined,
              accent: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppStatTile(
              value: s.pengganti.toString(),
              label: 'Ganti',
              icon: Icons.swap_horiz,
              accent: AppColors.info,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppStatTile(
              value: s.alpa.toString(),
              label: 'Alpa',
              icon: Icons.cancel_outlined,
              accent: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Bebas KP (banner + progres + aksi) ──────────────────────────────

  Widget _buildBebasKpSection() {
    final s = _info!.stats;
    final int totalKehadiran = s.hadir + s.pengganti;
    final int targetKehadiran = 200; // Minimal 200 kali mengajar

    final double progress = (totalKehadiran / targetKehadiran).clamp(0.0, 1.0);
    final bool isEligible = _info!.bisaAjukanBebasKP;
    final Color progressColor = isEligible
        ? AppColors.success
        : AppColors.primary;

    return AppSection(
      title: 'Status Bebas KP',
      child: AppSurface(
        variant: AppSurfaceVariant.hero,
        radius: AppRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk mengajukan Bebas KP, asisten harus mencapai target minimum kehadiran dan rata-rata evaluasi.',
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kehadiran', style: AppText.label),
                Text(
                  '$totalKehadiran / $targetKehadiran',
                  style: AppText.h3.copyWith(color: progressColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: progressColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isEligible ? _submitBebasKp : null,
                child: Text(
                  isEligible ? 'Ajukan Bebas KP' : 'Syarat Belum Terpenuhi',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grafik kinerja ─────────────────────────────────────────────────────────

  Widget _buildModernChart() {
    return Column(
      children: [
        _buildLineChart(),
        const SizedBox(height: AppSpacing.lg),
        _buildChartLegend(),
      ],
    );
  }

  Widget _buildLineChart() {
    if (_laporan == null || _laporan!.datasets.isEmpty) {
      return const SizedBox.shrink();
    }

    List<LineChartBarData> lines = [];
    double maxY = 0;

    int datasetIndex = 0;

    for (var dataset in _laporan!.datasets) {
      if (dataset.type != 'line') continue;

      Color color = _chartColors[datasetIndex % _chartColors.length];
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
                color: AppColors.surface,
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

    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.only(
        right: AppSpacing.lg,
        top: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) =>
                  const FlLine(color: AppColors.border, strokeWidth: 1),
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
                          style: AppText.label.copyWith(
                            fontSize: 10,
                            color: AppColors.textMuted,
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
                      style: AppText.label.copyWith(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
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
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final textStyle = AppText.label.copyWith(
                      color: touchedSpot.bar.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    );
                    return LineTooltipItem('${touchedSpot.y}', textStyle);
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    if (_laporan == null || _laporan!.datasets.isEmpty) {
      return const SizedBox.shrink();
    }

    int datasetIndex = 0;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: _laporan!.datasets.where((d) => d.type == 'line').map((d) {
        final color = _chartColors[datasetIndex % _chartColors.length];
        datasetIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              d.label,
              style: AppText.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Jadwal mengajar ────────────────────────────────────────────────────────

  Widget _buildJadwalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tahunAkademikList.isNotEmpty) _buildTahunDropdown(),
        const SizedBox(height: AppSpacing.lg),
        if (_loadingJadwal)
          const AppLoading(message: 'Memuat jadwal…')
        else if (_errorJadwal != null)
          AppErrorState(message: _errorJadwal!, onRetry: _loadJadwal)
        else if (_jadwalList.isEmpty)
          const AppEmptyState(
            title: 'Tidak ada jadwal untuk periode ini',
            icon: CupertinoIcons.calendar,
          )
        else
          ..._buildGroupedJadwal(),
      ],
    );
  }

  /// Pemilih tahun akademik — memakai tema input global (AppDeco + AppText),
  /// bukan warna/border yang ditulis ulang di halaman.
  Widget _buildTahunDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDeco.card(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AsistenTahunAkademik>(
          isExpanded: true,
          value: _selectedTahun,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: AppColors.textMuted,
          ),
          items: _tahunAkademikList.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(
                '${t.thnAkademik} - ${t.semester == 1
                    ? 'Ganjil'
                    : t.semester == 2
                    ? 'Genap'
                    : 'Pendek'}',
                style: AppText.body,
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

  /// Pemilih hari (pil) + daftar kelas hari terpilih dalam SATU grup baris,
  /// supaya jadwal bisa dipindai tanpa menggulir kartu demi kartu.
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

    final items = grouped[_selectedHari] ?? [];

    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final hari in sortedKeys) ...[
              _hariChip(hari),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AppListGroup.from([
        for (final item in items) _jadwalRow(item),
      ]),
    ];
  }

  Widget _hariChip(String hari) {
    final isSelected = hari == _selectedHari;
    return ChoiceChip(
      label: Text(hari),
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: isSelected
          ? BorderSide.none
          : const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelStyle: AppText.label.copyWith(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedHari = hari);
      },
    );
  }

  Widget _jadwalRow(AsistenJadwal item) {
    final keterangan = <String>[
      if (item.kode.isNotEmpty) item.kode,
      if (item.ruang.isNotEmpty) item.ruang,
      if (item.dosen.isNotEmpty) item.dosen,
    ].join(' • ');

    return AppListRow(
      // Jam jadi info depan: yang pertama dicari saat melihat jadwal mengajar.
      leading: Container(
        width: 64,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Text(
          item.jam.isEmpty ? '-' : item.jam,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: item.mkl.isEmpty ? '-' : item.mkl,
      subtitle: keterangan.isEmpty ? null : keterangan,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill('${item.sks} SKS', tone: AppPillTone.info),
          IconButton(
            tooltip: 'Add to Google Calendar',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 18,
              color: AppColors.primary,
            ),
            onPressed: () => _addToGoogleCalendar(item),
          ),
        ],
      ),
    );
  }
}

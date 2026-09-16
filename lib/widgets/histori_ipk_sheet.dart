import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/histori_ipk.dart';
import '../services/transkrip_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

void showHistoriIpkBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const HistoriIpkSheet(),
  );
}

/// Sheet analitik tren IPK.
///
/// Redesign memakai design system:
///   * ringkasan IPK/SKS memakai [AppStatTile];
///   * grafik tetap memakai `fl_chart` (konten visual → dibungkus
///     [AppSurface]), hanya warna sumbu/garis yang diambil dari token;
///   * tiap semester jadi baris [AppListRow] dalam satu [AppListGroup] —
///     semester sebagai title, IPK sebagai nilai `AppText.metric`, delta
///     semester sebagai [AppPill];
///   * keadaan memuat / galat memakai [AppLoading] dan [AppErrorState].
/// Seluruh perhitungan, pemanggilan service, dan nilai yang ditampilkan sama.
class HistoriIpkSheet extends StatefulWidget {
  const HistoriIpkSheet({super.key});

  @override
  State<HistoriIpkSheet> createState() => _HistoriIpkSheetState();
}

class _HistoriIpkSheetState extends State<HistoriIpkSheet> {
  final _service = TranskripService();
  HistoriIpkData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getHistoriIpk();
      if (mounted) {
        setState(() {
          _data = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              const Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Analitik Tren IPK', style: AppText.h2),
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: _loading
                ? const AppLoading()
                : _error != null
                    ? Center(
                        child: AppErrorState(
                          message: _error!,
                          onRetry: _fetch,
                        ),
                      )
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final trendList = d.trendSemester;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Ringkasan
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                value: d.ipkTerakhir.toStringAsFixed(2),
                label: 'IPK Kumulatif',
                icon: CupertinoIcons.chart_bar_alt_fill,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatTile(
                value: '${d.totalSksLulus} SKS',
                label: 'Total SKS Lulus',
                icon: CupertinoIcons.book_fill,
                accent: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Grafik tren (konten visual → kartu)
        if (trendList.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Grafik Perkembangan IPK & IPS', style: AppText.h2),
          const SizedBox(height: AppSpacing.md),
          _buildLineChart(trendList),
        ],

        // Histori per semester (data dibaca/dibandingkan → list)
        const SizedBox(height: AppSpacing.xl),
        Text('Histori Nilai per Semester', style: AppText.h2),
        const SizedBox(height: AppSpacing.md),
        if (trendList.isEmpty)
          const AppEmptyState(
            title: 'Belum ada histori IPK',
            message: 'Data tren semester belum tersedia.',
            icon: CupertinoIcons.chart_bar_alt_fill,
          )
        else
          AppListGroup.from([
            for (var i = 0; i < trendList.length; i++)
              _buildSemesterCard(trendList[i], i),
          ]),
      ],
    );
  }

  Widget _buildLineChart(List<TrendSemesterItem> list) {
    final spotsIpk = <FlSpot>[];
    final spotsIps = <FlSpot>[];

    for (int i = 0; i < list.length; i++) {
      spotsIpk.add(FlSpot(i.toDouble(), list[i].ipkKumulatif));
      spotsIps.add(FlSpot(i.toDouble(), list[i].ips));
    }

    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 220,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'IPK',
                      style: AppText.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'IPS',
                      style: AppText.label.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1.0,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            val.toStringAsFixed(1),
                            style: AppText.label.copyWith(
                              color: AppColors.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1.0,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < list.length) {
                            return Text(
                              'Smt ${list[idx].semester}',
                              style: AppText.label.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (list.length - 1).toDouble(),
                  minY: 0,
                  maxY: 4.0,
                  lineBarsData: [
                    // IPK Line
                    LineChartBarData(
                      spots: spotsIpk,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    // IPS Line
                    LineChartBarData(
                      spots: spotsIps,
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final label = spot.barIndex == 0 ? 'IPK' : 'IPS';
                          return LineTooltipItem(
                            '$label: ${spot.y.toStringAsFixed(2)}',
                            AppText.label.copyWith(
                              color: spot.bar.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterCard(TrendSemesterItem item, int index) {
    final AppPillTone deltaTone;
    final String deltaText;

    if (item.delta > 0) {
      deltaTone = AppPillTone.success;
      deltaText = '+${item.delta.toStringAsFixed(2)}';
    } else if (item.delta < 0) {
      deltaTone = AppPillTone.danger;
      deltaText = item.delta.toStringAsFixed(2);
    } else {
      deltaTone = AppPillTone.neutral;
      deltaText = '0.00';
    }

    return AppListRow(
      leading: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Text(
          '${item.semester}',
          style: AppText.h3.copyWith(color: AppColors.primary),
        ),
      ),
      title: 'Semester ${item.semester} (${item.tahunAkademik})',
      subtitle: 'IPS: ${item.ips.toStringAsFixed(2)} • ${item.sksSemester} SKS',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.ipkKumulatif.toStringAsFixed(2),
                style: AppText.metric.copyWith(fontSize: 18),
              ),
              Text('IPK', style: AppText.label),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          AppPill(deltaText, tone: deltaTone),
        ],
      ),
    );
  }
}

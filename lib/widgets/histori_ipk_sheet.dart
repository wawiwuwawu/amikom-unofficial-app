import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/histori_ipk.dart';
import '../services/transkrip_service.dart';
import 'glass_card.dart';

void showHistoriIpkBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const HistoriIpkSheet(),
  );
}

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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(CupertinoIcons.chart_bar_alt_fill, color: Color(0xFF501F66), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Analitik Tren IPK',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF501F66)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetch,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
                              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                            ),
                          ],
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
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('IPK Kumulatif', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      d.ipkTerakhir.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total SKS Lulus', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${d.totalSksLulus} SKS',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(),
        const SizedBox(height: 20),

        // Line Chart if trend items > 0
        if (trendList.isNotEmpty) ...[
          const Text('Grafik Perkembangan IPK & IPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF501F66))),
          const SizedBox(height: 12),
          _buildLineChart(trendList),
          const SizedBox(height: 24),
        ],

        // Semester Trend Breakdown List
        const Text('Histori Nilai per Semester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF501F66))),
        const SizedBox(height: 12),
        ...List.generate(trendList.length, (index) {
          final item = trendList[index];
          return _buildSemesterCard(item, index);
        }),
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

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 16, 20, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF501F66).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF501F66).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF501F66), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('IPK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF1976D2), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('IPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
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
                    color: const Color(0xFF501F66),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF501F66).withValues(alpha: 0.1),
                    ),
                  ),
                  // IPS Line
                  LineChartBarData(
                    spots: spotsIps,
                    isCurved: true,
                    color: const Color(0xFF1976D2),
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
                          TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold, fontSize: 12),
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
    ).animate().fadeIn();
  }

  Widget _buildSemesterCard(TrendSemesterItem item, int index) {
    Color deltaColor;
    IconData deltaIcon;
    String deltaText;

    if (item.delta > 0) {
      deltaColor = Colors.green;
      deltaIcon = CupertinoIcons.arrow_up_right;
      deltaText = '+${item.delta.toStringAsFixed(2)}';
    } else if (item.delta < 0) {
      deltaColor = Colors.red;
      deltaIcon = CupertinoIcons.arrow_down_right;
      deltaText = item.delta.toStringAsFixed(2);
    } else {
      deltaColor = Colors.grey;
      deltaIcon = CupertinoIcons.minus;
      deltaText = '0.00';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 14,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF501F66).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${item.semester}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semester ${item.semester} (${item.tahunAkademik})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('IPS: ${item.ips.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1976D2))),
                      const SizedBox(width: 12),
                      Text('IPK: ${item.ipkKumulatif.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(width: 12),
                      Text('${item.sksSemester} SKS', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: deltaColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(deltaIcon, size: 12, color: deltaColor),
                  const SizedBox(width: 2),
                  Text(
                    deltaText,
                    style: TextStyle(color: deltaColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (40 * index).ms);
  }
}

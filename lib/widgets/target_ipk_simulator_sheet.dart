import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transkrip.dart';
import '../services/transkrip_service.dart';
import 'glass_card.dart';

void showTargetIpkSimulatorBottomSheet(BuildContext context, {double? initialTarget}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TargetIpkSimulatorSheet(initialTarget: initialTarget ?? 3.75),
  );
}

class TargetIpkSimulatorSheet extends StatefulWidget {
  final double initialTarget;

  const TargetIpkSimulatorSheet({super.key, required this.initialTarget});

  @override
  State<TargetIpkSimulatorSheet> createState() => _TargetIpkSimulatorSheetState();
}

class _TargetIpkSimulatorSheetState extends State<TargetIpkSimulatorSheet> {
  final _service = TranskripService();
  late double _targetIpk;
  bool _loading = false;
  String? _error;
  SimulasiIpkData? _data;

  @override
  void initState() {
    super.initState();
    _targetIpk = widget.initialTarget;
    _runSimulasi(_targetIpk);
  }

  Future<void> _runSimulasi(double target) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.simulasiTargetIpk(target);
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
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFCFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handlebar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF501F66).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.scope, color: Color(0xFF501F66), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Simulasi Target IPK Kelulusan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF501F66),
                            ),
                          ),
                          Text(
                            'Kalkulator Bebas IPS Sisa SKS',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Target Display Card
                    GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'TARGET IPK IMPIAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _targetIpk.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF501F66),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF501F66),
                              inactiveTrackColor: Colors.grey.shade200,
                              thumbColor: const Color(0xFF501F66),
                              overlayColor: const Color(0xFF501F66).withValues(alpha: 0.1),
                              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                              valueIndicatorColor: const Color(0xFF501F66),
                              valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            child: Slider(
                              value: _targetIpk,
                              min: 2.50,
                              max: 4.00,
                              divisions: 30,
                              label: _targetIpk.toStringAsFixed(2),
                              onChanged: (val) {
                                setState(() => _targetIpk = double.parse(val.toStringAsFixed(2)));
                              },
                              onChangeEnd: (val) {
                                _runSimulasi(double.parse(val.toStringAsFixed(2)));
                              },
                            ),
                          ),

                          // Presets Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [3.50, 3.75, 3.85, 4.00].map((preset) {
                              final selected = _targetIpk == preset;
                              return InkWell(
                                onTap: () {
                                  setState(() => _targetIpk = preset);
                                  _runSimulasi(preset);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFF501F66) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? const Color(0xFF501F66) : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    preset.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(duration: 300.ms),
                    const SizedBox(height: 24),

                    // Results Card
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF501F66)),
                        ),
                      )
                    else if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    else if (_data != null) ...[
                      _buildSimulasiResultCard(_data!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimulasiResultCard(SimulasiIpkData d) {
    final isPossible = d.isAchievable;
    final cardColor = isPossible ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final borderColor = isPossible ? Colors.green.shade300 : Colors.red.shade300;
    final textColor = isPossible ? Colors.green.shade900 : Colors.red.shade900;
    final primaryBadgeColor = isPossible ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPossible ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.xmark_circle_fill,
                color: primaryBadgeColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPossible ? 'DAPAT DICAPAI (ACHIEVABLE)' : 'TIDAK MEMUNGKINKAN (> 4.00)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: primaryBadgeColor,
                      ),
                    ),
                    Text(
                      'IPK Saat Ini: ${d.ipkSaatIni.toStringAsFixed(2)} • Sisa SKS: ${d.sisaSks}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wajib IPS Rata-Rata Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Text(
                  'WAJIB IPS RATA-RATA DIBUTUHKAN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  d.wajibIpsRataRata.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isPossible ? const Color(0xFF501F66) : Colors.red.shade700,
                  ),
                ),
                const Text(
                  'pada seluruh sisa SKS yang akan diambil',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Analisis Kalimat
          Text(
            d.analisisKalimat,
            style: TextStyle(
              fontSize: 12.5,
              color: textColor,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0);
  }
}

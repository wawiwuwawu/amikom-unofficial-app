import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/transkrip.dart';
import '../services/transkrip_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

void showTargetIpkSimulatorBottomSheet(BuildContext context, {double? initialTarget}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TargetIpkSimulatorSheet(initialTarget: initialTarget ?? 3.75),
  );
}

/// Sheet simulasi target IPK.
///
/// Redesign memakai design system:
///   * header memakai token warna/teks, target ditampilkan sebagai
///     `AppText.metric` di dalam [AppSurface];
///   * slider & field memakai tema global (tanpa `SliderTheme` lokal);
///   * presets memakai `AppPill`-style pilihan yang mengikuti token;
///   * hasil simulasi memakai [AppSurface] success/danger + [AppKeyValue].
/// Seluruh perhitungan simulasi, pemanggilan service, dan state tidak berubah.
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
            color: AppColors.scaffold,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            children: [
              // Handlebar
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: AppDeco.softPrimary(),
                      child: const Icon(
                        CupertinoIcons.scope,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simulasi Target IPK Kelulusan',
                            style: AppText.h2,
                          ),
                          Text('Kalkulator Bebas IPS Sisa SKS', style: AppText.label),
                        ],
                      ),
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
              ),
              const Divider(height: 1),

              // Body Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    // Target Display Card
                    AppSurface(
                      radius: AppRadius.lg,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          Text('TARGET IPK IMPIAN', style: AppText.overline),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _targetIpk.toStringAsFixed(2),
                            style: AppText.metric.copyWith(fontSize: 44),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Slider — memakai tema global
                          Slider(
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

                          // Presets Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [3.50, 3.75, 3.85, 4.00].map((preset) {
                              final selected = _targetIpk == preset;
                              return InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                onTap: () {
                                  setState(() => _targetIpk = preset);
                                  _runSimulasi(preset);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    preset.toStringAsFixed(2),
                                    style: AppText.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Hasil simulasi
                    if (_loading)
                      const AppLoading()
                    else if (_error != null)
                      AppErrorState(message: _error!, onRetry: () => _runSimulasi(_targetIpk))
                    else if (_data != null)
                      _buildSimulasiResultCard(_data!),
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
    final accent = isPossible ? AppColors.success : AppColors.danger;

    return AppSurface(
      variant: isPossible ? AppSurfaceVariant.success : AppSurfaceVariant.danger,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPossible
                    ? CupertinoIcons.checkmark_alt_circle_fill
                    : CupertinoIcons.xmark_circle_fill,
                color: accent,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPossible ? 'DAPAT DICAPAI (ACHIEVABLE)' : 'TIDAK MEMUNGKINKAN (> 4.00)',
                      style: AppText.h3.copyWith(color: accent),
                    ),
                    Text(
                      'IPK Saat Ini: ${d.ipkSaatIni.toStringAsFixed(2)} • Sisa SKS: ${d.sisaSks}',
                      style: AppText.bodySm,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Wajib IPS Rata-Rata
          AppSurface(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text('WAJIB IPS RATA-RATA DIBUTUHKAN', style: AppText.overline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  d.wajibIpsRataRata.toStringAsFixed(2),
                  style: AppText.metric.copyWith(
                    fontSize: 32,
                    color: isPossible ? AppColors.primary : AppColors.danger,
                  ),
                ),
                Text(
                  'pada seluruh sisa SKS yang akan diambil',
                  style: AppText.label.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Analisis Kalimat
          Text(
            d.analisisKalimat,
            style: AppText.bodySm.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

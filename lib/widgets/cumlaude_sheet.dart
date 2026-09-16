import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/transkrip.dart';
import '../pages/sp_page.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

void showCumlaudeBottomSheet(BuildContext context, CumlaudeData data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CumlaudeSheet(data: data),
  );
}

/// Sheet evaluasi kelayakan cumlaude.
///
/// Redesign memakai design system:
///   * header & handlebar memakai token; banner proyeksi predikat memakai
///     [AppSurface] variant + [AppPill] status;
///   * 4 syarat akademik jadi baris [AppListRow] dalam satu [AppListGroup] —
///     syarat sebagai title, keterangan sebagai subtitle, status sebagai
///     [AppPill] terpenuhi/belum;
///   * matakuliah yang perlu perbaikan memakai [AppListGroup] + [AppGradeBadge];
///   * rekomendasi tindakan dibungkus [AppSurface].
/// Seluruh perhitungan, kondisi, dan navigasi tidak berubah.
class CumlaudeSheet extends StatelessWidget {
  final CumlaudeData data;

  const CumlaudeSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isCumlaude = data.isCumlaudeEligible;
    final accent = isCumlaude ? AppColors.warning : AppColors.info;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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
                      child: Icon(
                        isCumlaude ? CupertinoIcons.rosette : CupertinoIcons.chart_bar_alt_fill,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Evaluasi Kelayakan Cumlaude', style: AppText.h2),
                          Text('Analisis Predikat & Syarat Akademis', style: AppText.label),
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
                    // Banner Proyeksi Predikat (konten visual → kartu)
                    AppSurface(
                      variant: isCumlaude
                          ? AppSurfaceVariant.warning
                          : AppSurfaceVariant.hero,
                      radius: AppRadius.lg,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isCumlaude
                                      ? '🎓 Proyeksi: Cumlaude'
                                      : 'Proyeksi: ${data.predikatSaatIni}',
                                  style: AppText.h2.copyWith(color: accent),
                                ),
                              ),
                              AppPill(
                                isCumlaude ? 'ELIGIBLE' : 'REGULER',
                                tone: isCumlaude
                                    ? AppPillTone.warning
                                    : AppPillTone.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: AppStatTile(
                                  value: data.ipkTerakhir.toStringAsFixed(2),
                                  label: 'IPK',
                                  accent: accent,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppStatTile(
                                  value: '${data.totalSksLulus} SKS',
                                  label: 'SKS Lulus',
                                  accent: accent,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppStatTile(
                                  value: '${data.semesterSaatIni}',
                                  label: 'Semester',
                                  accent: accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Checklist 4 Syarat Akademik
                    AppSection(
                      title: 'Checklist 4 Syarat Cumlaude',
                      topGap: 0,
                      child: AppListGroup.from([
                        // Syarat 1: IPK
                        _buildSyaratItem(
                          title: 'Syarat IPK (${data.analisisSyarat.syaratIpk.target})',
                          detail: data.analisisSyarat.syaratIpk,
                          icon: CupertinoIcons.star_fill,
                        ),
                        // Syarat 2: Masa Studi
                        _buildSyaratItem(
                          title:
                              'Syarat Masa Studi (${data.analisisSyarat.syaratMasaStudi.target})',
                          detail: data.analisisSyarat.syaratMasaStudi,
                          icon: CupertinoIcons.time_solid,
                        ),
                        // Syarat 3: Status Masuk
                        _buildSyaratItem(
                          title:
                              'Syarat Status Masuk (${data.analisisSyarat.syaratStatusMasuk.target})',
                          detail: data.analisisSyarat.syaratStatusMasuk,
                          icon: CupertinoIcons.person_badge_plus_fill,
                        ),
                        // Syarat 4: Nilai Minimum
                        _buildSyaratItem(
                          title:
                              'Syarat Nilai Minimum (${data.analisisSyarat.syaratNilaiMinimum.target})',
                          detail: SyaratDetail(
                            isFulfilled: data.analisisSyarat.syaratNilaiMinimum.isFulfilled,
                            currentVal:
                                '${data.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount} pelanggaran',
                            target: data.analisisSyarat.syaratNilaiMinimum.target,
                            description:
                                data.analisisSyarat.syaratNilaiMinimum.description,
                          ),
                          icon: CupertinoIcons.exclamationmark_shield_fill,
                        ),
                      ]),
                    ),

                    // Matakuliah Perlu Perbaikan (Nilai < B-)
                    if (data.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount > 0) ...[
                      AppSection(
                        title:
                            'Matakuliah Perlu Perbaikan (${data.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount} Matkul)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppListGroup.from([
                              for (final m
                                  in data.analisisSyarat.syaratNilaiMinimum.violatingMatkul)
                                AppListRow(
                                  leading: AppGradeBadge(grade: m.nilai, size: 30),
                                  title: '${m.kode} - ${m.mkl}',
                                  subtitle: '${m.sks} SKS',
                                ),
                            ]),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // Close bottom sheet
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SpPage(),
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(CupertinoIcons.layers_alt_fill, size: 16),
                                label: const Text('Perbaiki via Semester Pendek (SP)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Rekomendasi Tindakan
                    if (data.rekomendasiTindakan.isNotEmpty)
                      AppSection(
                        title: 'Rekomendasi Langkah / Tindakan',
                        child: AppSurface(
                          variant: AppSurfaceVariant.warning,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.lightbulb_fill,
                                    color: AppColors.warning,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Rekomendasi Langkah / Tindakan:',
                                      style: AppText.h3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              for (final saran in data.rekomendasiTindakan)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: AppText.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(saran, style: AppText.bodySm),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyaratItem({
    required String title,
    required SyaratDetail detail,
    required IconData icon,
  }) {
    final isOk = detail.isFulfilled;

    return AppListRow(
      leading: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Icon(
          isOk ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.xmark_circle_fill,
          color: isOk ? AppColors.success : AppColors.danger,
          size: 20,
        ),
      ),
      title: title,
      subtitle: detail.description,
      trailing: AppPill(
        isOk ? 'Terpenuhi' : 'Belum Terpenuhi',
        tone: isOk ? AppPillTone.success : AppPillTone.danger,
      ),
    );
  }
}

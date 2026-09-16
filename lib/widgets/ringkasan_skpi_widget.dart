import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transkrip.dart';
import '../pages/sertifikasi_page.dart';
import '../pages/prestasi_page.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

class RingkasanSkpiWidget extends StatelessWidget {
  final SkpiData data;

  const RingkasanSkpiWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isEligible = data.isSkpiEligible;
    final poin = data.skkmPoinInfo.estimasiPoinSkkm;
    final pct = (poin / 100.0).clamp(0.0, 1.0);
    final accent = isEligible ? AppColors.success : AppColors.warning;

    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  isEligible
                      ? CupertinoIcons.doc_checkmark_fill
                      : CupertinoIcons.exclamationmark_circle_fill,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kecukupan SKPI & Poin SKKM', style: AppText.h3),
                    const SizedBox(height: 2),
                    Text(
                      data.statusSkpi,
                      style: AppText.label.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppPill(
                isEligible ? 'LULUS SKPI' : '$poin / 100 POIN',
                tone: isEligible ? AppPillTone.success : AppPillTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress Bar SKKM
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.skkmPoinInfo.description,
            style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
          ),

          // Peringatan Kekurangan (If any)
          if (data.peringatanKekurangan.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              variant: AppSurfaceVariant.warning,
              radius: AppRadius.sm,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.info_circle_fill,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Perhatian Tambahan SKPI:',
                          style: AppText.label.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final warn in data.peringatanKekurangan)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $warn',
                        style: AppText.bodySm.copyWith(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Quick Actions Row
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SertifikasiPage(onBack: () => Navigator.pop(context)),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.doc_append, size: 14, color: Colors.white),
                  label: Text(
                    'Input Sertifikasi',
                    style: AppText.label.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrestasiPage(onBack: () => Navigator.pop(context)),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.star_fill, size: 14, color: AppColors.primary),
                  label: Text(
                    'Input Prestasi',
                    style: AppText.label.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }
}

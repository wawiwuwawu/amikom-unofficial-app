import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transkrip.dart';
import '../pages/sp_page.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

class ProgressKelulusanCard extends StatefulWidget {
  final ProgressKelulusanData data;

  const ProgressKelulusanCard({super.key, required this.data});

  @override
  State<ProgressKelulusanCard> createState() => _ProgressKelulusanCardState();
}

class _ProgressKelulusanCardState extends State<ProgressKelulusanCard> {
  int _selectedJalur = 0; // 0: Skripsi Reguler, 1: Technopreneur IT

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final pct = (d.persentaseKelulusan / 100.0).clamp(0.0, 1.0);
    final wisuda = d.kelayakanAkademikWisuda;
    final jalur = d.jalurKelulusan;

    return AppSurface(
      variant: AppSurfaceVariant.hero,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: AppDeco.softPrimary(),
                child: const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Kelulusan & Wisuda', style: AppText.h3),
                    const SizedBox(height: 2),
                    Text(
                      '${d.prodi} (${d.jenjang})',
                      style: AppText.label.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${d.persentaseKelulusan.toStringAsFixed(1)}%',
                  style: AppText.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Stats — Wrap: turun baris sendiri di layar sempit (tidak overflow)
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${d.totalSksLulus} / ${d.targetSks} SKS Lulus',
                style: AppText.h3.copyWith(fontSize: 13),
              ),
              Text(
                'Sisa ${d.sisaSks} SKS • ~${d.estimasiSisaSemester} Smt Lg',
                style: AppText.label.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),

          // Wisuda Eligibility Warning (If D/E exists)
          if (!wisuda.bebasNilaiDEEligible && wisuda.warningWisuda.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
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
                        CupertinoIcons.exclamationmark_triangle_fill,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Syarat Bebas Nilai D/E Wisuda',
                          style: AppText.h3.copyWith(
                            fontSize: 13,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    wisuda.warningWisuda,
                    style: AppText.bodySm.copyWith(height: 1.35),
                  ),
                  if (wisuda.dEMatkulItems.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ...wisuda.dEMatkulItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${item.kode} - ${item.mkl} (${item.sks} SKS): Nilai ${item.nilai}',
                          style: AppText.label.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpPage(onBack: () => Navigator.pop(context)),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.layers_alt_fill, size: 14),
                        label: Text(
                          'Daftar Semester Pendek (SP)',
                          style: AppText.label.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Segmented Control Jalur Kelulusan
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(child: _jalurTab(0, '📘 Skripsi Reguler')),
                Expanded(child: _jalurTab(1, '🚀 Technopreneur IT')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Content based on Selected Jalur
          if (_selectedJalur == 0) ...[
            // Skripsi Reguler
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _statusCheckBadge('PKL / Magang', jalur.skripsiReguler.pklEligible),
                _statusCheckBadge('Skripsi', jalur.skripsiReguler.skripsiEligible),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              jalur.skripsiReguler.skripsiEligible
                  ? 'Anda sudah memenuhi syarat untuk mengajukan Skripsi.'
                  : 'Membutuhkan ${jalur.skripsiReguler.sisaSksMenujuSkripsi} SKS lagi menuju pengajuan Skripsi.',
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ] else ...[
            // Technopreneur IT
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _statusCheckBadge('SKS & IPK (>=140 SKS)', jalur.technopreneurIt.eligibleSksIpk),
                Text(
                  'Sisa ${jalur.technopreneurIt.sisaSksMenuju140} SKS',
                  style: AppText.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Syarat Tambahan Jalur Startup:',
              style: AppText.h3.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...jalur.technopreneurIt.syaratTambahan.map(
              (syarat) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        CupertinoIcons.smallcircle_fill_circle,
                        size: 10,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        syarat,
                        style: AppText.bodySm.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  /// Tab jalur kelulusan (segmented) — Expanded di parent, jadi aman di layar sempit.
  Widget _jalurTab(int index, String label) {
    final selected = _selectedJalur == index;
    return InkWell(
      onTap: () => setState(() => _selectedJalur = index),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: selected ? Border.all(color: AppColors.border) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(
            color: selected ? AppColors.primary : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _statusCheckBadge(String label, bool isOk) {
    final (bg, fg) = isOk
        ? (AppColors.successBg, AppColors.success)
        : (AppColors.dangerBg, AppColors.danger);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.xmark_circle_fill,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: AppText.label.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

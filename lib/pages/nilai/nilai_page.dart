import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_kit.dart';
import '../khs_page.dart';
import '../nilai_rincian_page.dart';
import '../transkrip_page.dart';

/// Tab "Nilai" — sebelumnya langsung membuka satu halaman panjang sehingga
/// terasa padat. Kini jadi titik masuk ringkas: pengguna memilih tingkat
/// kedalaman informasi yang dibutuhkan (progressive disclosure).
///
///   KHS          → hasil studi satu semester terpilih
///   Rincian      → rincian komponen penilaian tiap mata kuliah
///   Transkrip    → rekap seluruh semester + IPK
class NilaiPage extends StatelessWidget {
  const NilaiPage({super.key});


  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nilai',
      subtitle: 'KHS, rincian, dan transkrip',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMASI NILAI',
            style: AppText.overline,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListGroup.from([
            AppListRow(
              leading: _iconBadge(CupertinoIcons.rosette),
              title: 'KHS',
              subtitle: 'Kartu hasil studi per semester',
              trailing: const Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: AppColors.textMuted,
              ),
              onTap: () => _push(context, const KhsPage()),
            ),
            AppListRow(
              leading: _iconBadge(CupertinoIcons.chart_bar_alt_fill),
              title: 'Rincian Nilai',
              subtitle: 'Komponen penilaian tiap mata kuliah',
              trailing: const Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: AppColors.textMuted,
              ),
              onTap: () => _push(
                context,
                NilaiRincianPage(),
              ),
            ),
            AppListRow(
              leading: _iconBadge(CupertinoIcons.doc_text_fill),
              title: 'Transkrip Nilai',
              subtitle: 'Rekap seluruh semester & IPK',
              trailing: const Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: AppColors.textMuted,
              ),
              onTap: () => _push(
                context,
                TranskripPage(),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          AppSurface(
            variant: AppSurfaceVariant.hero,
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.info_circle_fill,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Nilai yang tampil di aplikasi ini bersifat informasi. '
                    'Nilai resmi tetap mengacu pada portal akademik kampus.',
                    style: AppText.bodySm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _iconBadge(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: AppDeco.softPrimary(radius: AppRadius.sm),
      child: Icon(icon, size: 19, color: AppColors.primary),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

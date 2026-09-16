import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class VisiMisiInstitusiPage extends StatelessWidget {
  final VoidCallback? onBack;
  const VisiMisiInstitusiPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Visi & Misi Institusi',
      subtitle: 'Universitas AMIKOM Purwokerto',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(),
          _contentSection(
            title: 'Visi',
            icon: CupertinoIcons.eye_fill,
            toneBg: AppColors.infoBg,
            toneFg: AppColors.info,
            child: Text(
              'Visi Universitas AMIKOM Purwokerto adalah "Unggul Dalam Pengembangan Ilmu Pengetahuan dan Teknologi Berbasis Technopreneur".',
              style: AppText.body.copyWith(height: 1.7),
              textAlign: TextAlign.justify,
            ),
          ),
          _contentSection(
            title: 'Misi',
            icon: CupertinoIcons.rocket_fill,
            toneBg: AppColors.warningBg,
            toneFg: AppColors.warning,
            child: _numberedList([
              'Menyelenggarakan pendidikan dan pelatihan terbaik di bidang teknologi komputer dan informatika berbasis Technopreneur, sesuai dengan perkembangan ilmu pengetahuan dan teknologi.',
              'Menyebarluaskan hasil penelitian dan pengabdian kepada masyarakat melalui berbagai media agar dapat diakses oleh masyarakat.',
              'Menyelenggarakan penelitian dan pengabdian masyarakat dalam bidang teknologi komputer dan informatika untuk kesejahteraan masyarakat.',
            ]),
          ),
        ],
      ),
    );
  }

  /// Kartu identitas universitas.
  Widget _buildHeader() {
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: AppDeco.softPrimary(),
            child: const Icon(
              CupertinoIcons.building_2_fill,
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Universitas', style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'AMIKOM Purwokerto',
            style: AppText.h1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Seksi teks: judul hierarkis (overline + ikon) dan kartu isi yang lapang.
  Widget _contentSection({
    required String title,
    required IconData icon,
    required Color toneBg,
    required Color toneFg,
    required Widget child,
  }) {
    return AppSection(
      title: title,
      trailing: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: toneBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 16, color: toneFg),
      ),
      child: AppSurface(child: child),
    );
  }

  /// Daftar bernomor untuk butir misi.
  Widget _numberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, text) in items.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: AppDeco.softPrimary(radius: AppRadius.sm),
                child: Text(
                  '${index + 1}',
                  style: AppText.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: AppText.body.copyWith(height: 1.7),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

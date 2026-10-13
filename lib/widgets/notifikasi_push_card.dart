import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/notifikasi.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

/// Kartu status notifikasi push (FCM) di puncak halaman notifikasi.
///
/// Seluruh state & aksi disuntikkan dari luar agar kartu bebas dari ketergantungan
/// jaringan langsung dan mudah diuji secara terisolasi.
class NotifikasiPushCard extends StatelessWidget {
  final NotifikasiOptinStatus? status;
  final bool loading;
  final bool busy;
  final bool tidakTersedia;
  final String? pesanGagal;
  final int retryAfterSeconds;
  final VoidCallback? onAktifkan;
  final VoidCallback? onMatikan;
  final VoidCallback? onMuatUlang;

  const NotifikasiPushCard({
    super.key,
    this.status,
    this.loading = false,
    this.busy = false,
    this.tidakTersedia = false,
    this.pesanGagal,
    this.retryAfterSeconds = 0,
    this.onAktifkan,
    this.onMatikan,
    this.onMuatUlang,
  });

  @override
  Widget build(BuildContext context) {
    if (tidakTersedia) {
      return _buildTidakTersedia();
    }

    final sedangMemuat =
        loading ||
        (status == null && (pesanGagal == null || pesanGagal!.isEmpty));
    if (sedangMemuat) {
      return _buildMemuat();
    }

    if (pesanGagal != null && pesanGagal!.isNotEmpty) {
      return _buildGagal();
    }

    if (status != null && status!.enabled) {
      return _buildAktif();
    }

    return _buildNonaktif();
  }

  Widget _buildMemuat() {
    return AppSurface(
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Memuat status notifikasi push…',
              style: AppText.bodySm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGagal() {
    return AppSurface(
      variant: AppSurfaceVariant.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Notifikasi Push',
                  style: AppText.h3.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(pesanGagal!, style: AppText.bodySm),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: (busy || retryAfterSeconds > 0) ? null : onMuatUlang,
            icon: const Icon(CupertinoIcons.refresh, size: 16),
            label: Text(
              retryAfterSeconds > 0
                  ? 'Coba lagi dalam ${retryAfterSeconds}s'
                  : 'Coba Lagi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTidakTersedia() {
    return AppSurface(
      variant: AppSurfaceVariant.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.bell_slash_fill,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Notifikasi Push', style: AppText.h3)),
              const AppPill('Tidak Tersedia', tone: AppPillTone.warning),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Layanan notifikasi push sedang dinonaktifkan oleh server.',
            style: AppText.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          const FilledButton(
            onPressed: null,
            child: Text('Aktifkan Notifikasi Push'),
          ),
        ],
      ),
    );
  }

  Widget _buildNonaktif() {
    final terkunciRateLimit = retryAfterSeconds > 0;
    final nonaktifTombol = busy || terkunciRateLimit;

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.bell,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Notifikasi Push', style: AppText.h3)),
              const AppPill('Nonaktif', tone: AppPillTone.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Terima kabar terbaru dari kampus langsung di ponsel Anda.',
            style: AppText.bodySm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: nonaktifTombol ? null : onAktifkan,
            child: _buildLabelTombolAksi(
              labelDefault: 'Aktifkan Notifikasi Push',
              terkunciRateLimit: terkunciRateLimit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAktif() {
    final terkunciRateLimit = retryAfterSeconds > 0;
    final nonaktifMatikan = busy || terkunciRateLimit;

    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.bell_fill,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Notifikasi Push', style: AppText.h3)),
              const AppPill('Aktif', tone: AppPillTone.success),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Notifikasi kampus aktif di perangkat ini.',
            style: AppText.bodySm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                CupertinoIcons.device_phone_portrait,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Android · Terhubung · ${status!.tokenCount} perangkat',
                  style: AppText.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: nonaktifMatikan ? null : onMatikan,
            child: _buildLabelTombolAksi(
              labelDefault: 'Matikan',
              terkunciRateLimit: terkunciRateLimit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelTombolAksi({
    required String labelDefault,
    required bool terkunciRateLimit,
  }) {
    if (terkunciRateLimit) {
      return Text('Coba lagi dalam ${retryAfterSeconds}s');
    }
    if (busy) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(labelDefault),
        ],
      );
    }
    return Text(labelDefault);
  }
}

/// Membuka bottom sheet panduan sistem notifikasi push.
Future<void> showNotifikasiPushSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const NotifikasiPushSheet(),
  );
}

/// Bottom sheet panduan agar notifikasi kampus tidak tertahan oleh sistem.
///
/// Isinya murni pengaturan perangkat — tidak ada aplikasi pihak ketiga yang
/// perlu dipasang atau disambungkan, karena notifikasi dikirim langsung oleh
/// server kampus ke aplikasi ini.
class NotifikasiPushSheet extends StatelessWidget {
  const NotifikasiPushSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Agar Notifikasi Kampus Masuk', style: AppText.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Notifikasi dikirim langsung oleh server kampus ke aplikasi ini — '
              'tidak perlu memasang aplikasi lain.',
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              variant: AppSurfaceVariant.hero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLangkah(
                    nomor: 1,
                    teks:
                        'Izinkan notifikasi untuk aplikasi ini. Pada Android 13 ke '
                        'atas, izin diminta saat Anda menekan Aktifkan; bila '
                        'sebelumnya ditolak, buka Pengaturan > Notifikasi > '
                        'Ini Amikom?.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildLangkah(
                    nomor: 2,
                    teks:
                        "Bila muncul peringatan optimasi baterai untuk aplikasi "
                        "Ini Amikom?, pilih 'Jangan optimalkan' agar notifikasi "
                        "tidak tertahan.",
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildLangkah(
                    nomor: 3,
                    teks:
                        'Selesai. Notifikasi kampus akan masuk otomatis — ketuk '
                        'notifikasi untuk membuka detail pengumuman.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangkah({required int nomor, required String teks}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$nomor',
            style: AppText.label.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(teks, style: AppText.bodySm)),
      ],
    );
  }
}

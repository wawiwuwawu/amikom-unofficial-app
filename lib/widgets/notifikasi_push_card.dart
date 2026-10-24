import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/notifikasi.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

/// Kartu status notifikasi push (FCM) di puncak halaman notifikasi.
///
/// Status bersifat BACA-SAJA: notifikasi dinyalakan otomatis oleh aplikasi
/// (izin diminta sendiri setelah login maupun saat aplikasi dibuka kembali),
/// jadi user tidak perlu menyalakannya lewat tombol di kartu ini. Bila push
/// belum aktif — misalnya izin notifikasi ditolak — kartu memandu ke
/// pengaturan sistem perangkat, bukan menawarkan aksi dalam aplikasi.
///
/// Seluruh state disuntikkan dari luar agar kartu bebas dari ketergantungan
/// jaringan langsung dan mudah diuji secara terisolasi.
class NotifikasiPushCard extends StatelessWidget {
  final NotifikasiOptinStatus? status;
  final bool loading;
  final bool tidakTersedia;
  final String? pesanGagal;

 /// Aktivasi gagal karena perangkat/build (gateway FCM tak siap), bukan
 /// karena izin sistem - kartu tak boleh memandu ke Pengaturan sistem.
 final bool perangkatGagal;

 /// Registrasi token ditolak SERVER (mis. adapter 503 - FCM belum
 /// dikonfigurasi): pengaturan di HP tak bisa menolong, jadi pesan yang
 /// tepat adalah "server bermasalah" + aksi Muat Ulang, bukan panduan
 /// Pengaturan.
 final bool serverGagal;
 final VoidCallback? onMuatUlang;

 const NotifikasiPushCard({
 super.key,
 this.status,
 this.loading = false,
 this.tidakTersedia = false,
 this.pesanGagal,
 this.perangkatGagal = false,
 this.serverGagal = false,
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
    return const AppSurface(
      child: AppLoading(message: 'Memuat status notifikasi push…'),
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
            onPressed: onMuatUlang,
            icon: const Icon(CupertinoIcons.refresh, size: 16),
            label: const Text('Muat Ulang'),
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
          OutlinedButton.icon(
            onPressed: onMuatUlang,
            icon: const Icon(CupertinoIcons.refresh, size: 16),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildNonaktif() {
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
          if (perangkatGagal)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 13,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Notifikasi tidak bisa dinyalakan di perangkat ini — '
                    'perbarui aplikasi atau hubungi pengelola.',
                    style: AppText.label.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            )
          else if (serverGagal)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 13,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Notifikasi belum aktif karena server pengelola sedang '
                        'bermasalah — izin di HP sudah cukup. Tekan Muat Ulang '
                        'untuk mencoba lagi setelah server diperbaiki.',
                        style: AppText.label.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onMuatUlang,
                  icon: const Icon(CupertinoIcons.refresh, size: 16),
                  label: const Text('Muat Ulang'),
                ),
              ],
            )
          else
            Text(
              'Notifikasi kampus dinyalakan otomatis oleh aplikasi. Bila belum '
              'aktif, buka Pengaturan > Notifikasi > Ini Amikom? lalu izinkan '
              'notifikasi untuk aplikasi ini.',
              style: AppText.bodySm,
            ),
          // Saran BE: enabled=false + token masih terdaftar berarti server
          // push bermasalah (mis. FCM mati), bukan user belum pernah daftar.
          if (status != null && status!.tokenCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 13,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Perangkat sudah terdaftar, tapi server notifikasi sedang '
                    'bermasalah. Coba lagi nanti atau hubungi pengelola.',
                    style: AppText.label.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAktif() {
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
        ],
      ),
    );
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
                        'Izinkan notifikasi untuk aplikasi ini. Izin diminta '
                        'otomatis oleh aplikasi; bila sebelumnya ditolak, buka '
                        'Pengaturan > Notifikasi > Ini Amikom? lalu izinkan '
                        'notifikasi.',
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
                        'notifikasi untuk membuka daftar notifikasi.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pengingat jadwal juga aktif otomatis tanpa pengaturan: aplikasi '
              'mengingatkan 30 menit sebelum kelas atau ujian dimulai, selama '
              'izin notifikasi di atas diizinkan.',
              style: AppText.bodySm,
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

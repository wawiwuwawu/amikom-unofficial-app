import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/disclaimer_view.dart';

/// Halaman "Penafian" — bisa dibuka kapan saja dari drawer/menu aplikasi.
class PenafianPage extends StatelessWidget {
  const PenafianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Penafian',
      body: Center(
        // Lebar baris dibatasi agar teks panjang tetap nyaman dibaca.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _item(
                topGap: AppSpacing.xs,
                icon: CupertinoIcons.exclamationmark_shield_fill,
                title: 'Bukan Aplikasi Resmi',
                body:
                    'AmiApp adalah aplikasi tidak resmi yang dibuat secara independen. '
                    'Aplikasi ini TIDAK berafiliasi, tidak didukung, dan tidak disponsori oleh '
                    'Universitas Amikom Purwokerto maupun vendor sistem informasi kampus dalam bentuk apa pun.',
              ),
              _item(
                icon: CupertinoIcons.doc_text,
                title: 'Tanpa Garansi',
                body:
                    'Aplikasi disediakan "sebagaimana adanya", tanpa garansi dalam bentuk apa pun — '
                    'termasuk keakuratan, kelengkapan, atau ketersediaan data. Data akademik yang '
                    'ditampilkan bisa tertinggal, berbeda, atau salah karena faktor di luar kendali pengembang. '
                    'Untuk keputusan penting (pembayaran, KRS, kelulusan, dll.), selalu verifikasi langsung '
                    'melalui kanal resmi kampus. Aplikasi ini bukan pengganti kanal resmi untuk hal-hal '
                    'yang bersifat mengikat.',
              ),
              _item(
                icon: CupertinoIcons.hand_raised_fill,
                title: 'Gunakan dengan Risiko Sendiri',
                body:
                    'Penggunaan aplikasi sepenuhnya merupakan keputusan dan tanggung jawab pengguna. '
                    'Pengembang tidak bertanggung jawab atas kerugian, kerusakan, konsekuensi '
                    'akademik/administratif, maupun masalah lain yang timbul — langsung maupun tidak langsung — '
                    'dari penggunaan aplikasi ini.',
              ),
              _item(
                icon: CupertinoIcons.lock_shield,
                title: 'Ketersediaan Layanan',
                body:
                    'Backend adaptor berjalan di infrastruktur pribadi yang tidak menyala 24/7. '
                    'Uptime 100% tidak dapat dijamin; bila aplikasi menampilkan status offline, '
                    'silakan coba kembali di lain waktu.',
              ),
              _item(
                icon: CupertinoIcons.exclamationmark_triangle_fill,
                title: 'Operasi Sensitif & Pembayaran',
                body:
                    'Untuk tindakan yang TIDAK BOLEH SALAH — mengunggah dokumen resmi (skripsi, '
                    'laporan, berkas administrasi) maupun transaksi pembayaran/pembuatan VA — '
                    'sangat disarankan menggunakan portal resmi melalui browser. Kemampuan aplikasi '
                    'pada operasi tersebut tidak dapat dijamin 100%. Sejak awal aplikasi dirilis '
                    'tanpa garansi apa pun; akibat kegagalan atau kesalahan proses pada operasi '
                    'sensitif merupakan risiko dan tanggung jawab pengguna sepenuhnya, bukan pengembang.',
              ),
              _item(
                icon: CupertinoIcons.person_crop_circle_badge_exclam,
                title: 'Privasi & Kredensial',
                body:
                    'Token sesi disimpan di secure storage perangkat, bukan password mentah. '
                    'Tetap gunakan perangkat pribadi dan jangan pernah membagikan kredensial portal '
                    'kepada siapa pun.',
              ),
              const SizedBox(height: AppSpacing.xl),
              AppSurface(
                variant: AppSurfaceVariant.hero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dengan melanjutkan menggunakan AmiApp, kamu dianggap telah membaca, memahami, '
                      'dan menyetujui seluruh ketentuan di atas. Detail lengkap tersedia di Wiki proyek.',
                      style: AppText.body.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Ketentuan ini dapat berubah sewaktu-waktu dan berlaku sejak dipublikasikan '
                      'di Wiki proyek dan/atau disertakan dalam versi aplikasi terbaru; ketentuan '
                      'pada versi sebelumnya gugur dan digantikan oleh versi terbaru.',
                      style: AppText.label.copyWith(
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: openFullDisclaimer,
                  icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 16),
                  label: const Text('Baca versi lengkap di Wiki proyek'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String body,
    double topGap = AppSpacing.xl,
  }) {
    return AppSection(
      title: title,
      topGap: topGap,
      child: AppSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              // line-height lega supaya paragraf panjang tetap enak dibaca.
              child: Text(body, style: AppText.body.copyWith(height: 1.65)),
            ),
          ],
        ),
      ),
    );
  }
}

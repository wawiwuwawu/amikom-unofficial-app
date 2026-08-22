import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'glass_card.dart';

/// Widget tampilan isi penafian (disclaimer) AmiApp.
/// Dipakai di [DisclaimerGatePage] (persetujuan pertama) dan menu "Penafian".
///
/// [showAcceptButton]: true untuk mode persetujuan (gate), false untuk baca-saja.
class DisclaimerView extends StatelessWidget {
  final bool showAcceptButton;
  final VoidCallback? onAccepted;

  const DisclaimerView({
    super.key,
    this.showAcceptButton = false,
    this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(
            icon: CupertinoIcons.exclamationmark_shield_fill,
            title: 'Bukan Aplikasi Resmi',
            body:
                'AmiApp adalah aplikasi tidak resmi yang dibuat secara independen. '
                'Aplikasi ini TIDAK berafiliasi, tidak didukung, dan tidak disponsori oleh '
                'Universitas Amikom Purwokerto maupun vendor sistem informasi kampus dalam bentuk apa pun.',
          ),
          _section(
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
          _section(
            icon: CupertinoIcons.hand_raised_fill,
            title: 'Gunakan dengan Risiko Sendiri',
            body:
                'Penggunaan aplikasi sepenuhnya merupakan keputusan dan tanggung jawab pengguna. '
                'Pengembang tidak bertanggung jawab atas kerugian, kerusakan, konsekuensi '
                'akademik/administratif, maupun masalah lain yang timbul — langsung maupun tidak langsung — '
                'dari penggunaan aplikasi ini.',
          ),
          _section(
            icon: CupertinoIcons.lock_shield,
            title: 'Ketersediaan Layanan',
            body:
                'Backend adaptor berjalan di infrastruktur pribadi yang tidak menyala 24/7. '
                'Uptime 100% tidak dapat dijamin; bila aplikasi menampilkan status offline, '
                'silakan coba kembali di lain waktu.',
          ),
          _section(
            icon: CupertinoIcons.person_crop_circle_badge_exclam,
            title: 'Privasi & Kredensial',
            body:
                'Token sesi disimpan di secure storage perangkat, bukan password mentah. '
                'Tetap gunakan perangkat pribadi dan jangan pernah membagikan kredensial portal '
                'kepada siapa pun.',
          ),
          const SizedBox(height: 8),
          Text(
            'Dengan melanjutkan menggunakan AmiApp, kamu dianggap telah membaca, memahami, '
            'dan menyetujui seluruh ketentuan di atas. Detail lengkap tersedia di Wiki proyek.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketentuan ini dapat berubah sewaktu-waktu dan berlaku sejak dipublikasikan '
            'di Wiki proyek dan/atau disertakan dalam versi aplikasi terbaru; ketentuan '
            'pada versi sebelumnya gugur dan digantikan oleh versi terbaru.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (showAcceptButton) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onAccepted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF501F66),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Saya Setuju — Lanjutkan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF501F66)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(fontSize: 12.5, height: 1.55)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Buka wiki Disclaimer di browser eksternal.
Future<void> openFullDisclaimer() async {
  final uri = Uri.parse(
    'https://github.com/wawiwuwawu/amikom-unofficial-app/wiki/Disclaimer',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class PanduanPembayaranPage extends StatefulWidget {
  const PanduanPembayaranPage({super.key});

  @override
  State<PanduanPembayaranPage> createState() => _PanduanPembayaranPageState();
}

class _PanduanPembayaranPageState extends State<PanduanPembayaranPage> {
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka tautan. Silakan coba lagi.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Satu langkah bernomor — angka memberi urutan yang jelas saat dibaca.
  Widget _buildNumberedStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppText.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                text,
                style: AppText.body.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepList(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) _buildNumberedStep(i + 1, steps[i]),
      ],
    );
  }

  /// Kelompok langkah per metode pembayaran → satu permukaan, bukan kartu per langkah.
  Widget _buildMethodCard({
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: AppText.h3)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStepList(steps),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Panduan & Tata Cara Pembayaran',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSurface(
                    variant: AppSurfaceVariant.hero,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(CupertinoIcons.info_circle, color: AppColors.primary, size: 20),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Panduan ini merupakan tata cara resmi pembayaran UKT melalui Virtual Account (VA) Bank Muamalat dan BRI/BRIVA.',
                            style: AppText.body,
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppSection(
                    title: 'I. Tahap Validasi Pembayaran',
                    trailing: const Icon(CupertinoIcons.doc_checkmark, size: 18, color: AppColors.primarySoft),
                    child: AppSurface(
                      child: _buildStepList(const [
                        'Login ke portal Mahasiswa (student.amikompurwokerto.ac.id).',
                        'Masuk ke menu Tagihan Pembayaran.',
                        'Pilih semua tagihan yang ada, lalu klik tombol Bayar pada bagian kiri atas.',
                        'Pada halaman Proses Pembayaran, periksa Nama, NIM, dan Total Tagihan.',
                        'Pilih Metode Pembayaran (contoh: Bank Muamalat / BRIVA).',
                        'Klik Proses dan lanjutkan. Setelah selesai, catat Nomor Virtual Account (VA) dan Total Nominal Tagihan yang terbit.',
                      ]),
                    ),
                  ),

                  AppSection(
                    title: 'II. Metode Pembayaran',
                    trailing: const Icon(CupertinoIcons.creditcard, size: 18, color: AppColors.primarySoft),
                    child: Column(
                      children: [
                        _buildMethodCard(
                          title: 'A. Bank Muamalat',
                          icon: CupertinoIcons.building_2_fill,
                          steps: const [
                            'Teller Bank Muamalat: Kunjungi Payment Point Bank Muamalat depan kampus atau kantor cabang terdekat. Isi slip setoran dengan No. Virtual Account dan Total Biaya sesuai tagihan.',
                            'ATM, Internet Banking & Mobile Banking Muamalat: Masuk menu Pembayaran → Virtual Account. Masukkan No. Virtual Account (751036000*******). Jika Mobile Banking, pilih transfer Online / Segera. Masukkan total biaya sesuai tagihan.',
                            'ATM Bank Lain (Transfer Antarbank): Pilih Transfer Antar Bank, Masukkan Kode Bank Muamalat: 147, lalu No. Virtual Account dan total nominal.',
                            'Internet / Mobile Banking Bank Lain: Transfer Antar Bank → Pilih Bank Muamalat. Masukkan No. VA, pilih Online / Segera, isi kode bank 147 bila diminta, lalu nominal sesuai tagihan.',
                            'Teller Bank Lain: Pengisian slip setoran transfer antarbank menyesuaikan ketentuan masing-masing bank dengan mengarah ke No. Virtual Account Bank Muamalat.',
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildMethodCard(
                          title: 'B. Bank BRI / BRIVA',
                          icon: CupertinoIcons.building_2_fill,
                          steps: const [
                            'Mobile Banking BRI (BRImo): Login BRImo → menu BRIVA → Pembayaran Baru. Masukkan Nomor VA, pilih Online / Segera, klik Lanjut (nominal muncul otomatis), konfirmasi dan Bayar.',
                            'ATM BRI: Masukkan kartu & PIN → menu Pembayaran → Virtual Account. Masukkan Nomor VA, nominal tagihan, lalu Bayar.',
                            'Teller BRI / Agen BRILink: Serahkan Nomor Virtual Account Pembayaran kepada petugas teller BRI atau agen pembayaran.',
                          ],
                        ),
                      ],
                    ),
                  ),

                  AppSection(
                    title: 'III. Catatan & Bantuan',
                    trailing: const Icon(CupertinoIcons.chat_bubble_text, size: 18, color: AppColors.primarySoft),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSurface(
                          variant: AppSurfaceVariant.warning,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'PENTING: Apabila transaksi pembayaran berhasil namun status mata kuliah di KRS belum teraktivasi secara otomatis, silakan hubungi Bagian Keuangan via WhatsApp dengan melampirkan bukti transaksi.',
                                  style: AppText.body.copyWith(color: AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Portal Mahasiswa', style: AppText.h3),
                              const SizedBox(height: AppSpacing.xs),
                              InkWell(
                                onTap: () => _launchUrl('https://student.amikompurwokerto.ac.id/'),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                  child: Text(
                                    'student.amikompurwokerto.ac.id',
                                    style: AppText.body.copyWith(
                                      color: AppColors.info,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.info,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: () => _launchUrl('https://wa.me/62895411177702'),
                          icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 18),
                          label: const Text('Hubungi Bagian Keuangan (WhatsApp)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
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
    );
  }
}

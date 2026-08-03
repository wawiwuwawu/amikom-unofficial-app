import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class PanduanPembayaranPage extends StatefulWidget {
  final VoidCallback? onBack;
  const PanduanPembayaranPage({super.key, this.onBack});

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
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF501F66).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF501F66)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF501F66),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF501F66),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepList(List<String> steps) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) _buildNumberedStep(i + 1, steps[i]),
      ],
    );
  }

  Widget _buildMethodCard({
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF501F66)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStepList(steps),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFAFCFF), Color(0xFFE3F2FD)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                      onPressed: widget.onBack ?? () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Panduan & Tata Cara Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF501F66),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF501F66).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF501F66).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(CupertinoIcons.info_circle,
                            color: Color(0xFF501F66), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Panduan ini merupakan tata cara resmi pembayaran UKT melalui Virtual Account (VA) Bank Muamalat dan BRI/BRIVA.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle(
                    'I. Tahap Validasi Pembayaran',
                    CupertinoIcons.doc_checkmark,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                    ),
                    child: _buildStepList(const [
                      'Login ke portal Mahasiswa (student.amikompurwokerto.ac.id).',
                      'Masuk ke menu Tagihan Pembayaran.',
                      'Pilih semua tagihan yang ada, lalu klik tombol Bayar pada bagian kiri atas.',
                      'Pada halaman Proses Pembayaran, periksa Nama, NIM, dan Total Tagihan.',
                      'Pilih Metode Pembayaran (contoh: Bank Muamalat / BRIVA).',
                      'Klik Proses dan lanjutkan. Setelah selesai, catat Nomor Virtual Account (VA) dan Total Nominal Tagihan yang terbit.',
                    ]),
                  ),

                  _buildSectionTitle(
                    'II. Metode Pembayaran',
                    CupertinoIcons.creditcard,
                  ),
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
                  _buildMethodCard(
                    title: 'B. Bank BRI / BRIVA',
                    icon: CupertinoIcons.building_2_fill,
                    steps: const [
                      'Mobile Banking BRI (BRImo): Login BRImo → menu BRIVA → Pembayaran Baru. Masukkan Nomor VA, pilih Online / Segera, klik Lanjut (nominal muncul otomatis), konfirmasi dan Bayar.',
                      'ATM BRI: Masukkan kartu & PIN → menu Pembayaran → Virtual Account. Masukkan Nomor VA, nominal tagihan, lalu Bayar.',
                      'Teller BRI / Agen BRILink: Serahkan Nomor Virtual Account Pembayaran kepada petugas teller BRI atau agen pembayaran.',
                    ],
                  ),

                  _buildSectionTitle(
                    'III. Catatan & Bantuan',
                    CupertinoIcons.chat_bubble_text,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'PENTING: Apabila transaksi pembayaran berhasil namun status mata kuliah di KRS belum teraktivasi secara otomatis, silakan hubungi Bagian Keuangan via WhatsApp dengan melampirkan bukti transaksi.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Portal Mahasiswa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _launchUrl('https://student.amikompurwokerto.ac.id/'),
                          borderRadius: BorderRadius.circular(6),
                          child: const Text(
                            'student.amikompurwokerto.ac.id',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1976D2),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _launchUrl('https://wa.me/62895411177702'),
                        icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 18),
                        label: const Text('Hubungi Bagian Keuangan (WhatsApp)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

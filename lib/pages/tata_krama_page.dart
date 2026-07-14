import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glass_card.dart';

class TataKramaPage extends StatelessWidget {
  final VoidCallback? onBack;
  const TataKramaPage({super.key, this.onBack});

  Future<void> _downloadPedoman(BuildContext context) async {
    final url = Uri.parse('https://student.amikompurwokerto.ac.id/assets/dokumen/Pedoman_Kode_Etik_Mahasiswa.pdf');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Tidak dapat membuka tautan');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka tautan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: onBack != null
            ? IconButton(
                icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                onPressed: onBack,
              )
            : null,
        title: const Text(
          'Tata Krama & Tertib',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 100,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHeader().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            
            // Intro
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              opacity: 0.8,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pelaksanaan tata krama mahasiswa di Universitas AMIKOM Purwokerto yang sesuai dengan PP 60 Tahun 1999 tentang Sistem Pendidikan Tinggi diwujudkan dengan diberlakukannya tata tertib kehidupan kampus, tata tertib ujian, ketentuan pemilihan lembaga kemahasiswaan yang prinsipnya mengatur tentang perilaku mahasiswa guna menunjang tercapainya tujuan pendidikan tinggi seperti yang diisyaratkan di dalam PP 60 tahun 1999 tersebut.',
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Selain itu, guna menunjang pengembangan penalaran dan keilmuan, minat dan kegemaran serta upaya perbaikan kesejahteraan mahasiswa di Universitas AMIKOM Purwokerto, diadakan kegiatan ekstra kurikuler. Adapun kegiatan kemahasiswaan yang dilaksanakan di lingkungan Universitas AMIKOM Purwokerto misalnya olahraga, seni, kegiatan sosial, kerohanian, dan lain-lain. Melalui pembinaan kemahasiswaan ini fungsi Perguruan Tinggi dengan Tri Dharma Perguruan Tingginya akan mengarah pada pelaksanaan kegiatan ilmiah yang profesional dalam mewujudkan dirinya sebagai lembaga dan masyarakat ilmiah untuk menunjang pembangunan nasional. Dalam hal ini perlu diperhatikan bahwa suasana kampus, baik sebagai wadah kegiatan ekstra kurikuler, maupun kurikuler, hanyalah merupakan salah satu lingkungan pendidikan dalam proses pendidikan seumur hidup, dan dengan sendirinya tidak dapat menampung atau menggantikan fungsi lingkungan pendidikan lainnya yaitu rumah dan masyarakat.',
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Oleh karena itu, agar terjalin masyarakat ilmiah yang selaras, serasi dan seimbang, mahasiswa sebagai anggota lembaga pendidikan Universitas AMIKOM Purwokerto perlu mentaati peraturan mengenai hak dan kewajiban mahasiswa beserta larangannya serta ketentuan tentang lembaga kemahasiswaan yang berlaku di lingkungan Universitas AMIKOM Purwokerto.',
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),

            // Download PDF
            ElevatedButton.icon(
              onPressed: () => _downloadPedoman(context),
              icon: const Icon(CupertinoIcons.doc_text_fill),
              label: const Text('Download Pedoman Kode Etik (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),

            // Norma dan Tingkah Laku
            _buildSectionCard(
              title: 'NORMA DAN TINGKAH LAKU',
              icon: CupertinoIcons.person_3_fill,
              color: Colors.blue,
              items: [
                'Jujur, khususnya dalam proses belajar mengajar, meneliti, membuat karya tulis dan dalam tindakan lain yang menyangkut nama baik Universitas AMIKOM Purwokerto;',
                'Tekun dan disiplin dalam berbagai tindakan, khususnya dalam menjalankan tugas menimba ilmu di lingkungan Universitas AMIKOM Purwokerto',
                'Berperan aktif menjaga integritas Universitas AMIKOM Purwokerto;',
                'Selalu berusaha meningkatkan kemampuan dalam menunjang tugas di Universitas AMIKOM Purwokerto;',
                'Sopan dalam berpakaian, berperilaku santun dan rendah hati, tidak anarkis, serta tidak menyebarfitnah dan atau kedengkian;',
                'Saling menghormati dan menghargai;',
                'Peduli lingkungan, baik lingkungan sosial mapun lingkungan fisik, berupa suasana, kebersihan, maupun keindahan lingkungan.',
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),

            // Pelanggaran dan Sanksi
            _buildSectionCard(
              title: 'PELANGGARAN DAN SANKSI',
              icon: CupertinoIcons.exclamationmark_shield_fill,
              color: Colors.redAccent,
              items: [
                'Menyalahgunakan nama,lambang dan segala bentuk atribut Universitas AMIKOM Purwokerto. Sanksi : Teguran dan peringatan; Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Memalsukan atau menyalah gunakan surat atau membocorkan kerahasiaan dokumen Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Menghambat atau mengganggu berlangsungnya kegiatan Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Mengotori atau merusak ruangan, bangunan dan sarana lain milik atau di bawah pengawasan Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan, sertai kewajiban mengganti semua kerusakan dan atau kerugian yang ditimbulkannya; (2) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Menimbulkan atau mencoba menimbulkan ketidak tertiban dan perpecahan di Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Mempergunakan atau mencoba mempergunakan atau memperdagangkan jenis narkotika / obat terlarang dilingkungan Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto',
                'Melakukan atau mencoba melakukan semua jenis permainan yang mengarah ke bentuk perjudian di lingkungan Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Melakukan kekerasan phisik dalam penyelesaian suatu masalah di lingkungan Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan;(2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Mengadakan demonstrasi, huru-hara dan sejenisnya di lingkungan Universitas AMIKOM Purwokerto. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
                'Menggunakan sarana dan dana yang dimiliki atau di bawah pengawasan Universitas AMIKOM Purwokerto untuk keperluan pribadi. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.'
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            
            // Tata Tertib Perkuliahan
            _buildSectionCard(
              title: 'TATA TERTIB PERKULIAHAN',
              icon: CupertinoIcons.building_2_fill,
              color: Colors.green,
              items: [
                'Mahasiswa dapat mengikuti kegiatan perkuliahan suatu mata kuliah dengan ketentuan sebagai berikut : (a) Terdaftar sebagai mahasiswa Universitas AMIKOM Purwokerto; (b) Terdaftar sebagai pesertamata kuliah tersebut; (c) Tidak dicabut haknya untuk mengikuti aktivitas studi.',
                'Mahasiswa yang tidak terdaftar pada suatu mata kuliah dapat menjadi pendengar dengan seijin dosen matakuliah yang bersangkutan.',
                'Mahasiswa harus berpakaian rapih dan bersikap sopan serta saling menghargai dan menghormati.',
                'Mahasiswa wajib mengikuti segala kegiatan kurikuler (kuliah, responsi, praktikum penunjang) sesuai dengan jadwal yang telah ditentukan. Kuliah diberikan selama 60 menit per satu SKS untuk setiap kali pertemuan.',
                'Mahasiswa peserta kuliah dilarang meninggalkan ruang kuliah selama kuliah berlangsung tanpa seijin Dosen.',
                'Apabila mahasiswa berhalangan atau sakit diharuskan menunjukkan surat ijin yang ditujukan ke Dosen.',
                'Apabila mahasiswa terlambat hadir di ruang kuliah, maka mahasiswa dapat mengikuti perkuliahan setelah ada izin dari Dosen.',
                'Mahasiswa yang hadir wajib membubuhkan tanda tangan pada daftar hadir kuliah.',
                'Mahasiswa melakukan presensi secara elektronis melaui program ePresensi',
                'Mahasiswa harus hadir minimal 70% dari seluruh jumlah pertemuan untuk setiap mata kuliah untuk dapat mengikuti Ujian Akhir Semester (UAS) atau Ujian Utama.',
                'Mahasiswa wajib berpartisipasi aktif di dalam kegiatan kuliah.',
                'Mahasiswa dilarang merokok di dalam ruang kuliah selama perkuliahan berlangsung.',
                'Mahasiswa dilarang membuat onar dan kegaduhan selama kuliah berlangsung.',
                'Mahasiswa tidak diperkenanka menggunakan alat komunikasi selama perkuliahan berlangsung;',
                'Untuk memperlancar studinya, setiap mahasiswa mendapat bimbingan dari seorang penasehat akademik dan dosen wali yang ditunjuk oleh BAAK dengan tugas membimbing kegiatan akademik mahasiswa seperti penentuan matakuliah setiap semester dan masalah-salah yang bersangkutan dengan akademik'
              ],
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(CupertinoIcons.person_2_alt, size: 64, color: Color(0xFF501F66)),
        const SizedBox(height: 12),
        const Text(
          'Pedoman',
          style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        const Text(
          'Tata Krama Mahasiswa',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF501F66), letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF501F66),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final text = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$idx',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

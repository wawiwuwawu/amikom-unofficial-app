import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class TataKramaPage extends StatelessWidget {
  final VoidCallback? onBack;
  const TataKramaPage({super.key, this.onBack});

  Future<void> _downloadPedoman(BuildContext context) async {
    final url = Uri.parse(
      'https://student.amikompurwokerto.ac.id/assets/dokumen/Pedoman_Kode_Etik_Mahasiswa.pdf',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Tidak dapat membuka tautan');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka tautan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tata Krama & Tertib',
      subtitle: 'Pedoman kode etik mahasiswa',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.xl),

          // Intro
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pelaksanaan tata krama mahasiswa di Universitas AMIKOM Purwokerto yang sesuai dengan PP 60 Tahun 1999 tentang Sistem Pendidikan Tinggi diwujudkan dengan diberlakukannya tata tertib kehidupan kampus, tata tertib ujian, ketentuan pemilihan lembaga kemahasiswaan yang prinsipnya mengatur tentang perilaku mahasiswa guna menunjang tercapainya tujuan pendidikan tinggi seperti yang diisyaratkan di dalam PP 60 tahun 1999 tersebut.',
                  style: AppText.body.copyWith(height: 1.7),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Selain itu, guna menunjang pengembangan penalaran dan keilmuan, minat dan kegemaran serta upaya perbaikan kesejahteraan mahasiswa di Universitas AMIKOM Purwokerto, diadakan kegiatan ekstra kurikuler. Adapun kegiatan kemahasiswaan yang dilaksanakan di lingkungan Universitas AMIKOM Purwokerto misalnya olahraga, seni, kegiatan sosial, kerohanian, dan lain-lain. Melalui pembinaan kemahasiswaan ini fungsi Perguruan Tinggi dengan Tri Dharma Perguruan Tingginya akan mengarah pada pelaksanaan kegiatan ilmiah yang profesional dalam mewujudkan dirinya sebagai lembaga dan masyarakat ilmiah untuk menunjang pembangunan nasional. Dalam hal ini perlu diperhatikan bahwa suasana kampus, baik sebagai wadah kegiatan ekstra kurikuler, maupun kurikuler, hanyalah merupakan salah satu lingkungan pendidikan dalam proses pendidikan seumur hidup, dan dengan sendirinya tidak dapat menampung atau menggantikan fungsi lingkungan pendidikan lainnya yaitu rumah dan masyarakat.',
                  style: AppText.body.copyWith(height: 1.7),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Oleh karena itu, agar terjalin masyarakat ilmiah yang selaras, serasi dan seimbang, mahasiswa sebagai anggota lembaga pendidikan Universitas AMIKOM Purwokerto perlu mentaati peraturan mengenai hak dan kewajiban mahasiswa beserta larangannya serta ketentuan tentang lembaga kemahasiswaan yang berlaku di lingkungan Universitas AMIKOM Purwokerto.',
                  style: AppText.body.copyWith(height: 1.7),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Download PDF
          FilledButton.icon(
            onPressed: () => _downloadPedoman(context),
            icon: const Icon(CupertinoIcons.doc_text_fill),
            label: const Text('Download Pedoman Kode Etik (PDF)'),
          ),

          // Norma dan Tingkah Laku
          _buildSectionCard(
            title: 'NORMA DAN TINGKAH LAKU',
            icon: CupertinoIcons.person_3_fill,
            color: AppColors.info,
            items: [
              'Jujur, khususnya dalam proses belajar mengajar, meneliti, membuat karya tulis dan dalam tindakan lain yang menyangkut nama baik Universitas AMIKOM Purwokerto;',
              'Tekun dan disiplin dalam berbagai tindakan, khususnya dalam menjalankan tugas menimba ilmu di lingkungan Universitas AMIKOM Purwokerto',
              'Berperan aktif menjaga integritas Universitas AMIKOM Purwokerto;',
              'Selalu berusaha meningkatkan kemampuan dalam menunjang tugas di Universitas AMIKOM Purwokerto;',
              'Sopan dalam berpakaian, berperilaku santun dan rendah hati, tidak anarkis, serta tidak menyebarfitnah dan atau kedengkian;',
              'Saling menghormati dan menghargai;',
              'Peduli lingkungan, baik lingkungan sosial mapun lingkungan fisik, berupa suasana, kebersihan, maupun keindahan lingkungan.',
            ],
          ),

          // Pelanggaran dan Sanksi
          _buildSectionCard(
            title: 'PELANGGARAN DAN SANKSI',
            icon: CupertinoIcons.exclamationmark_shield_fill,
            color: AppColors.danger,
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
              'Menggunakan sarana dan dana yang dimiliki atau di bawah pengawasan Universitas AMIKOM Purwokerto untuk keperluan pribadi. Sanksi : (1) Teguran dan peringatan; (2) Larangan mengikuti kegiatan akademis dan kegiatan lainnya dalam waktu maksimum 12 bulan; (3) Dicabut kedudukannya sebagai warga Universitas AMIKOM Purwokerto.',
            ],
          ),

          // Tata Tertib Perkuliahan
          _buildSectionCard(
            title: 'TATA TERTIB PERKULIAHAN',
            icon: CupertinoIcons.building_2_fill,
            color: AppColors.success,
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
              'Untuk memperlancar studinya, setiap mahasiswa mendapat bimbingan dari seorang penasehat akademik dan dosen wali yang ditunjuk oleh BAAK dengan tugas membimbing kegiatan akademik mahasiswa seperti penentuan matakuliah setiap semester dan masalah-salah yang bersangkutan dengan akademik',
            ],
          ),
        ],
      ),
    );
  }

  /// Kartu identitas pedoman.
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
              CupertinoIcons.person_2_alt,
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Pedoman', style: AppText.label),
          Text(
            'Tata Krama Mahasiswa',
            style: AppText.h1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Seksi aturan: judul hierarkis (overline + ikon) dan butir bernomor
  /// dengan paragraf yang lapang agar mudah dibaca.
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return AppSection(
      title: title,
      trailing: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      child: AppSurface(
        child: Column(
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
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppText.label.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: AppText.body.copyWith(height: 1.6),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

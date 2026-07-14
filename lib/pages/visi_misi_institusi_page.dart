import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_card.dart';

class VisiMisiInstitusiPage extends StatelessWidget {
  final VoidCallback? onBack;
  const VisiMisiInstitusiPage({super.key, this.onBack});

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
          'Visi & Misi Institusi',
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
            _buildSectionCard(
              title: 'Visi',
              icon: CupertinoIcons.eye_fill,
              color: Colors.blue,
              content: [
                'Visi Universitas AMIKOM Purwokerto adalah "Unggul Dalam Pengembangan Ilmu Pengetahuan dan Teknologi Berbasis Technopreneur".'
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Misi',
              icon: CupertinoIcons.rocket_fill,
              color: Colors.orange,
              content: [
                'Menyelenggarakan pendidikan dan pelatihan terbaik di bidang teknologi komputer dan informatika berbasis Technopreneur, sesuai dengan perkembangan ilmu pengetahuan dan teknologi.',
                'Menyebarluaskan hasil penelitian dan pengabdian kepada masyarakat melalui berbagai media agar dapat diakses oleh masyarakat.',
                'Menyelenggarakan penelitian dan pengabdian masyarakat dalam bidang teknologi komputer dan informatika untuk kesejahteraan masyarakat.'
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(CupertinoIcons.building_2_fill, size: 64, color: Color(0xFF501F66)),
        const SizedBox(height: 12),
        const Text(
          'Universitas',
          style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        const Text(
          'AMIKOM Purwokerto',
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
    required List<String> content,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF501F66),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.asMap().entries.map((entry) {
            final text = entry.value;
            final isList = content.length > 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isList) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: isList ? TextAlign.left : TextAlign.justify,
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

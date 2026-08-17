import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transkrip.dart';
import '../pages/sp_page.dart';
import 'glass_card.dart';

void showCumlaudeBottomSheet(BuildContext context, CumlaudeData data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CumlaudeSheet(data: data),
  );
}

class CumlaudeSheet extends StatelessWidget {
  final CumlaudeData data;

  const CumlaudeSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isCumlaude = data.isCumlaudeEligible;
    final primaryColor = isCumlaude ? const Color(0xFFD89E00) : const Color(0xFF1565C0);
    final bgGradient = isCumlaude
        ? const LinearGradient(
            colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFCFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handlebar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCumlaude ? CupertinoIcons.rosette : CupertinoIcons.chart_bar_alt_fill,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Evaluasi Kelayakan Cumlaude',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF501F66),
                            ),
                          ),
                          Text(
                            'Analisis Predikat & Syarat Akademis',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Banner Proyeksi Predikat
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: bgGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isCumlaude ? '🎓 Proyeksi: Cumlaude' : 'Proyeksi: ${data.predikatSaatIni}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCumlaude ? Colors.amber.shade700 : Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isCumlaude ? 'ELIGIBLE' : 'REGULER',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _infoBadge('IPK', data.ipkTerakhir.toStringAsFixed(2), primaryColor),
                              const SizedBox(width: 8),
                              _infoBadge('SKS Lulus', '${data.totalSksLulus} SKS', primaryColor),
                              const SizedBox(width: 8),
                              _infoBadge('Semester', '${data.semesterSaatIni}', primaryColor),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(duration: 300.ms),
                    const SizedBox(height: 24),

                    // Title 4 Syarat Akademik
                    const Text(
                      'Checklist 4 Syarat Cumlaude',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF501F66),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Syarat 1: IPK
                    _buildSyaratItem(
                      title: 'Syarat IPK (${data.analisisSyarat.syaratIpk.target})',
                      detail: data.analisisSyarat.syaratIpk,
                      icon: CupertinoIcons.star_fill,
                    ),
                    const SizedBox(height: 10),

                    // Syarat 2: Masa Studi
                    _buildSyaratItem(
                      title: 'Syarat Masa Studi (${data.analisisSyarat.syaratMasaStudi.target})',
                      detail: data.analisisSyarat.syaratMasaStudi,
                      icon: CupertinoIcons.time_solid,
                    ),
                    const SizedBox(height: 10),

                    // Syarat 3: Status Masuk
                    _buildSyaratItem(
                      title: 'Syarat Status Masuk (${data.analisisSyarat.syaratStatusMasuk.target})',
                      detail: data.analisisSyarat.syaratStatusMasuk,
                      icon: CupertinoIcons.person_badge_plus_fill,
                    ),
                    const SizedBox(height: 10),

                    // Syarat 4: Nilai Minimum
                    _buildSyaratItem(
                      title: 'Syarat Nilai Minimum (${data.analisisSyarat.syaratNilaiMinimum.target})',
                      detail: SyaratDetail(
                        isFulfilled: data.analisisSyarat.syaratNilaiMinimum.isFulfilled,
                        currentVal: '${data.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount} pelanggaran',
                        target: data.analisisSyarat.syaratNilaiMinimum.target,
                        description: data.analisisSyarat.syaratNilaiMinimum.description,
                      ),
                      icon: CupertinoIcons.exclamationmark_shield_fill,
                    ),
                    const SizedBox(height: 20),

                    // Section Matakuliah Perlu Perbaikan (Nilai < B-)
                    if (data.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade300, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Matakuliah Perlu Perbaikan (${data.analisisSyarat.syaratNilaiMinimum.violatingMatkulCount} Matkul):',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFFC62828),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...data.analisisSyarat.syaratNilaiMinimum.violatingMatkul.map(
                              (m) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        m.nilai,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${m.kode} - ${m.mkl} (${m.sks} SKS)',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // Close bottom sheet
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SpPage(onBack: () => Navigator.pop(context)),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC62828),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 1,
                                ),
                                icon: const Icon(CupertinoIcons.layers_alt_fill, size: 16),
                                label: const Text(
                                  'Perbaiki via Semester Pendek (SP)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 20),
                    ],

                    // Section Rekomendasi Tindakan
                    if (data.rekomendasiTindakan.isNotEmpty) ...[
                      GlassCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(CupertinoIcons.lightbulb_fill, color: Color(0xFFE65100), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Rekomendasi Langkah / Tindakan:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFF501F66),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...data.rekomendasiTindakan.map(
                              (saran) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                                    Expanded(
                                      child: Text(
                                        saran,
                                        style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoBadge(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 9, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSyaratItem({
    required String title,
    required SyaratDetail detail,
    required IconData icon,
  }) {
    final isOk = detail.isFulfilled;
    final statusColor = isOk ? Colors.green : Colors.red;

    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOk ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.xmark_circle_fill,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isOk ? const Color(0xFF501F66) : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.description,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3),
                ),
                if (detail.currentVal.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Saat ini: ${detail.currentVal}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

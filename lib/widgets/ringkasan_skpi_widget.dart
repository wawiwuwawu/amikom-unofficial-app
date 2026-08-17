import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transkrip.dart';
import '../pages/sertifikasi_page.dart';
import '../pages/prestasi_page.dart';
import 'glass_card.dart';

class RingkasanSkpiWidget extends StatelessWidget {
  final SkpiData data;

  const RingkasanSkpiWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isEligible = data.isSkpiEligible;
    final poin = data.skkmPoinInfo.estimasiPoinSkkm;
    final pct = (poin / 100.0).clamp(0.0, 1.0);
    final statusColor = isEligible ? Colors.green : Colors.orange;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEligible ? CupertinoIcons.doc_checkmark_fill : CupertinoIcons.exclamationmark_circle_fill,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kecukupan SKPI & Poin SKKM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF501F66),
                      ),
                    ),
                    Text(
                      data.statusSkpi,
                      style: TextStyle(fontSize: 11, color: statusColor.shade900, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isEligible ? 'LULUS SKPI' : '$poin / 100 POIN',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar SKKM
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor.shade700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.skkmPoinInfo.description,
            style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Peringatan Kekurangan (If any)
          if (data.peringatanKekurangan.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.info_circle_fill, size: 14, color: Colors.deepOrange),
                      SizedBox(width: 6),
                      Text(
                        'Perhatian Tambahan SKPI:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...data.peringatanKekurangan.map(
                    (warn) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $warn',
                        style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Quick Actions Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SertifikasiPage(onBack: () => Navigator.pop(context))),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF501F66),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(CupertinoIcons.doc_append, size: 14),
                    label: const Text('Input Sertifikasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PrestasiPage(onBack: () => Navigator.pop(context))),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF501F66),
                      side: const BorderSide(color: Color(0xFF501F66)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(CupertinoIcons.star_fill, size: 14),
                    label: const Text('Input Prestasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }
}

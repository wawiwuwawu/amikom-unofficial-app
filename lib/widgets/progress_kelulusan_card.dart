import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transkrip.dart';
import '../pages/sp_page.dart';
import 'glass_card.dart';

class ProgressKelulusanCard extends StatefulWidget {
  final ProgressKelulusanData data;

  const ProgressKelulusanCard({super.key, required this.data});

  @override
  State<ProgressKelulusanCard> createState() => _ProgressKelulusanCardState();
}

class _ProgressKelulusanCardState extends State<ProgressKelulusanCard> {
  int _selectedJalur = 0; // 0: Skripsi Reguler, 1: Technopreneur IT

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final pct = (d.persentaseKelulusan / 100.0).clamp(0.0, 1.0);
    final wisuda = d.kelayakanAkademikWisuda;
    final jalur = d.jalurKelulusan;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF501F66).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF501F66), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress Kelulusan & Wisuda',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF501F66),
                      ),
                    ),
                    Text(
                      '${d.prodi} (${d.jenjang})',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF501F66),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${d.persentaseKelulusan.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF501F66)),
            ),
          ),
          const SizedBox(height: 10),

          // Stats Subrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${d.totalSksLulus} / ${d.targetSks} SKS Lulus',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'Sisa ${d.sisaSks} SKS • ~${d.estimasiSisaSemester} Smt Lg',
                style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wisuda Eligibility Warning (If D/E exists)
          if (!wisuda.bebasNilaiDEEligible && wisuda.warningWisuda.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.deepOrange, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Syarat Bebas Nilai D/E Wisuda',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE65100)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    wisuda.warningWisuda,
                    style: const TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3),
                  ),
                  if (wisuda.dEMatkulItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...wisuda.dEMatkulItems.map((item) => Text(
                          '• ${item.kode} - ${item.mkl} (${item.sks} SKS): Nilai ${item.nilai}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        )),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SpPage(onBack: () => Navigator.pop(context))),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(CupertinoIcons.layers_alt_fill, size: 14),
                        label: const Text('Daftar Semester Pendek (SP)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Segmented Control Jalur Kelulusan
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedJalur = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedJalur == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedJalur == 0
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : [],
                      ),
                      child: Text(
                        '📘 Skripsi Reguler',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedJalur == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedJalur == 0 ? const Color(0xFF501F66) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedJalur = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedJalur == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedJalur == 1
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : [],
                      ),
                      child: Text(
                        '🚀 Technopreneur IT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedJalur == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedJalur == 1 ? const Color(0xFF501F66) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Content based on Selected Jalur
          if (_selectedJalur == 0) ...[
            // Skripsi Reguler
            Row(
              children: [
                _statusCheckBadge('PKL / Magang', jalur.skripsiReguler.pklEligible),
                const SizedBox(width: 8),
                _statusCheckBadge('Skripsi', jalur.skripsiReguler.skripsiEligible),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              jalur.skripsiReguler.skripsiEligible
                  ? 'Anda sudah memenuhi syarat untuk mengajukan Skripsi.'
                  : 'Membutuhkan ${jalur.skripsiReguler.sisaSksMenujuSkripsi} SKS lagi menuju pengajuan Skripsi.',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ] else ...[
            // Technopreneur IT
            Row(
              children: [
                _statusCheckBadge('SKS & IPK (>=140 SKS)', jalur.technopreneurIt.eligibleSksIpk),
                const SizedBox(width: 8),
                Text(
                  'Sisa ${jalur.technopreneurIt.sisaSksMenuju140} SKS',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Syarat Tambahan Jalur Startup:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            ...jalur.technopreneurIt.syaratTambahan.map((syarat) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.smallcircle_fill_circle, size: 10, color: Color(0xFF501F66)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          syarat,
                          style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _statusCheckBadge(String label, bool isOk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOk ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isOk ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.xmark_circle_fill,
            size: 12,
            color: isOk ? Colors.green.shade800 : Colors.red.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isOk ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

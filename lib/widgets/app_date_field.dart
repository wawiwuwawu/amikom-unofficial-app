import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/waktu.dart';

/// Field tanggal seragam untuk semua form — pengganti pola
/// `InkWell + InputDecorator + showDatePicker` yang sebelumnya diduplikasi
/// 3 halaman (izin penelitian, surat tugas ×4, PPKS).
///
///  * Tampilan: ikon kalender + tanggal lengkap Indonesia ("8 November 2026")
///    via [formatTanggalIndo]; belum dipilih → [hint] (default "Pilih Tanggal").
///  * Ketukan membuka kalender Material yang kini berbahasa Indonesia
///    (MaterialApp di-set `locale: id` — lihat `main.dart`).
///  * `defaultDate` mengisi nilai awal (mis. `DateTime.now()` untuk kasus
///    yang ingin default hari ini) tanpa memicu onChanged.
///  * `minDate` membatasi pilihan ke atasnya — untuk field Selesai yang tak
///    boleh mendahului Mulai; bila hasil pilihan lebih awal, di-clamp otomatis.
///
/// Batal/keluar dialog TIDAK memicu onChanged.
class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;

  /// Dipanggil dengan tanggal terpilih; dipanggil dengan nilai ter-clamp
  /// bila [minDate] terlewati. Tidak dipanggil bila dialog ditutup tanpa pilih.
  final ValueChanged<DateTime> onChanged;

  /// Fallback titik awal kalender bila [value] masih kosong.
  final DateTime? defaultDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Batas bawah nilai (mis. tanggal mulai untuk field tanggal selesai).
  final DateTime? minDate;
  final String? hint;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.defaultDate,
    this.firstDate,
    this.lastDate,
    this.minDate,
    this.hint,
  });

  Future<void> _pilih(BuildContext context) async {
    final batasAwal = firstDate ?? DateTime(2020);
    final awal = minDate != null && minDate!.isAfter(batasAwal)
        ? minDate!
        : batasAwal;
    final awalDialog =
        value ?? (minDate ?? defaultDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate:
          awalDialog.isBefore(awal) ? awal : awalDialog,
      firstDate: awal,
      lastDate: lastDate ?? DateTime(2035),
    );
    if (picked == null) return;
    // Clamp: field Selesai tidak boleh mendahului Mulai.
    onChanged(minDate != null && picked.isBefore(minDate!) ? minDate! : picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pilih(context),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            CupertinoIcons.calendar,
            color: AppColors.primary,
          ),
        ),
        child: Text(
          value != null ? formatTanggalIndo(value!) : (hint ?? 'Pilih Tanggal'),
          style: AppText.bodySm.copyWith(
            color: value != null ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

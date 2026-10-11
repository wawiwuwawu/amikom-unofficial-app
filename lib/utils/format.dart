import 'package:intl/intl.dart';

/// Helper format bersama untuk halaman — menggantikan salinan metode privat
/// yang sebelumnya diduplikasi di beberapa State (keuangan ×4, tanggal ×3).

/// Rupiah tanpa desimal: "Rp 1.500.000".
String formatRupiah(int number) => NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);

/// Label semester akademik (1 = Ganjil, 2 = Genap).
String semesterLabel(int semester) => switch (semester) {
      1 => 'Ganjil',
      2 => 'Genap',
      _ => 'Semester $semester',
    };

/// Format tanggal untuk payload API (yyyy-MM-dd).
String formatDateApi(DateTime dt) {
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '${dt.year}-$month-$day';
}

/// Format tanggal untuk tampilan (d/M/yyyy).
String formatDateDisplay(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

/// Opsi tahun untuk dropdown (tahun berjalan mundur 4 tahun).
List<int> yearOptions() =>
    List.generate(5, (index) => DateTime.now().year - index);

/// Urutan hari untuk pengelompokan jadwal (Senin = 1 … Minggu = 7).
/// Bucket di luar hari biasa: "Lainnya" (8) dan "Tanpa Jadwal" (9) —
/// keduanya selalu dirender paling bawah.
int dayValue(String day) => switch (day.toLowerCase().trim()) {
      'senin' => 1,
      'selasa' => 2,
      'rabu' => 3,
      'kamis' => 4,
      'jumat' || "jum'at" => 5,
      'sabtu' => 6,
      'minggu' => 7,
      'lainnya' => 8,
      'tanpa jadwal' => 9,
      _ => 8,
    };

/// Label tampilan untuk judul seksi hari agenda — hanya bucket khusus yang
/// diterjemahkan, hari biasa apa adanya.
String agendaDayLabel(String day) =>
    day.trim().toLowerCase() == 'tanpa jadwal' ? 'Belum ada jadwal' : day;

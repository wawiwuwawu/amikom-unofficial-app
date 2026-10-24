import '../models/agenda_terpadu.dart';

/// Helper waktu bersama untuk agenda (beranda + jadwal + pengingat jadwal) —
/// menggantikan salinan metode privat yang sebelumnya hidup terpisah di
/// dashboard_page (`_timeToMinutes`, `_ongoingRange`, `_getHariIndo`) dan
/// jadwal_page (`_jamChip`).

/// Parse "hh:mm" (juga menerima "hh.mm") menjadi menit sejak tengah malam.
/// Tidak bisa diparse → 0.
int timeToMinutes(String timeStr) {
  final clean = timeStr.trim().replaceAll('.', ':');
  final parts = clean.split(':');
  if (parts.length >= 2) {
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }
  return 0;
}

/// Rentang (mulai, selesai) dalam menit untuk deteksi "berlangsung" — dari
/// [AgendaItem]. `jamMulai`/`jamSelesai` dipilih bila keduanya terisi
/// (respons baru); jika tidak, jatuh ke parsing `jam` "hh:mm - hh:mm"
/// (respons lama). Marker kosong `'-'` dan jam tanpa angka → null (kosong).
(int, int)? ongoingRange(AgendaItem item) {
  if (item.jamMulai.isNotEmpty && item.jamSelesai.isNotEmpty) {
    return (timeToMinutes(item.jamMulai), timeToMinutes(item.jamSelesai));
  }
  final parts = item.jam.split('-');
  if (parts.length >= 2) {
    final a = parts[0].trim();
    final b = parts[1].trim();
    final adaAngka = RegExp(r'\d');
    if (a.isNotEmpty && b.isNotEmpty && adaAngka.hasMatch(a) && adaAngka.hasMatch(b)) {
      return (timeToMinutes(a), timeToMinutes(b));
    }
  }
  return null;
}

/// Chip jam tampilan: utamakan `jam_mulai` (marker kosong portal adalah '-',
/// bukan string kosong), jatuh ke `jam` warisan. Satu sumber untuk predikat
/// "berjam" supaya tak ada divergensi antara aturan tampil dan tampilan.
String jamChip(AgendaItem i) {
  final m = i.jamMulai.trim();
  if (m.isNotEmpty && m != '-') return m;
  final j = i.jam.trim();
  return j.isEmpty || j == '-' ? '-' : j;
}

/// Nama hari Indonesia dari `DateTime.weekday` (Senin = 1 … Minggu = 7) —
/// selaras pemetaan `dayValue` di `lib/utils/format.dart`.
String namaHariDariWeekday(int weekday) => switch (weekday) {
      DateTime.monday => 'Senin',
      DateTime.tuesday => 'Selasa',
      DateTime.wednesday => 'Rabu',
      DateTime.thursday => 'Kamis',
      DateTime.friday => 'Jumat',
      DateTime.saturday => 'Sabtu',
      DateTime.sunday => 'Minggu',
      _ => 'Senin',
    };

/// Parse tanggal "dd-MM-yyyy" (format portal jadwal ujian, UTS maupun UAS)
/// menjadi [DateTime] tengah malam waktu lokal. Null bila kosong, bukan
/// format, atau rentangnya tidak valid (mis. 32-13-2026). Sumber tunggal —
/// dipakai periode ujian, gerbang tampil ujian, dan pengingat jadwal.
DateTime? tanggalDariDdMmYyyy(String teks) {
  final parts = teks.trim().split('-');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final t = DateTime(y, m, d);
  if (t.year != y || t.month != m || t.day != d) return null;
  return t;
}

/// Format tanggal Bahasa Indonesia untuk tampilan: "24 November 2026".
String formatTanggalIndo(DateTime dt) {
  const bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
}

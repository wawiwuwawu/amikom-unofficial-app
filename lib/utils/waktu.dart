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

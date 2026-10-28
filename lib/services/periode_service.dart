import '../models/app_failure.dart';
import 'api_client.dart';

/// Flag periode KRS dari `GET /api/v1/periode?scope=krs` (kontrak BE
/// 2026-10-29, panduan-implement-fe §2.3). `dibuka` dihitung BE dari rentang
/// tanggal portal yang berhasil di-parse — `false` + tanggal `null` berarti
/// portal mengirim teks yang tak bisa di-parse (fail-open BE, bukan tebakan).
class PeriodeKrsData {
  final bool dibuka;

  /// Rentang periode ISO `yyyy-MM-dd`; null bila BE gagal mem-parse.
  final String? mulai;
  final String? selesai;

  const PeriodeKrsData({required this.dibuka, this.mulai, this.selesai});

  factory PeriodeKrsData.fromJson(Map<String, dynamic> json) {
    String? tanggal(dynamic raw) {
      final s = raw?.toString() ?? '';
      return s.isEmpty ? null : s;
    }

    return PeriodeKrsData(
      dibuka: json['dibuka'] == true,
      mulai: tanggal(json['mulai']),
      selesai: tanggal(json['selesai']),
    );
  }

  /// Identitas periode: penutupan banner disimpan per kunci ini, jadi periode
  /// baru (rentang tanggal berbeda) otomatis menampilkan banner lagi tanpa
  /// perlu durasi sembunyi seperti banner SP.
  String get kunci => '$mulai..$selesai';

  /// Label rentang ramah-baca dari tanggal ISO, mis. "2 – 7 November 2026".
  /// Tanggal tak-valid/null → null (banner tampil tanpa baris tanggal).
  String? get labelRentang {
    final a = _tanggalIsoKeLabel(mulai);
    final b = _tanggalIsoKeLabel(selesai);
    if (a == null && b == null) return null;
    if (a != null && b != null) return '$a – $b';
    return a ?? b;
  }

  static String? _tanggalIsoKeLabel(String? iso) {
    if (iso == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (m == null) return null;
    final bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
      'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final idx = int.tryParse(m.group(2)!);
    if (idx == null || idx < 1 || idx > 12) return null;
    return '${int.parse(m.group(3)!)} ${bulan[idx - 1]} ${m.group(1)}';
  }
}

class PeriodeService {
  final _dio = ApiClient.instance.dio;

  /// Ambil flag periode KRS saja (`scope=krs` — BE hanya men-scrape scope
  /// yang diminta, jadi ini murah dan aman dipanggil tiap muat beranda).
  /// Gagal melempar AppFailure; pemanggil memakai catchError → banner tidak
  /// tampil (fail-open, perilaku lama tanpa endpoint).
  Future<PeriodeKrsData> getPeriodeKrs() =>
      ApiClient.guard<PeriodeKrsData>(() async {
        final response = await _dio.get(
          '/api/v1/periode',
          queryParameters: {'scope': 'krs'},
        );
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        final krs = data['krs'];
        if (krs is! Map) {
          throw AppFailure('Respons periode tidak dikenal');
        }
        return PeriodeKrsData.fromJson(Map<String, dynamic>.from(krs));
      }, 'Gagal memuat periode KRS');
}

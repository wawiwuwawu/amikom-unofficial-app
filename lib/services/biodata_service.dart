import 'package:dio/dio.dart';

import '../models/biodata.dart';
import 'api_client.dart';

/// Service biodata mahasiswa (`GET /api/v1/biodata`).
///
/// Data bersifat PII — TIDAK di-cache ke disk (aturan §0.5); setiap buka
/// halaman Profil memanggil ulang. Seluruh galat dipetakan ke `AppFailure`
/// ramah lewat [ApiClient.guard] (pola §8.3).
class BiodataService {
  static const _endpoint = '/api/v1/biodata';

  final Dio _dio = ApiClient.instance.dio;

  Future<Biodata> getBiodata() => ApiClient.guard<Biodata>(() async {
        final response = await _dio.get(_endpoint);
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return Biodata.fromJson(data);
      }, 'Gagal memuat biodata. Silakan coba lagi.');
}

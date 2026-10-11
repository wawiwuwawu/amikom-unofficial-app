import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/nilai_rincian.dart';

class NilaiService {
  final Dio _dio;

  NilaiService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  /// Mengambil rincian nilai berdasarkan tahun akademik dan/atau semester.
  /// Memanggil GET /api/v1/nilai/rincian dan unwrap menggunakan ApiClient.unwrapRoot(response.data).
  Future<RincianNilaiResponse> getRincianNilai({
    String? thnAkademik,
    String? semester,
  }) =>
      ApiClient.guard<RincianNilaiResponse>(() async {
        final queryParams = <String, dynamic>{};
        if (thnAkademik != null && thnAkademik.trim().isNotEmpty) {
          queryParams['thn_akademik'] = thnAkademik.trim();
        }
        if (semester != null && semester.trim().isNotEmpty) {
          queryParams['semester'] = semester.trim();
        }

        final response = await _dio.get(
          '/api/v1/nilai/rincian',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        final root = ApiClient.unwrapRoot(response.data);
        return RincianNilaiResponse.fromJson(root);
      }, 'Gagal memuat rincian nilai');

  /// Mengambil daftar tahun akademik untuk filter nilai.
  /// Memanggil GET /api/v1/nilai/tahun-akademik dan unwrap menggunakan `ApiClient.unwrapData<List>(response.data)`.
  Future<List<NilaiOpsiItem>> getTahunAkademikList() =>
      ApiClient.guard<List<NilaiOpsiItem>>(() async {
        final response = await _dio.get('/api/v1/nilai/tahun-akademik');
        final list = ApiClient.unwrapData<List>(response.data);
        return list
            .map((e) => NilaiOpsiItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }, 'Gagal memuat opsi tahun akademik');

  /// Mengambil daftar semester untuk filter nilai.
  /// Memanggil GET /api/v1/nilai/semester dan unwrap menggunakan `ApiClient.unwrapData<List>(response.data)`.
  Future<List<NilaiOpsiItem>> getSemesterList({String? thnAkademik}) =>
      ApiClient.guard<List<NilaiOpsiItem>>(() async {
        final queryParams = <String, dynamic>{};
        if (thnAkademik != null && thnAkademik.trim().isNotEmpty) {
          queryParams['thn_akademik'] = thnAkademik.trim();
        }

        final response = await _dio.get(
          '/api/v1/nilai/semester',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        final list = ApiClient.unwrapData<List>(response.data);
        return list
            .map((e) => NilaiOpsiItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }, 'Gagal memuat opsi semester');
}

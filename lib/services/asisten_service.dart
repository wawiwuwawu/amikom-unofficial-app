import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/api_response.dart';
import '../models/asisten.dart';

class AsistenService {
  final _dio = ApiClient.instance.dio;

  Future<AsistenInfo> getInfo() async {
    try {
      final response = await _dio.get('/api/v1/asisten/info');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return AsistenInfo.fromJson(data);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat info asisten');
    }
  }

  Future<AsistenTahunAkademikResponse> getTahunAkademik() async {
    try {
      final response = await _dio.get('/api/v1/asisten/tahun-akademik');
      final root = ApiClient.unwrapRoot(response.data);
      return AsistenTahunAkademikResponse.fromJson(root);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat tahun akademik');
    }
  }

  Future<AsistenJadwalResponse> getJadwal({
    String? tahun,
    int offset = 0,
    int limit = 10,
    String? sortBy,
    String? sort,
  }) async {
    try {
      Map<String, dynamic> params = {
        'offset': offset,
        'limit': limit,
      };
      if (tahun != null && tahun.isNotEmpty) params['tahun'] = tahun;
      if (sortBy != null && sortBy.isNotEmpty) params['sort_by'] = sortBy;
      if (sort != null && sort.isNotEmpty) params['sort'] = sort;

      final response = await _dio.get('/api/v1/asisten/jadwal', queryParameters: params);
      final root = ApiClient.unwrapRoot(response.data);
      return AsistenJadwalResponse.fromJson(root);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat jadwal asisten');
    }
  }

  Future<AsistenLaporan> getLaporan() async {
    try {
      final response = await _dio.get('/api/v1/asisten/laporan');
      final root = ApiClient.unwrapRoot(response.data);
      return AsistenLaporan.fromJson(root);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat laporan asisten');
    }
  }

  Future<MutationResult> pengajuanBebasKp({String act = 'ajukan'}) async {
    try {
      final response = await _dio.post(
        '/api/v1/asisten/pengajuan-bebas-kp',
        queryParameters: {'act': act},
        data: {},
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw _handleError(e, 'Gagal memproses pengajuan bebas KP');
    }
  }

  Exception _handleError(dynamic e, [String fallback = 'Terjadi kesalahan pada layanan Asisten']) {
    if (e is DioException) {
      return ApiClient.handleError(e, fallback);
    }
    if (e is Exception) {
      return e;
    }
    return Exception(e?.toString() ?? fallback);
  }
}

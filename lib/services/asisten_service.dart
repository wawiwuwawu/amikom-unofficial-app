import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/asisten.dart';

class AsistenService {
  final _dio = ApiClient.instance.dio;

  Future<AsistenInfo> getInfo() async {
    try {
      final response = await _dio.get('/api/v1/asisten/info');
      return AsistenInfo.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AsistenTahunAkademikResponse> getTahunAkademik() async {
    try {
      final response = await _dio.get('/api/v1/asisten/tahun-akademik');
      return AsistenTahunAkademikResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
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
      return AsistenJadwalResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AsistenLaporan> getLaporan() async {
    try {
      final response = await _dio.get('/api/v1/asisten/laporan');
      return AsistenLaporan.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> pengajuanBebasKp() async {
    try {
      await _dio.post('/api/v1/asisten/pengajuan-bebas-kp', data: {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException && e.response != null) {
      final msg = e.response?.data?['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return Exception(msg);
      }
      return Exception(e.message ?? 'Terjadi kesalahan pada layanan Asisten');
    }
    return Exception(e.toString());
  }
}

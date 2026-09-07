import 'package:dio/dio.dart';
import '../models/izin_penelitian.dart';
import 'api_client.dart';

class IzinPenelitianService {
  final Dio _dio;

  IzinPenelitianService() : _dio = ApiClient.instance.dio;

  Future<IzinPenelitianData> getIzinPenelitianData() async {
    try {
      final response = await _dio.get('/api/v1/izin-penelitian');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return IzinPenelitianData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat data Izin Penelitian');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Izin Penelitian');
    }
  }

  Future<Map<String, dynamic>> submitIzinPenelitian(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        '/api/v1/izin-penelitian',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Gagal menambahkan pengajuan izin penelitian');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambahkan pengajuan izin penelitian');
    }
  }

  Future<Map<String, dynamic>> deleteIzinPenelitian(String id) async {
    try {
      final response = await _dio.delete('/api/v1/izin-penelitian/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data ?? {'success': true, 'message': 'Pengajuan Berhasil Dihapus'};
      }
      throw Exception(response.data?['message'] ?? 'Gagal menghapus pengajuan izin penelitian');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus pengajuan izin penelitian');
    }
  }
}

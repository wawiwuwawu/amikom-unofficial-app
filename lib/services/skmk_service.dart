import 'package:dio/dio.dart';
import '../models/skmk.dart';
import 'api_client.dart';

class SkmkService {
  final Dio _dio;

  SkmkService() : _dio = ApiClient.instance.dio;

  Future<SkmkData> getSkmkData() async {
    try {
      final response = await _dio.get('/api/v1/skmk');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SkmkData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat data pengajuan SKMK');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data pengajuan SKMK');
    }
  }

  Future<Map<String, dynamic>> submitSkmk(String keperluan, String ortu) async {
    try {
      final response = await _dio.post(
        '/api/v1/skmk',
        data: {
          'keperluan': keperluan,
          'ortu': ortu,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Gagal menambahkan pengajuan SKMK');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambahkan pengajuan SKMK');
    }
  }

  Future<Map<String, dynamic>> deleteSkmk(String id) async {
    try {
      final response = await _dio.delete('/api/v1/skmk/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data ?? {'success': true, 'message': 'Pengajuan Berhasil Dihapus'};
      }
      throw Exception(response.data?['message'] ?? 'Gagal menghapus pengajuan SKMK');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus pengajuan SKMK');
    }
  }
}

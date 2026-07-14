import 'package:dio/dio.dart';
import '../models/pusat_studi.dart';
import 'api_client.dart';

class PusatStudiService {
  final Dio _dio;

  PusatStudiService() : _dio = ApiClient.instance.dio;

  Future<List<PusatStudi>> getPusatStudiList() async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => PusatStudi.fromJson(e)).toList();
      }
      throw Exception('Gagal memuat daftar pusat studi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<List<PusatStudi>> getJoinedPusatStudi() async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi/joined');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => PusatStudi.fromJson(e)).toList();
      }
      throw Exception('Gagal memuat pusat studi yang diikuti');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> joinPusatStudi(String id) async {
    try {
      final response = await _dio.post('/api/v1/pusat-studi/join', data: {'id': id});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Gagal bergabung dengan pusat studi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<PusatStudiDetail> getDetailPusatStudi(String base64Id) async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi/$base64Id');
      if (response.statusCode == 200) {
        return PusatStudiDetail.fromJson(response.data['data'] ?? {});
      }
      throw Exception('Gagal memuat detail pusat studi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<List<JoinedDetailTema>> getJoinedDetail(String id) async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi/$id/joined-detail');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => JoinedDetailTema.fromJson(e)).toList();
      }
      throw Exception('Gagal memuat detail tema pusat studi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> proposeTema(String idps, String judul, String deskripsi, String rencanaJudul) async {
    try {
      final response = await _dio.post(
        '/api/v1/pusat-studi/$idps/propose-tema',
        data: {
          'judul': judul,
          'deskripsi': deskripsi,
          'rencana_judul': rencanaJudul,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Gagal mengusulkan tema');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> chooseTema(String idps, String idTema, String judul, String rencanaJudul) async {
    try {
      final response = await _dio.post(
        '/api/v1/pusat-studi/$idps/choose-tema',
        data: {
          'id_tema': idTema,
          'judul': judul,
          'rencana_judul': rencanaJudul,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Gagal memilih tema');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}

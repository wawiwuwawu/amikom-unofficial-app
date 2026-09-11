import 'package:dio/dio.dart';
import '../models/pusat_studi.dart';
import 'api_client.dart';

class PusatStudiService {
  final Dio _dio;

  PusatStudiService() : _dio = ApiClient.instance.dio;

  Future<List<PusatStudi>> getPusatStudiList() async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => PusatStudi.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat daftar pusat studi');
    }
  }

  Future<List<PusatStudi>> getJoinedPusatStudi() async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi/joined');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => PusatStudi.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pusat studi yang diikuti');
    }
  }

  Future<Map<String, dynamic>> joinPusatStudi(String id) async {
    try {
      final response = await _dio.post('/api/v1/pusat-studi/join', data: {'id': id});
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal bergabung dengan pusat studi');
    }
  }

  Future<PusatStudiDetail> getDetailPusatStudi(String base64Id) async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi/$base64Id');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is Map<String, dynamic>) {
        return PusatStudiDetail.fromJson(data);
      } else if (data is Map) {
        return PusatStudiDetail.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Gagal memuat detail pusat studi');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat detail pusat studi');
    }
  }

  Future<List<JoinedDetailTema>> getJoinedDetail(String id) async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi/$id/joined-detail');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => JoinedDetailTema.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat detail tema pusat studi');
    }
  }

  Future<PusatStudiJoinedPageData?> getJoinedPage(String base64Id) async {
    try {
      final response = await _dio.get('/api/v1/pusat-studi/$base64Id/joined-page');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data != null) {
        if (data is Map<String, dynamic>) {
          return PusatStudiJoinedPageData.fromJson(data);
        } else if (data is Map) {
          return PusatStudiJoinedPageData.fromJson(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat halaman pusat studi');
    }
  }

  Future<Map<String, dynamic>> cancelAjuan(String idAjuan) async {
    try {
      final response = await _dio.post(
        '/api/v1/pusat-studi/cancel-ajuan',
        data: {'id_ajuan': idAjuan},
      );
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal membatalkan ajuan');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengusulkan tema');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memilih tema');
    }
  }
}

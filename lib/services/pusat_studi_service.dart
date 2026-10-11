import 'package:dio/dio.dart';
import '../models/pusat_studi.dart';
import 'api_client.dart';
import '../models/app_failure.dart';

class PusatStudiService {
  final Dio _dio;

  PusatStudiService() : _dio = ApiClient.instance.dio;

  Future<List<PusatStudi>> getPusatStudiList() =>
      ApiClient.guard<List<PusatStudi>>(() async {
        final response = await _dio.get('/api/v1/pusat-studi');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<PusatStudi>(data, PusatStudi.fromJson);
      }, 'Gagal memuat daftar pusat studi');

  Future<List<PusatStudi>> getJoinedPusatStudi() =>
      ApiClient.guard<List<PusatStudi>>(() async {
        final response = await _dio.get('/api/v1/pusat-studi/joined');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<PusatStudi>(data, PusatStudi.fromJson);
      }, 'Gagal memuat pusat studi yang diikuti');

  Future<Map<String, dynamic>> joinPusatStudi(String id) =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        final response =
            await _dio.post('/api/v1/pusat-studi/join', data: {'id': id});
        return ApiClient.mutationRoot(response.data);
      }, 'Gagal bergabung dengan pusat studi');

  Future<PusatStudiDetail> getDetailPusatStudi(String base64Id) =>
      ApiClient.guard<PusatStudiDetail>(() async {
        final response = await _dio.get('/api/v1/pusat-studi/$base64Id');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data is Map<String, dynamic>) {
          return PusatStudiDetail.fromJson(data);
        } else if (data is Map) {
          return PusatStudiDetail.fromJson(Map<String, dynamic>.from(data));
        }
        throw const AppFailure('Gagal memuat detail pusat studi');
      }, 'Gagal memuat detail pusat studi');

  Future<List<JoinedDetailTema>> getJoinedDetail(String id) =>
      ApiClient.guard<List<JoinedDetailTema>>(() async {
        final response = await _dio.get('/api/v1/pusat-studi/$id/joined-detail');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<JoinedDetailTema>(
            data, JoinedDetailTema.fromJson);
      }, 'Gagal memuat detail tema pusat studi');

  Future<PusatStudiJoinedPageData?> getJoinedPage(String base64Id) =>
      ApiClient.guard<PusatStudiJoinedPageData?>(() async {
        final response =
            await _dio.get('/api/v1/pusat-studi/$base64Id/joined-page');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data != null) {
          if (data is Map<String, dynamic>) {
            return PusatStudiJoinedPageData.fromJson(data);
          } else if (data is Map) {
            return PusatStudiJoinedPageData.fromJson(
                Map<String, dynamic>.from(data));
          }
        }
        return null;
      }, 'Gagal memuat halaman pusat studi');

  Future<Map<String, dynamic>> cancelAjuan(String idAjuan) =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        final response = await _dio.post(
          '/api/v1/pusat-studi/cancel-ajuan',
          data: {'id_ajuan': idAjuan},
        );
        return ApiClient.mutationRoot(response.data);
      }, 'Gagal membatalkan ajuan');

  Future<Map<String, dynamic>> proposeTema(String idps, String judul,
          String deskripsi, String rencanaJudul) =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        final response = await _dio.post(
          '/api/v1/pusat-studi/$idps/propose-tema',
          data: {
            'judul': judul,
            'deskripsi': deskripsi,
            'rencana_judul': rencanaJudul,
          },
        );
        return ApiClient.mutationRoot(response.data);
      }, 'Gagal mengusulkan tema');

  Future<Map<String, dynamic>> chooseTema(
          String idps, String idTema, String judul, String rencanaJudul) =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        final response = await _dio.post(
          '/api/v1/pusat-studi/$idps/choose-tema',
          data: {
            'id_tema': idTema,
            'rencana_judul': rencanaJudul,
          },
        );
        return ApiClient.mutationRoot(response.data);
      }, 'Gagal memilih tema');
}

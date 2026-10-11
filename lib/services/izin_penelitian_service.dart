import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/izin_penelitian.dart';
import 'api_client.dart';

class IzinPenelitianService {
  final Dio _dio;

  IzinPenelitianService() : _dio = ApiClient.instance.dio;

  Future<IzinPenelitianData> getIzinPenelitianData() =>
      ApiClient.guard<IzinPenelitianData>(() async {
        final response = await _dio.get('/api/v1/izin-penelitian');
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return IzinPenelitianData.fromJson(data);
      }, 'Gagal memuat data Izin Penelitian');

  Future<MutationResult> submitIzinPenelitian(Map<String, dynamic> body) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.post(
          '/api/v1/izin-penelitian',
          data: body,
        );
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menambahkan pengajuan izin penelitian');

  Future<MutationResult> deleteIzinPenelitian(String id) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.delete('/api/v1/izin-penelitian/$id');
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menghapus pengajuan izin penelitian');
}

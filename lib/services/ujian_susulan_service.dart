import 'package:dio/dio.dart';
import '../models/ujian_susulan.dart';
import 'api_client.dart';

class UjianSusulanService {
  final Dio _dio;

  UjianSusulanService() : _dio = ApiClient.instance.dio;

  Future<UjianSusulanData> getUtsData() async {
    try {
      final response = await _dio.get('/api/v1/ujian-susulan/uts');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return UjianSusulanData.fromJson(data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Ujian Susulan UTS');
    }
  }

  Future<UjianSusulanData> getUasData() async {
    try {
      final response = await _dio.get('/api/v1/ujian-susulan/uas');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return UjianSusulanData.fromJson(data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Ujian Susulan UAS');
    }
  }
}

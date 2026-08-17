import 'package:dio/dio.dart';
import '../models/ujian_susulan.dart';
import 'api_client.dart';

class UjianSusulanService {
  final Dio _dio;

  UjianSusulanService() : _dio = ApiClient.instance.dio;

  Future<UjianSusulanData> getUtsData() async {
    try {
      final response = await _dio.get('/api/v1/ujian-susulan/uts');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return UjianSusulanData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat data Ujian Susulan UTS');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<UjianSusulanData> getUasData() async {
    try {
      final response = await _dio.get('/api/v1/ujian-susulan/uas');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return UjianSusulanData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat data Ujian Susulan UAS');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}

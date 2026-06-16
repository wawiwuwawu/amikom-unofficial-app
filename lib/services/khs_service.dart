import 'dart:io';

import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/khs.dart';

class KhsService {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/khs');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat data KHS');
    }
  }

  Future<KhsDetailResponse> getDetail(String thn, String smt) async {
    try {
      final response = await _dio.post(
        '/api/v1/khs/detail',
        data: {'thn': thn, 'smt': smt},
      );
      return KhsDetailResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat detail KHS');
    }
  }

  Future<String> download(String thn, String smt) async {
    try {
      final dir = Directory.systemTemp;
      final savePath =
          '${dir.path}/KHS_${thn.replaceAll('/', '_')}_SMT$smt.pdf';
      await _dio.download(
        '/api/v1/khs/download',
        savePath,
        data: {'thn': thn, 'smt': smt},
      );
      return savePath;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal mengunduh KHS');
    }
  }
}

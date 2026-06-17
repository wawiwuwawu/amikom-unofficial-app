import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<String> _downloadDir() async {
    if (Platform.isAndroid) {
      final download = Directory('/storage/emulated/0/Download');
      if (await download.exists()) {
        return download.path;
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<String> download(String thn, String smt) async {
    try {
      final dir = await _downloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final nama = ApiClient.instance.nama ?? '';
      final namaFile = nama.isNotEmpty ? '$nama ($nim)' : nim;
      final safeThn = thn.replaceAll('/', '_');
      final savePath = '$dir/KHS_${namaFile}_${safeThn}_SMT$smt.pdf';
      await _dio.download(
        '/api/v1/khs/download',
        savePath,
        data: {'thn': thn, 'smt': smt},
        options: Options(method: 'POST'),
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

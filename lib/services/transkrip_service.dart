import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../models/transkrip.dart';

class TranskripService {
  final _dio = ApiClient.instance.dio;

  Future<List<TranskripItem>> getTranskrip() async {
    try {
      final response = await _dio.get('/api/v1/transkrip');
      final list = (response.data as List)
          .map((e) => TranskripItem.fromJson(e))
          .toList();
      return list;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat transkrip');
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

  Future<String> download() async {
    try {
      final dir = await _downloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final nama = ApiClient.instance.nama ?? '';
      final namaFile = nama.isNotEmpty ? '$nama ($nim)' : nim;
      final savePath = '$dir/Transkrip_$namaFile.pdf';
      await _dio.download(
        '/api/v1/transkrip/download',
        savePath,
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
      throw Exception(e.message ?? 'Gagal mengunduh transkrip');
    }
  }
}

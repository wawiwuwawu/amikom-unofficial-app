import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../models/sertifikasi.dart';

class SertifikasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<SertifikasiItem>> getSertifikasi() async {
    try {
      final response = await _dio.get('/api/v1/sertifikasi-kompetensi');
      final data = response.data['data'] as List?;
      return data?.map((e) => SertifikasiItem.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat data Sertifikasi Kompetensi');
    }
  }

  Future<List<SertifikasiOption>> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/sertifikasi-kompetensi/options');
      final data = response.data['data'] as List?;
      return data?.map((e) => SertifikasiOption.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat pilihan Sertifikasi');
    }
  }

  Future<void> tambahSertifikasi(FormData data) async {
    try {
      await _dio.post(
        '/api/v1/sertifikasi-kompetensi',
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal menambahkan Sertifikasi Kompetensi');
    }
  }

  Future<void> hapusSertifikasi(int id) async {
    try {
      await _dio.delete('/api/v1/sertifikasi-kompetensi/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal menghapus Sertifikasi Kompetensi');
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

  Future<String> downloadFile(int id, String namaFile) async {
    try {
      final dir = await _downloadDir();
      final savePath = '$dir/$namaFile';
      await _dio.download(
        '/api/v1/sertifikasi-kompetensi/$id/file',
        savePath,
      );
      return savePath;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal mengunduh file sertifikat');
    }
  }
}

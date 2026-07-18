import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../models/organisasi.dart';

class OrganisasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<OrganisasiItem>> getOrganisasi() async {
    try {
      final response = await _dio.get('/api/v1/organisasi-mahasiswa');
      final data = response.data['data'] as List?;
      return data?.map((e) => OrganisasiItem.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat data Organisasi Mahasiswa');
    }
  }

  Future<OrganisasiOptionResponse> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/organisasi-mahasiswa/options');
      final data = response.data['data'];
      if (data != null && data is Map<String, dynamic>) {
        return OrganisasiOptionResponse.fromJson(data);
      }
      return OrganisasiOptionResponse(organisasi: [], jabatan: []);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat pilihan Organisasi');
    }
  }

  Future<void> tambahOrganisasi(FormData data) async {
    try {
      await _dio.post(
        '/api/v1/organisasi-mahasiswa',
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
      throw Exception(e.message ?? 'Gagal menambahkan Organisasi Mahasiswa');
    }
  }

  Future<void> hapusOrganisasi(int id) async {
    try {
      await _dio.delete('/api/v1/organisasi-mahasiswa/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal menghapus Organisasi Mahasiswa');
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
        '/api/v1/organisasi-mahasiswa/$id/file',
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
      throw Exception(e.message ?? 'Gagal mengunduh dokumen organisasi');
    }
  }
}

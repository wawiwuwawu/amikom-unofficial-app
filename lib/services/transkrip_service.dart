import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../models/transkrip.dart';
import '../models/histori_ipk.dart';

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

  Future<HistoriIpkData> getHistoriIpk() async {
    try {
      final response = await _dio.get('/api/v1/transkrip/histori-ipk');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return HistoriIpkData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat histori IPK');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat histori IPK');
    }
  }

  Future<CumlaudeData> getCumlaudeEligibility() async {
    try {
      final response = await _dio.get('/api/v1/transkrip/cumlaude');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return CumlaudeData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat evaluasi cumlaude');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat evaluasi cumlaude');
    }
  }

  Future<ProgressKelulusanData> getProgressKelulusan() async {
    try {
      final response = await _dio.get('/api/v1/transkrip/progress-kelulusan');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return ProgressKelulusanData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat progress kelulusan');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat progress kelulusan');
    }
  }

  Future<SkpiData> getRingkasanSkpi() async {
    try {
      final response = await _dio.get('/api/v1/aktivitas/ringkasan-skpi');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SkpiData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat ringkasan SKPI');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat ringkasan SKPI');
    }
  }

  Future<SimulasiIpkData> simulasiTargetIpk(double targetIpk) async {
    try {
      final response = await _dio.post(
        '/api/v1/transkrip/simulasi-target-ipk',
        data: {'target_ipk': targetIpk},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SimulasiIpkData.fromJson(response.data['data']);
      }
      throw Exception('Gagal melakukan simulasi target IPK');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal melakukan simulasi target IPK');
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

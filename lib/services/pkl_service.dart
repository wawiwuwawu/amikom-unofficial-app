import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pkl.dart';
import 'api_client.dart';

class PklService {
  final Dio _dio;

  PklService() : _dio = ApiClient.instance.dio;

  Future<PklData> getPklData() async {
    try {
      final response = await _dio.get('/api/v1/pkl');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return PklData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat data pendaftaran PKL');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> submitPkl(String jenis, String judul) async {
    try {
      final response = await _dio.post(
        '/api/v1/pkl',
        data: {
          'jenis': jenis,
          'judul': judul,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Gagal menambahkan pendaftaran PKL');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<String> downloadFormulirPkl(String idPengajuan) async {
    try {
      final dir = await _downloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final savePath = '$dir/Formulir_PKL_${idPengajuan}_$nim.pdf';

      await _dio.download(
        '/api/v1/pkl/download/$idPengajuan',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      return savePath;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> deletePkl(String idPengajuan) async {
    try {
      final response = await _dio.delete('/api/v1/pkl/$idPengajuan');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data ?? {'success': true, 'message': 'Pendaftaran PKL berhasil dihapus'};
      }
      throw Exception(response.data?['message'] ?? 'Gagal menghapus pendaftaran PKL');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
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
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/agenda.dart';
import '../models/jadwal_ujian.dart';
import '../models/agenda_terpadu.dart';

class AkademikService {
  final _dio = ApiClient.instance.dio;

  Future<List<Agenda>> getAgenda() async {
    try {
      final response = await _dio.get('/api/v1/akademik/agenda');
      final data = response.data['data'] as List?;
      if (data == null) return [];
      return data.map((e) => Agenda.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ponytail: centralized agenda terpadu alongside akademik agenda endpoints
  Future<AgendaTerpaduData> getAgendaTerpadu() async {
    try {
      final response = await _dio.get('/api/v1/agenda/terpadu');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return AgendaTerpaduData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat agenda terpadu');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat agenda terpadu');
    }
  }

  Future<List<JadwalUjian>> getJadwalUjian(String jenis) async {
    try {
      final response = await _dio.get(
        '/api/v1/akademik/jadwal-ujian',
        queryParameters: {'jenis': jenis},
      );
      final data = response.data['data'] as List?;
      if (data == null) return [];
      return data.map((e) => JadwalUjian.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> downloadKartuUjian(String jenis, {Function(int, int)? onReceiveProgress}) async {
    try {
      final dir = await ApiClient.getDownloadDir();
      final response = await _dio.get(
        '/api/v1/akademik/jadwal-ujian/download',
        queryParameters: {'jenis': jenis},
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onReceiveProgress,
      );
      
      String ext = '.pdf';
      final contentDisposition = response.headers.value('content-disposition');
      if (contentDisposition != null && contentDisposition.contains('filename=')) {
        final match = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
        if (match != null) {
          final fname = match.group(1);
          if (fname != null && fname.contains('.')) {
            ext = '.${fname.split('.').last}';
          }
        }
      }

      final nim = ApiClient.instance.nim ?? '';
      final savePath = '$dir/Kartu_Ujian_${jenis.toUpperCase()}_$nim$ext';
      
      final file = File(savePath);
      await file.writeAsBytes(response.data);
      
      return savePath;
    } catch (e) {
      throw _handleError(e);
    }
  }


  Exception _handleError(dynamic e) {
    if (e is DioException && e.response != null) {
      final msg = e.response?.data?['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return Exception(msg);
      }
      return Exception(e.message ?? 'Terjadi kesalahan');
    }
    return Exception(e.toString());
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../models/krs.dart';

class KrsService {
  final _dio = ApiClient.instance.dio;

  Future<KrsInfo> getInfo() async {
    try {
      final response = await _dio.get('/api/v1/krs');
      return KrsInfo.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<MatkulDitawarkanResponse> getMatkulDitawarkan() async {
    try {
      final response = await _dio.get('/api/v1/krs/matkul-ditawarkan');
      return MatkulDitawarkanResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<KrsPengajuanResponse> getPengajuan() async {
    try {
      final response = await _dio.get('/api/v1/krs/pengajuan');
      return KrsPengajuanResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> submitPengajuan(List<String> makul) async {
    try {
      await _dio.post('/api/v1/krs/pengajuan', data: {'makul': makul});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePengajuan(String id) async {
    try {
      await _dio.delete('/api/v1/krs/pengajuan/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<KrsPengisianResponse> getPengisian() async {
    try {
      final response = await _dio.get('/api/v1/krs/pengisian');
      return KrsPengisianResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> submitPengisian(Map<String, dynamic> formData) async {
    try {
      await _dio.post('/api/v1/krs/pengisian', data: {'formData': formData});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<KrsPengisianResponse> getBelumDiisi() async {
    try {
      final response = await _dio.get('/api/v1/krs/pengisian/belum-diisi');
      return KrsPengisianResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePengisian(String kode) async {
    try {
      await _dio.delete('/api/v1/krs/pengisian/$kode');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<JadwalKuliahResponse> getJadwal({String mod = 'kuliah_mbkm'}) async {
    try {
      final response = await _dio.get('/api/v1/krs/jadwal', queryParameters: {'mod': mod});
      return JadwalKuliahResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> sinkronisasi() async {
    try {
      await _dio.post('/api/v1/krs/sinkronisasi', data: {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> downloadKrs(Function(int, int)? onReceiveProgress) async {
    try {
      final dir = await _downloadDir();
      
      final response = await _dio.get(
        '/api/v1/krs/download',
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
      final nama = ApiClient.instance.nama ?? '';
      final namaFile = nama.isNotEmpty ? '$nama ($nim)' : nim;
      final savePath = '$dir/KRS_$namaFile$ext';
      
      final file = File(savePath);
      await file.writeAsBytes(response.data);
      
      return savePath;
    } catch (e) {
      throw _handleError(e);
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

  Exception _handleError(dynamic e) {
    if (e is DioException && e.response != null) {
      final msg = e.response?.data?['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return Exception(msg);
      }
      return Exception(e.message ?? 'Terjadi kesalahan request KRS');
    }
    return Exception(e.toString());
  }
}

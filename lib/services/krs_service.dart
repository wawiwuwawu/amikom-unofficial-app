import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/api_response.dart';
import '../models/krs.dart';

class KrsService {
  final _dio = ApiClient.instance.dio;

  Future<KrsInfo> getInfo() async {
    try {
      final response = await _dio.get('/api/v1/krs');
      final root = ApiClient.unwrapRoot(response.data);
      return KrsInfo.fromJson(root);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat informasi KRS');
    }
  }

  Future<MatkulDitawarkanResponse> getMatkulDitawarkan() async {
    try {
      final response = await _dio.get('/api/v1/krs/matkul-ditawarkan');
      final root = ApiClient.unwrapRoot(response.data);
      return MatkulDitawarkanResponse.fromJson(root);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat mata kuliah yang ditawarkan');
    }
  }

  Future<KrsPengajuanResponse> getPengajuan() async {
    try {
      final response = await _dio.get('/api/v1/krs/pengajuan');
      final root = ApiClient.unwrapRoot(response.data);
      return KrsPengajuanResponse.fromJson(root);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pengajuan KRS');
    }
  }

  Future<MutationResult> submitPengajuan(List<String> makul) async {
    try {
      final response = await _dio.post('/api/v1/krs/pengajuan', data: {'makul': makul});
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengajukan mata kuliah');
    }
  }

  Future<MutationResult> deletePengajuan(String id) async {
    try {
      final response = await _dio.delete('/api/v1/krs/pengajuan/$id');
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus pengajuan mata kuliah');
    }
  }

  Future<KrsPengisianResponse> getPengisian() async {
    try {
      final response = await _dio.get('/api/v1/krs/pengisian');
      final root = ApiClient.unwrapRoot(response.data);
      return KrsPengisianResponse.fromJson(root);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pengisian KRS');
    }
  }

  Future<MutationResult> submitPengisian(Map<String, dynamic> formData) async {
    try {
      final response = await _dio.post('/api/v1/krs/pengisian', data: {'formData': formData});
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menyimpan pengisian kelas');
    }
  }

  Future<KrsPengisianResponse> getBelumDiisi() async {
    try {
      final response = await _dio.get('/api/v1/krs/pengisian/belum-diisi');
      final root = ApiClient.unwrapRoot(response.data);
      return KrsPengisianResponse.fromJson(root);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat mata kuliah yang belum diisi');
    }
  }

  Future<MutationResult> deletePengisian(String kode) async {
    try {
      final response = await _dio.delete('/api/v1/krs/pengisian/$kode');
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus kelas pengisian');
    }
  }

  Future<JadwalKuliahResponse> getJadwal({String mod = 'kuliah_mbkm'}) async {
    try {
      final response = await _dio.get('/api/v1/krs/jadwal', queryParameters: {'mod': mod});
      final root = ApiClient.unwrapRoot(response.data);
      return JadwalKuliahResponse.fromJson(root);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat jadwal perkuliahan');
    }
  }

  Future<MutationResult> sinkronisasi() async {
    try {
      final response = await _dio.post('/api/v1/krs/sinkronisasi', data: {});
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal melakukan sinkronisasi KRS');
    }
  }

  Future<String> downloadKrs(Function(int, int)? onReceiveProgress) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      
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
      throw ApiClient.handleError(e, 'Gagal mengunduh KRS PDF');
    }
  }
}

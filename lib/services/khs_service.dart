import 'dart:io';

import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/khs.dart';

class KhsService {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getOptions() =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        // Tangkap semua error (bukan hanya DioException) supaya pesan teknis
        // dari Dio/parsing tidak pernah bocor ke UI.
        final response = await _dio.get('/api/v1/khs');
        return ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      }, 'Gagal memuat data KHS. Silakan coba lagi.');

  Future<KhsDetailResponse> getDetail(String thn, String smt) =>
      ApiClient.guard<KhsDetailResponse>(() async {
        final response = await _dio.post(
          '/api/v1/khs/detail',
          data: {'thn': thn, 'smt': smt},
        );
        return KhsDetailResponse.fromJson(
          ApiClient.unwrapData<Map<String, dynamic>>(response.data),
        );
      }, 'Gagal memuat detail KHS. Silakan coba lagi.');

  Future<String> download(String thn, String smt) =>
      ApiClient.guard<String>(() async {
        final nim = ApiClient.instance.nim ?? '';
        final namaFile = ApiClient.susunNamaBerkas(
          jenis: 'KHS',
          tahun: thn.replaceAll('/', '-'),
          semester: 'SMT$smt',
        );
        // ponytail: dio.download ke temp lalu pindah via MediaStore —
        // direct-write ke Download publik gagal di Android 10+ (scoped storage).
        final dir = await ApiClient.getDownloadDir();
        final tempPath =
            '$dir${Platform.pathSeparator}khs_tmp_$nim${DateTime.now().millisecondsSinceEpoch}.pdf';
        await _dio.download(
          '/api/v1/khs/download',
          tempPath,
          data: {'thn': thn, 'smt': smt},
          options: Options(method: 'POST'),
        );
        final bytes = await File(tempPath).readAsBytes();
        try {
          return await ApiClient.simpanKeDownload(namaFile, bytes);
        } finally {
          final temp = File(tempPath);
          if (await temp.exists()) await temp.delete();
        }
      }, 'Gagal mengunduh KHS. Silakan coba lagi.');
}

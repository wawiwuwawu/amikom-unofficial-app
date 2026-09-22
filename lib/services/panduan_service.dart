import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/panduan.dart';

class PanduanService {
  final _dio = ApiClient.instance.dio;

  Future<List<PanduanItem>> getList() async {
    try {
      final response = await _dio.get('/api/v1/panduan');
      // unwrapData melempar AppFailure ramah bila bentuk data server berbeda.
      final data = ApiClient.unwrapData<List<dynamic>>(response.data);
      return data.map((e) => PanduanItem.fromJson(e)).toList();
    } catch (e) {
      // Tangkap semua error agar pesan teknis (cast/parsing/Dio) tidak bocor.
      throw ApiClient.handleError(e, 'Gagal memuat daftar panduan. Silakan coba lagi.');
    }
  }

  Future<String> downloadPanduan(String link, String filename, Function(int, int)? onReceiveProgress) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      
      final response = await _dio.get(
        '/api/v1/panduan/download/$link',
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onReceiveProgress,
      );
      
      // Determine extension dynamically
      String ext = '.pdf'; // fallback default
      final contentDisposition = response.headers.value('content-disposition');
      if (contentDisposition != null && contentDisposition.contains('filename=')) {
        final match = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
        if (match != null) {
          final fname = match.group(1);
          if (fname != null && fname.contains('.')) {
            ext = '.${fname.split('.').last}';
          }
        }
      } else {
        final contentType = response.headers.value('content-type') ?? '';
        if (contentType.contains('wordprocessingml') || contentType.contains('msword')) {
          ext = '.docx';
        } else if (contentType.contains('spreadsheetml') || contentType.contains('ms-excel')) {
          ext = '.xlsx';
        } else if (contentType.contains('presentationml') || contentType.contains('ms-powerpoint')) {
          ext = '.pptx';
        } else if (contentType.contains('pdf')) {
          ext = '.pdf';
        } else if (contentType.contains('zip')) {
          ext = '.zip';
        } else if (contentType.contains('jpeg') || contentType.contains('jpg')) {
          ext = '.jpg';
        } else if (contentType.contains('png')) {
          ext = '.png';
        }
      }

      final savePath = '$dir/$filename$ext';
      final file = File(savePath);
      await file.writeAsBytes(response.data);
      
      return savePath;
    } catch (e) {
      // Termasuk kegagalan menulis berkas — tetap tampilkan pesan ramah.
      throw ApiClient.handleError(e, 'Gagal mengunduh panduan. Silakan coba lagi.');
    }
  }
}

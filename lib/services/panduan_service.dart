import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../models/panduan.dart';

class PanduanService {
  final _dio = ApiClient.instance.dio;

  Future<List<PanduanItem>> getList() async {
    try {
      final response = await _dio.get('/api/v1/panduan');
      final data = response.data['data'] as List;
      return data.map((e) => PanduanItem.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat daftar panduan');
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

  Future<String> downloadPanduan(String link, String filename, Function(int, int)? onReceiveProgress) async {
    try {
      final dir = await _downloadDir();
      
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
        if (contentType.contains('wordprocessingml') || contentType.contains('msword')) ext = '.docx';
        else if (contentType.contains('spreadsheetml') || contentType.contains('ms-excel')) ext = '.xlsx';
        else if (contentType.contains('presentationml') || contentType.contains('ms-powerpoint')) ext = '.pptx';
        else if (contentType.contains('pdf')) ext = '.pdf';
        else if (contentType.contains('zip')) ext = '.zip';
        else if (contentType.contains('jpeg') || contentType.contains('jpg')) ext = '.jpg';
        else if (contentType.contains('png')) ext = '.png';
      }

      final savePath = '$dir/$filename$ext';
      final file = File(savePath);
      await file.writeAsBytes(response.data);
      
      return savePath;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal mengunduh panduan');
    }
  }
}


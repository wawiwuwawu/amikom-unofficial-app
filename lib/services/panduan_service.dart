import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/panduan.dart';

class PanduanService {
  final _dio = ApiClient.instance.dio;

  Future<List<PanduanItem>> getList() =>
      ApiClient.guard<List<PanduanItem>>(() async {
        final response = await _dio.get('/api/v1/panduan');
        // unwrapData melempar AppFailure ramah bila bentuk data server berbeda.
        final data = ApiClient.unwrapData<List<dynamic>>(response.data);
        return data.map((e) => PanduanItem.fromJson(e)).toList();
      }, 'Gagal memuat daftar panduan. Silakan coba lagi.');

  Future<String> downloadPanduan(
          String link, String filename, Function(int, int)? onReceiveProgress) =>
      ApiClient.guard<String>(() async {
        final response = await _dio.get(
          '/api/v1/panduan/download/$link',
          options: Options(responseType: ResponseType.bytes),
          onReceiveProgress: onReceiveProgress,
        );

        // Determine extension dynamically
        final contentDisposition = response.headers.value('content-disposition');
        final String ext;
        if (contentDisposition != null &&
            contentDisposition.contains('filename=')) {
          ext = ApiClient.extensionFromHeaders(response.headers);
        } else {
          final contentType = response.headers.value('content-type') ?? '';
          if (contentType.contains('wordprocessingml') ||
              contentType.contains('msword')) {
            ext = '.docx';
          } else if (contentType.contains('spreadsheetml') ||
              contentType.contains('ms-excel')) {
            ext = '.xlsx';
          } else if (contentType.contains('presentationml') ||
              contentType.contains('ms-powerpoint')) {
            ext = '.pptx';
          } else if (contentType.contains('pdf')) {
            ext = '.pdf';
          } else if (contentType.contains('zip')) {
            ext = '.zip';
          } else if (contentType.contains('jpeg') || contentType.contains('jpg')) {
            ext = '.jpg';
          } else if (contentType.contains('png')) {
            ext = '.png';
          } else {
            ext = '.pdf';
          }
        }

        // Nama: `{Panduan}_{judul} {tanggal}{ext}` — tanggal unduh agar
        // berkas panduan lama/baru tidak sulit dibedakan di Download.
        final now = DateTime.now();
        String duaDigit(int n) => n.toString().padLeft(2, '0');
        final tanggal =
            '${duaDigit(now.day)}-${duaDigit(now.month)}-${now.year}';
        final namaFile = '${filename}_$tanggal$ext';
        return ApiClient.simpanKeDownload(namaFile, response.data ?? []);
      }, 'Gagal mengunduh panduan. Silakan coba lagi.');
}

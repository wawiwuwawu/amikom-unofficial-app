import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../models/keuangan.dart';

class KeuanganService {
  final _dio = ApiClient.instance.dio;

  Future<KeuanganHistoryResponse> getHistory() async {
    try {
      final response = await _dio.get('/api/v1/keuangan/history');
      return KeuanganHistoryResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<KeuanganDetailItem>> getHistoryDetail(KeuanganHistoryItem item) async {
    try {
      final response = await _dio.post(
        '/api/v1/keuangan/history/detail',
        data: item.toDetailRequestBody(),
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((e) => KeuanganDetailItem.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> downloadHistoryPdf() async {
    try {
      final dir = await _downloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final nama = ApiClient.instance.nama ?? '';
      final namaFile = nama.isNotEmpty ? '$nama ($nim)' : nim;
      final savePath = '$dir/Histori_Pembayaran_$namaFile.pdf';

      await _dio.download(
        '/api/v1/keuangan/history/download',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      return savePath;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> downloadDetailPdf(KeuanganHistoryItem item) async {
    try {
      final dir = await _downloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final kwitansi = item.nomorKwitansi ?? 'Detail';
      final safeThn = item.tahunAkademik.replaceAll('/', '_');
      final savePath = '$dir/Kwitansi_${kwitansi}_${nim}_SMT${item.semester}_$safeThn.pdf';

      await _dio.download(
        '/api/v1/keuangan/history/detail/download',
        savePath,
        queryParameters: item.toDownloadQueryParams(),
        options: Options(responseType: ResponseType.bytes),
      );

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
      return Exception(e.message ?? 'Terjadi kesalahan request Keuangan');
    }
    return Exception(e.toString());
  }
}

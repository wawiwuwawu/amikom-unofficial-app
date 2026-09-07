import 'package:dio/dio.dart';
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
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
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
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
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

  Future<KeuanganVaResult> bayarTagihan(
    String channelBank,
    List<KeuanganTagihanItem> items,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/keuangan/tagihan/bayar',
        data: {
          'channel_bank': channelBank,
          'items': items.map((e) => e.toBayarPayload()).toList(),
        },
      );
      return KeuanganVaResult.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<KeuanganTagihanResponse> getTagihan() async {
    try {
      final response = await _dio.get('/api/v1/keuangan/tagihan');
      return KeuanganTagihanResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> batalTagihan(String channelBank, String custCode, String idtrans) async {
    try {
      await _dio.post(
        '/api/v1/keuangan/tagihan/batal',
        data: {
          'channel_bank': channelBank,
          'custCode': custCode,
          'idtrans': idtrans,
        },
      );
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
      return Exception(e.message ?? 'Terjadi kesalahan request Keuangan');
    }
    return Exception(e.toString());
  }
}

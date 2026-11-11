import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/keuangan.dart';

class KeuanganService {
  final _dio = ApiClient.instance.dio;

  Future<KeuanganHistoryResponse> getHistory() =>
      ApiClient.guard<KeuanganHistoryResponse>(() async {
        final response = await _dio.get('/api/v1/keuangan/history');
        final root = ApiClient.unwrapRoot(response.data);
        return KeuanganHistoryResponse.fromJson(root);
      }, 'Gagal memuat riwayat pembayaran');

  Future<List<KeuanganDetailItem>> getHistoryDetail(
          KeuanganHistoryItem item) =>
      ApiClient.guard<List<KeuanganDetailItem>>(() async {
        final response = await _dio.post(
          '/api/v1/keuangan/history/detail',
          data: item.toDetailRequestBody(),
        );
        final list = response.data['data'] as List? ?? [];
        return list.map((e) => KeuanganDetailItem.fromJson(e)).toList();
      }, 'Gagal memuat rincian pembayaran');

  Future<String> downloadHistoryPdf() => ApiClient.guard<String>(() async {
        final namaFile = ApiClient.susunNamaBerkas(jenis: 'Histori_Pembayaran');

        final response = await _dio.get(
          '/api/v1/keuangan/history/download',
          options: Options(responseType: ResponseType.bytes),
        );

        return ApiClient.simpanKeDownload(
          namaFile,
          response.data is List ? response.data as List<int> : <int>[],
        );
      }, 'Gagal mengunduh riwayat pembayaran');

  Future<String> downloadDetailPdf(KeuanganHistoryItem item) =>
      ApiClient.guard<String>(() async {
        final namaFile = ApiClient.susunNamaBerkas(
          jenis: 'Kwitansi_${item.nomorKwitansi ?? 'Detail'}',
          tahun: item.tahunAkademik.replaceAll('/', '-'),
          semester: 'SMT${item.semester}',
        );

        final response = await _dio.get(
          '/api/v1/keuangan/history/detail/download',
          queryParameters: item.toDownloadQueryParams(),
          options: Options(responseType: ResponseType.bytes),
        );

        return ApiClient.simpanKeDownload(
          namaFile,
          response.data is List ? response.data as List<int> : <int>[],
        );
      }, 'Gagal mengunduh rincian pembayaran');

  Future<KeuanganVaResult> bayarTagihan(
    String channelBank,
    List<KeuanganTagihanItem> items,
  ) =>
      ApiClient.guard<KeuanganVaResult>(() async {
        final response = await _dio.post(
          '/api/v1/keuangan/tagihan/bayar',
          data: {
            'channel_bank': channelBank,
            'items': items.map((e) => e.toBayarPayload()).toList(),
          },
        );
        final root = ApiClient.unwrapRoot(response.data);
        final payload = ApiClient.unwrapData<dynamic>(response.data);
        final Map<String, dynamic> merged = {};
        if (payload is Map<String, dynamic>) {
          merged.addAll(payload);
        } else {
          merged.addAll(root);
        }
        if (root['message'] != null) {
          merged['message'] = root['message'];
        }
        return KeuanganVaResult.fromJson(merged);
      }, 'Gagal melakukan pembayaran');

  Future<KeuanganTagihanResponse> getTagihan() =>
      ApiClient.guard<KeuanganTagihanResponse>(() async {
        final response = await _dio.get('/api/v1/keuangan/tagihan');
        final root = ApiClient.unwrapRoot(response.data);
        return KeuanganTagihanResponse.fromJson(root);
      }, 'Gagal memuat tagihan');

  Future<void> batalTagihan(
          String channelBank, String custCode, String idtrans) =>
      ApiClient.guard<void>(() async {
        final response = await _dio.post(
          '/api/v1/keuangan/tagihan/batal',
          data: {
            'channel_bank': channelBank,
            'custCode': custCode,
            'idtrans': idtrans,
          },
        );
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal membatalkan tagihan');
}

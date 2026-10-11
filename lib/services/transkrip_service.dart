import 'api_client.dart';
import '../models/app_failure.dart';
import '../models/transkrip.dart';
import '../models/histori_ipk.dart';

class TranskripService {
  final _dio = ApiClient.instance.dio;

  Future<List<TranskripItem>> getTranskrip() =>
      ApiClient.guard<List<TranskripItem>>(() async {
        final response = await _dio.get('/api/v1/transkrip');
        final list = ApiClient.unwrapData<List>(response.data)
            .map((e) => TranskripItem.fromJson(e))
            .toList();
        return list;
      }, 'Gagal memuat transkrip. Silakan coba lagi.');

  Future<HistoriIpkData> getHistoriIpk() =>
      ApiClient.guard<HistoriIpkData>(() async {
        final response = await _dio.get('/api/v1/transkrip/histori-ipk');
        if (response.statusCode == 200 && response.data['data'] != null) {
          return HistoriIpkData.fromJson(response.data['data']);
        }
        throw const AppFailure('Gagal memuat histori IPK. Silakan coba lagi.');
      }, 'Gagal memuat histori IPK. Silakan coba lagi.');

  Future<CumlaudeData> getCumlaudeEligibility() =>
      ApiClient.guard<CumlaudeData>(() async {
        final response = await _dio.get('/api/v1/transkrip/cumlaude');
        if (response.statusCode == 200 && response.data['data'] != null) {
          return CumlaudeData.fromJson(response.data['data']);
        }
        throw const AppFailure('Gagal memuat evaluasi cumlaude. Silakan coba lagi.');
      }, 'Gagal memuat evaluasi cumlaude. Silakan coba lagi.');

  Future<ProgressKelulusanData> getProgressKelulusan() =>
      ApiClient.guard<ProgressKelulusanData>(() async {
        final response = await _dio.get('/api/v1/transkrip/progress-kelulusan');
        if (response.statusCode == 200 && response.data['data'] != null) {
          return ProgressKelulusanData.fromJson(response.data['data']);
        }
        throw const AppFailure('Gagal memuat progress kelulusan. Silakan coba lagi.');
      }, 'Gagal memuat progress kelulusan. Silakan coba lagi.');

  Future<SkpiData> getRingkasanSkpi() => ApiClient.guard<SkpiData>(() async {
        final response = await _dio.get('/api/v1/aktivitas/ringkasan-skpi');
        if (response.statusCode == 200 && response.data['data'] != null) {
          return SkpiData.fromJson(response.data['data']);
        }
        throw const AppFailure('Gagal memuat ringkasan SKPI. Silakan coba lagi.');
      }, 'Gagal memuat ringkasan SKPI. Silakan coba lagi.');

  Future<SimulasiIpkData> simulasiTargetIpk(double targetIpk) =>
      ApiClient.guard<SimulasiIpkData>(() async {
        final response = await _dio.post(
          '/api/v1/transkrip/simulasi-target-ipk',
          data: {'target_ipk': targetIpk},
        );
        if (response.statusCode == 200 && response.data['data'] != null) {
          return SimulasiIpkData.fromJson(response.data['data']);
        }
        throw const AppFailure('Gagal melakukan simulasi target IPK. Silakan coba lagi.');
      }, 'Gagal melakukan simulasi target IPK. Silakan coba lagi.');

  Future<String> download() => ApiClient.guard<String>(() async {
        // ponytail: centralized download dir via ApiClient
        final dir = await ApiClient.getDownloadDir();
        final nim = ApiClient.instance.nim ?? '';
        final nama = ApiClient.instance.nama ?? '';
        final namaFile = nama.isNotEmpty ? '$nama ($nim)' : nim;
        final savePath = '$dir/Transkrip_$namaFile.pdf';
        // ponytail: GET request as expected by backend /api/v1/transkrip/download route
        await _dio.download(
          '/api/v1/transkrip/download',
          savePath,
        );
        return savePath;
      }, 'Gagal mengunduh transkrip. Silakan coba lagi.');
}

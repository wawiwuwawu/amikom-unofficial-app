import 'api_client.dart';
import '../models/api_response.dart';
import '../models/asisten.dart';

class AsistenService {
  final _dio = ApiClient.instance.dio;

  Future<AsistenInfo> getInfo() => ApiClient.guard<AsistenInfo>(() async {
        final response = await _dio.get('/api/v1/asisten/info');
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return AsistenInfo.fromJson(data);
      }, 'Gagal memuat info asisten');

  Future<AsistenTahunAkademikResponse> getTahunAkademik() =>
      ApiClient.guard<AsistenTahunAkademikResponse>(() async {
        final response = await _dio.get('/api/v1/asisten/tahun-akademik');
        final root = ApiClient.unwrapRoot(response.data);
        return AsistenTahunAkademikResponse.fromJson(root);
      }, 'Gagal memuat tahun akademik');

  Future<AsistenJadwalResponse> getJadwal({String? tahun}) =>
      ApiClient.guard<AsistenJadwalResponse>(() async {
        final response = await _dio.get(
          '/api/v1/asisten/jadwal',
          queryParameters: {
            if (tahun != null && tahun.isNotEmpty) 'tahun': tahun,
          },
        );
        final root = ApiClient.unwrapRoot(response.data);
        return AsistenJadwalResponse.fromJson(root);
      }, 'Gagal memuat jadwal asisten');

  Future<AsistenLaporan> getLaporan() =>
      ApiClient.guard<AsistenLaporan>(() async {
        final response = await _dio.get('/api/v1/asisten/laporan');
        final root = ApiClient.unwrapRoot(response.data);
        return AsistenLaporan.fromJson(root);
      }, 'Gagal memuat laporan asisten');

  Future<MutationResult> pengajuanBebasKp({String act = 'ajukan'}) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.post(
          '/api/v1/asisten/pengajuan-bebas-kp',
          queryParameters: {'act': act},
          data: {},
        );
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal memproses pengajuan bebas KP');
}

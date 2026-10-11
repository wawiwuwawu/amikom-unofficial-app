import 'api_client.dart';
import '../models/app_failure.dart';
import '../models/pengumuman.dart';

class PengumumanService {
  final _dio = ApiClient.instance.dio;

  Future<List<PengumumanItem>> getList() =>
      ApiClient.guard<List<PengumumanItem>>(() async {
        final response = await _dio.get('/api/v1/pengumumanAkademik');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<PengumumanItem>(
            data, PengumumanItem.fromJson);
      }, 'Gagal memuat pengumuman');

  Future<PengumumanDetail> getDetail(dynamic idOrUrl) =>
      ApiClient.guard<PengumumanDetail>(() async {
        final str = idOrUrl.toString().trim();
        final endpoint = _buildEndpoint(str);
        final response = await _dio.get(endpoint);
        final raw = ApiClient.unwrapData<dynamic>(response.data);

        final Map<String, dynamic> jsonMap = _extractJsonMap(raw);

        if (jsonMap.isEmpty) {
          // Tanpa payload mentah — cukup pesan ramah.
          throw const AppFailure('Data pengumuman tidak dapat dibaca. Silakan coba lagi.');
        }

        final detail = PengumumanDetail.fromJson(jsonMap);

        // Validate that we got actual content (not an auth error response)
        if (detail.judul.isEmpty && detail.konten.isEmpty) {
          final msg = jsonMap['message']?.toString();
          if (msg != null && msg.isNotEmpty) {
            // Pesan server dipakai hanya bila tidak mengandung jejak teknis.
            throw AppFailure.fromServer(
                msg, fallback: 'Data pengumuman tidak tersedia');
          }
          throw const AppFailure('Data pengumuman tidak tersedia');
        }

        return detail;
      }, 'Gagal memuat detail pengumuman');

  String _buildEndpoint(String raw) {
    // Full URL: pass through as-is
    if (raw.startsWith('http')) return raw;

    // Already correct prefix
    if (raw.startsWith('/api/')) return raw;

    // Starts with "/" but missing "/api/v1" prefix
    if (raw.startsWith('/')) return '/api/v1$raw';

    // Plain ID: construct full path
    return '/api/v1/pengumumanAkademik/$raw';
  }

  Map<String, dynamic> _extractJsonMap(dynamic raw) =>
      ApiClient.forceJsonMap(raw);
}

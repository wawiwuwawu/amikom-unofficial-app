import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/notifikasi.dart';
import '../models/app_failure.dart';

class NotifikasiService {
  final _dio = ApiClient.instance.dio;
  static const _storageKey = 'read_notification_ids';

  Future<List<NotifikasiItem>> getNotifikasi() =>
      ApiClient.guard<List<NotifikasiItem>>(() async {
        final response = await _dio.get('/api/v1/notifikasi');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<NotifikasiItem>(
            data, NotifikasiItem.fromJson);
      }, 'Gagal memuat notifikasi');

  Future<NotifikasiDetail> getNotifikasiDetail(String id) =>
      ApiClient.guard<NotifikasiDetail>(() async {
        final endpoint = '/api/v1/notifikasi/$id';
        final response = await _dio.get(endpoint);
        final raw = ApiClient.unwrapData<dynamic>(response.data);

        Map<String, dynamic> jsonMap = ApiClient.forceJsonMap(raw);

        if (jsonMap.isEmpty) {
          throw const AppFailure('Format data detail notifikasi tidak valid');
        }

        final detail = NotifikasiDetail.fromJson(jsonMap);

        if (detail.judul.isEmpty && detail.konten.isEmpty) {
          final msg = jsonMap['message']?.toString();
          if (msg != null && msg.isNotEmpty) {
            throw AppFailure.fromServer(
                msg, fallback: 'Data notifikasi tidak tersedia');
          }
          throw const AppFailure('Data notifikasi tidak tersedia');
        }

        return detail;
      }, 'Gagal memuat detail notifikasi');

  Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? [];
    return list.toSet();
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readSet = (prefs.getStringList(_storageKey) ?? []).toSet();
    readSet.add(id);
    await prefs.setStringList(_storageKey, readSet.toList());
  }

  Future<void> markAllAsRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final readSet = (prefs.getStringList(_storageKey) ?? []).toSet();
    readSet.addAll(ids);
    await prefs.setStringList(_storageKey, readSet.toList());
  }

  Future<int> getUnreadCount() async {
    try {
      final items = await getNotifikasi();
      final readIds = await getReadIds();
      return items.where((item) => !readIds.contains(item.id)).length;
    } catch (_) {
      return 0;
    }
  }
}

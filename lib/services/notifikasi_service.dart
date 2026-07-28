import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/notifikasi.dart';

class NotifikasiService {
  final _dio = ApiClient.instance.dio;
  static const _storageKey = 'read_notification_ids';

  Future<List<NotifikasiItem>> getNotifikasi() async {
    try {
      final response = await _dio.get('/api/v1/notifikasi');
      final data = response.data['data'] as List?;
      return data?.map((e) => NotifikasiItem.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat notifikasi');
    }
  }

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
      int unread = 0;
      for (final item in items) {
        if (!readIds.contains(item.id)) {
          unread++;
        }
      }
      return unread;
    } catch (_) {
      return 0;
    }
  }
}

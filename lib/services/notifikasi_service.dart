import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/notifikasi.dart';

class NotifikasiService {
  final _dio = ApiClient.instance.dio;
  static const _storageKey = 'read_notification_ids';

  Future<List<NotifikasiItem>> getNotifikasi() async {
    try {
      final response = await _dio.get('/api/v1/notifikasi');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => NotifikasiItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat notifikasi');
    }
  }

  Future<NotifikasiDetail> getNotifikasiDetail(String id) async {
    try {
      final endpoint = '/api/v1/notifikasi/$id';
      final response = await _dio.get(endpoint);
      final raw = ApiClient.unwrapData<dynamic>(response.data);

      Map<String, dynamic> jsonMap = {};
      if (raw is Map<String, dynamic>) {
        jsonMap = raw;
      } else if (raw is Map) {
        jsonMap = Map<String, dynamic>.from(raw);
      } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
        jsonMap = Map<String, dynamic>.from(raw.first);
      } else if (raw is String) {
        try {
          final parsed = jsonDecode(raw);
          if (parsed is Map) {
            jsonMap = Map<String, dynamic>.from(parsed);
          } else if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
            jsonMap = Map<String, dynamic>.from(parsed.first);
          }
        } catch (_) {}
      }

      if (jsonMap.isEmpty) {
        throw Exception('Format data detail notifikasi tidak valid');
      }

      final detail = NotifikasiDetail.fromJson(jsonMap);

      if (detail.judul.isEmpty && detail.konten.isEmpty) {
        final msg = jsonMap['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          throw Exception(msg);
        }
        throw Exception('Data notifikasi tidak tersedia');
      }

      return detail;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat detail notifikasi');
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


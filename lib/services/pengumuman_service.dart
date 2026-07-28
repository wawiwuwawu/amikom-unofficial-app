import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/pengumuman.dart';

class PengumumanService {
  final _dio = ApiClient.instance.dio;

  Future<List<PengumumanItem>> getList() async {
    try {
      final response = await _dio.get('/api/v1/pengumumanAkademik');
      final data = response.data['data'] as List?;
      return data?.map((e) => PengumumanItem.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat pengumuman');
    }
  }

  Future<PengumumanDetail> getDetail(dynamic idOrUrl) async {
    try {
      final str = idOrUrl.toString().trim();
      final endpoint = _buildEndpoint(str);
      final response = await _dio.get(endpoint);
      final raw = response.data;

      Map<String, dynamic> jsonMap = _extractJsonMap(raw);

      if (jsonMap.isEmpty) {
        throw Exception('Format data detail pengumuman tidak valid: $raw');
      }

      final detail = PengumumanDetail.fromJson(jsonMap);

      // Validate that we got actual content (not an auth error response)
      if (detail.judul.isEmpty && detail.konten.isEmpty) {
        final msg = jsonMap['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          throw Exception(msg);
        }
        throw Exception('Data pengumuman tidak tersedia');
      }

      return detail;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat detail pengumuman');
    }
  }

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

  Map<String, dynamic> _extractJsonMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first);
    } else if (raw is String) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map) {
          return Map<String, dynamic>.from(parsed);
        } else if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          return Map<String, dynamic>.from(parsed.first);
        }
      } catch (_) {}
    }
    return {};
  }
}


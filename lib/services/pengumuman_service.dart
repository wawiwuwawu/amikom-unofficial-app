import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:developer' as dev;
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
      final endpoint = str.startsWith('/') ? str : '/api/v1/pengumumanAkademik/$str';
      dev.log('[PengumumanService] GET $endpoint');
      final response = await _dio.get(endpoint);
      final raw = response.data;
      dev.log('[PengumumanService] response.data type: ${raw.runtimeType}');
      
      Map<String, dynamic> jsonMap = {};
      if (raw is Map) {
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

      if (jsonMap.isNotEmpty) {
        final detail = PengumumanDetail.fromJson(jsonMap);
        dev.log('[PengumumanService] parsed judul: "${detail.judul}"');
        dev.log('[PengumumanService] parsed konten count: ${detail.konten.length}');
        return detail;
      }
      
      throw Exception('Format data detail pengumuman tidak valid: $raw');
    } on DioException catch (e) {
      dev.log('[PengumumanService] DioException: ${e.message}');
      dev.log('[PengumumanService] DioException response: ${e.response?.data}');
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat detail pengumuman');
    }
  }
}

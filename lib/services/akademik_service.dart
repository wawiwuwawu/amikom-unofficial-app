import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/agenda.dart';
import '../models/jadwal_ujian.dart';
import '../models/agenda_terpadu.dart';
import '../models/app_failure.dart';

class AkademikService {
  final _dio = ApiClient.instance.dio;

  Future<List<Agenda>> getAgenda() => ApiClient.guard<List<Agenda>>(() async {
        final response = await _dio.get('/api/v1/akademik/agenda');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<Agenda>(data, Agenda.fromJson);
      }, 'Gagal memuat agenda');

  // ponytail: centralized agenda terpadu alongside akademik agenda endpoints
  Future<AgendaTerpaduData> getAgendaTerpadu() =>
      ApiClient.guard<AgendaTerpaduData>(() async {
        final response = await _dio.get('/api/v1/agenda/terpadu');
        if (response.statusCode == 200 && response.data['data'] != null) {
          return AgendaTerpaduData.fromJson(response.data['data']);
        }
        throw const AppFailure('Gagal memuat agenda terpadu');
      }, 'Gagal memuat agenda terpadu');

  Future<List<JadwalUjian>> getJadwalUjian(String jenis) =>
      ApiClient.guard<List<JadwalUjian>>(() async {
        final response = await _dio.get(
          '/api/v1/akademik/jadwal-ujian',
          queryParameters: {'jenis': jenis},
        );
        final data = response.data['data'] as List?;
        if (data == null) return [];
        return data.map((e) => JadwalUjian.fromJson(e)).toList();
      }, 'Gagal memuat jadwal ujian');

  Future<String> downloadKartuUjian(String jenis) =>
      ApiClient.guard<String>(() async {
        final dir = await ApiClient.getDownloadDir();
        final response = await _dio.get(
          '/api/v1/akademik/jadwal-ujian/download',
          queryParameters: {'jenis': jenis},
          options: Options(responseType: ResponseType.bytes),
        );

        final ext = ApiClient.extensionFromHeaders(response.headers);

        final nim = ApiClient.instance.nim ?? '';
        final savePath = '$dir/Kartu_Ujian_${jenis.toUpperCase()}_$nim$ext';

        final file = File(savePath);
        await file.writeAsBytes(response.data);

        return savePath;
      }, 'Gagal mengunduh kartu ujian');
}

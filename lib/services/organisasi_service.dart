import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
import '../models/organisasi.dart';

class OrganisasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<OrganisasiItem>> getOrganisasi() async {
    try {
      final response = await _dio.get('/api/v1/organisasi-mahasiswa');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => OrganisasiItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Organisasi Mahasiswa');
    }
  }

  Future<OrganisasiOptionResponse> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/organisasi-mahasiswa/options');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data != null && data is Map<String, dynamic>) {
        return OrganisasiOptionResponse.fromJson(data);
      } else if (data != null && data is Map) {
        return OrganisasiOptionResponse.fromJson(Map<String, dynamic>.from(data));
      }
      return OrganisasiOptionResponse(organisasi: [], jabatan: []);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pilihan Organisasi');
    }
  }

  Future<void> tambahOrganisasi(FormData data) =>
      AktivitasHelper.submit('/api/v1/organisasi-mahasiswa', data, 'Gagal menambahkan Organisasi Mahasiswa');

  Future<void> hapusOrganisasi(int id) =>
      AktivitasHelper.delete('/api/v1/organisasi-mahasiswa', id, 'Gagal menghapus Organisasi Mahasiswa');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/organisasi-mahasiswa', id, namaFile, 'Gagal mengunduh dokumen organisasi');
}

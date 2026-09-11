import 'package:dio/dio.dart';
import 'api_client.dart';
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

  Future<void> tambahOrganisasi(FormData data) async {
    try {
      final response = await _dio.post(
        '/api/v1/organisasi-mahasiswa',
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambahkan Organisasi Mahasiswa');
    }
  }

  Future<void> hapusOrganisasi(int id) async {
    try {
      final response = await _dio.delete('/api/v1/organisasi-mahasiswa/$id');
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus Organisasi Mahasiswa');
    }
  }

  Future<String> downloadFile(int id, String namaFile) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      final savePath = '$dir/$namaFile';
      await _dio.download(
        '/api/v1/organisasi-mahasiswa/$id/file',
        savePath,
      );
      return savePath;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunduh dokumen organisasi');
    }
  }
}

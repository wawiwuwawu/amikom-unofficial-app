import 'package:dio/dio.dart';
import '../models/mbkm.dart';
import 'api_client.dart';

class MbkmService {
  final ApiClient _client = ApiClient.instance;

  Future<List<MbkmFakultas>> getDaftarMBKM() async {
    try {
      final response = await _client.dio.get('/api/v1/mbkm/fakultas');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => MbkmFakultas.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengambil data MBKM');
    }
  }

  Future<List<MbkmBimbingan>> getBimbingan(String idMbkm) async {
    try {
      final response = await _client.dio.get('/api/v1/mbkm/fakultas/bimbingan/$idMbkm');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => MbkmBimbingan.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengambil bimbingan');
    }
  }

  Future<void> tambahBimbingan(String idMbkm, String isiBimbingan) async {
    try {
      final response = await _client.dio.post('/api/v1/mbkm/fakultas/bimbingan', data: {
        'id_mbkm': idMbkm,
        'isi_bimbingan': isiBimbingan,
      });
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambah bimbingan');
    }
  }

  Future<void> hapusBimbingan(String idBimbingan) async {
    try {
      final response = await _client.dio.delete('/api/v1/mbkm/fakultas/bimbingan/$idBimbingan');
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus bimbingan');
    }
  }

  Future<void> uploadKomitmen(String idMbkm, String komitmenPath, String pembayaranPath) async {
    try {
      final formData = FormData.fromMap({
        'id_mbkm': idMbkm,
        'surat_komitmen': await MultipartFile.fromFile(komitmenPath),
        'bukti_pembayaran': await MultipartFile.fromFile(pembayaranPath),
      });
      final response = await _client.dio.post('/api/v1/mbkm/fakultas/upload-komitmen', data: formData);
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal upload dokumen komitmen');
    }
  }

  Future<void> uploadLuaran(String idMbkm, String linkLaporan, String jenis, String luaranPath) async {
    try {
      final formData = FormData.fromMap({
        'id_mbkm': idMbkm,
        'link_laporan': linkLaporan,
        'jenis': jenis,
        'file_luaran': await MultipartFile.fromFile(luaranPath),
      });
      final response = await _client.dio.post('/api/v1/mbkm/fakultas/upload-file-luaran', data: formData);
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal upload file luaran');
    }
  }
}

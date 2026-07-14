import 'package:dio/dio.dart';
import '../models/mbkm.dart';
import 'api_client.dart';

class MbkmService {
  final ApiClient _client = ApiClient.instance;

  Future<List<MbkmFakultas>> getDaftarMBKM() async {
    try {
      final response = await _client.dio.get('/api/v1/mbkm/fakultas');
      final List data = response.data['data'] ?? [];
      return data.map((e) => MbkmFakultas.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Data MBKM tidak ditemukan.');
      }
      throw Exception(e.message ?? 'Gagal mengambil data MBKM');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<List<MbkmBimbingan>> getBimbingan(String idMbkm) async {
    try {
      final response = await _client.dio.get('/api/v1/mbkm/fakultas/bimbingan/$idMbkm');
      final List data = response.data['data'] ?? [];
      return data.map((e) => MbkmBimbingan.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Riwayat bimbingan tidak ditemukan.');
      }
      throw Exception(e.message ?? 'Gagal mengambil bimbingan');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> tambahBimbingan(String idMbkm, String isiBimbingan) async {
    try {
      await _client.dio.post('/api/v1/mbkm/fakultas/bimbingan', data: {
        'id_mbkm': idMbkm,
        'isi_bimbingan': isiBimbingan,
      });
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Gagal menambah bimbingan');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> hapusBimbingan(String idBimbingan) async {
    try {
      await _client.dio.delete('/api/v1/mbkm/fakultas/bimbingan/$idBimbingan');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Gagal menghapus bimbingan');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> uploadKomitmen(String idMbkm, String komitmenPath, String pembayaranPath) async {
    try {
      final formData = FormData.fromMap({
        'id_mbkm': idMbkm,
        'surat_komitmen': await MultipartFile.fromFile(komitmenPath),
        'bukti_pembayaran': await MultipartFile.fromFile(pembayaranPath),
      });
      await _client.dio.post('/api/v1/mbkm/fakultas/upload-komitmen', data: formData);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Gagal upload dokumen komitmen');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
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
      await _client.dio.post('/api/v1/mbkm/fakultas/upload-file-luaran', data: formData);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Gagal upload file luaran');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}

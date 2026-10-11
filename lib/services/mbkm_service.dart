import 'package:dio/dio.dart';
import '../models/mbkm.dart';
import 'api_client.dart';

class MbkmService {
  final ApiClient _client = ApiClient.instance;

  Future<List<MbkmFakultas>> getDaftarMBKM() =>
      ApiClient.guard<List<MbkmFakultas>>(() async {
        final response = await _client.dio.get('/api/v1/mbkm/fakultas');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<MbkmFakultas>(
            data, MbkmFakultas.fromJson);
      }, 'Gagal mengambil data MBKM');

  Future<List<MbkmBimbingan>> getBimbingan(String idMbkm) =>
      ApiClient.guard<List<MbkmBimbingan>>(() async {
        final response = await _client.dio.get(
            '/api/v1/mbkm/fakultas/bimbingan/$idMbkm');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<MbkmBimbingan>(
            data, MbkmBimbingan.fromJson);
      }, 'Gagal mengambil bimbingan');

  Future<void> tambahBimbingan(String idMbkm, String isiBimbingan) =>
      ApiClient.guard<void>(() async {
        final response = await _client.dio.post(
            '/api/v1/mbkm/fakultas/bimbingan',
            data: {
              'id_mbkm': idMbkm,
              'isi_bimbingan': isiBimbingan,
            });
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal menambah bimbingan');

  Future<void> hapusBimbingan(String idBimbingan) =>
      ApiClient.guard<void>(() async {
        final response = await _client.dio.delete(
            '/api/v1/mbkm/fakultas/bimbingan/$idBimbingan');
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal menghapus bimbingan');

  Future<void> uploadKomitmen(
          String idMbkm, String komitmenPath, String pembayaranPath) =>
      ApiClient.guard<void>(() async {
        final formData = FormData.fromMap({
          'id_mbkm': idMbkm,
          'surat_komitmen': await MultipartFile.fromFile(komitmenPath),
          'bukti_pembayaran': await MultipartFile.fromFile(pembayaranPath),
        });
        final response = await _client.dio.post(
            '/api/v1/mbkm/fakultas/upload-komitmen',
            data: formData);
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal upload dokumen komitmen');

  Future<void> uploadLuaran(
          String idMbkm, String linkLaporan, String jenis, String luaranPath) =>
      ApiClient.guard<void>(() async {
        final formData = FormData.fromMap({
          'id_mbkm': idMbkm,
          'link_laporan': linkLaporan,
          'jenis': jenis,
          'file_luaran': await MultipartFile.fromFile(luaranPath),
        });
        final response = await _client.dio.post(
            '/api/v1/mbkm/fakultas/upload-file-luaran',
            data: formData);
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal upload file luaran');
}

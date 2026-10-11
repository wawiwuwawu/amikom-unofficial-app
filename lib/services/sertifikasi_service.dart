import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
import '../models/sertifikasi.dart';
import '../models/value_label_option.dart';

class SertifikasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<SertifikasiItem>> getSertifikasi() =>
      ApiClient.guard<List<SertifikasiItem>>(() async {
        final response = await _dio.get('/api/v1/sertifikasi-kompetensi');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<SertifikasiItem>(
            data, SertifikasiItem.fromJson);
      }, 'Gagal memuat data Sertifikasi Kompetensi');

  Future<List<ValueLabelOption>> getOptions() =>
      ApiClient.guard<List<ValueLabelOption>>(() async {
        final response =
            await _dio.get('/api/v1/sertifikasi-kompetensi/options');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data is Map && data['sertifikasi'] is List) {
          return ApiClient.unwrapList<ValueLabelOption>(
              data['sertifikasi'], ValueLabelOption.fromJson);
        } else if (data is List) {
          return ApiClient.unwrapList<ValueLabelOption>(
              data, ValueLabelOption.fromJson);
        }
        return [];
      }, 'Gagal memuat pilihan Sertifikasi');

  Future<void> tambahSertifikasi(FormData data) =>
      AktivitasHelper.submit('/api/v1/sertifikasi-kompetensi', data,
          'Gagal menambahkan Sertifikasi Kompetensi');

  Future<void> editSertifikasi(int id, FormData data) =>
      AktivitasHelper.edit('/api/v1/sertifikasi-kompetensi', id, data,
          'Gagal mengubah data Sertifikasi Kompetensi');

  Future<void> hapusSertifikasi(int id) => AktivitasHelper.delete(
      '/api/v1/sertifikasi-kompetensi', id,
      'Gagal menghapus Sertifikasi Kompetensi');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/sertifikasi-kompetensi', id,
          namaFile, 'Gagal mengunduh file sertifikat');
}

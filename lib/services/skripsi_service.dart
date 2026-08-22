import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/skripsi.dart';
import 'api_client.dart';

class SkripsiService {
  final _dio = ApiClient.instance.dio;

  // 1. Informasi Utama & Status
  Future<SkripsiMainData> getMainInfo() async {
    try {
      final response = await _dio.get('/api/v1/skripsi');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SkripsiMainData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat informasi utama skripsi');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 2. Tab Proposal
  Future<List<SkripsiProposalItem>> getProposals() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/proposal');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((e) => SkripsiProposalItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitProposalBaru({
    required String tipe,
    required String judul,
    required String idReviewer,
    required String idTema,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/proposal',
        data: {
          'tipe': tipe,
          'judul': judul,
          'id_reviewer': idReviewer,
          'id_tema': idTema,
        },
      );
      return response.data ?? {'success': true, 'message': 'Proposal berhasil diajukan'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitProposalUlang({
    required String idReviewer,
    required String idProposal,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/proposal/ulang',
        data: {
          'id_reviewer': idReviewer,
          'id_proposal': idProposal,
        },
      );
      return response.data ?? {'success': true, 'message': 'Proposal ulang berhasil diajukan'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitTemaUlang({
    required String idProposal,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/tema/ulang',
        data: {
          'id_proposal': idProposal,
        },
      );
      return response.data ?? {'success': true, 'message': 'Tema ulang berhasil diajukan ke Pusat Studi'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 3. Tab Kartu Bimbingan
  Future<List<SkripsiBimbinganItem>> getBimbinganList() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/bimbingan');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((e) => SkripsiBimbinganItem.fromJson(e)).toList();
      }
    } catch (_) {
      // Fallback strategy to main info
      try {
        final main = await getMainInfo();
        return main.bimbingan;
      } catch (_) {}
    }
    return [];
  }

  Future<Map<String, dynamic>> submitBimbingan({
    required String tanggal,
    required String idauto,
    required String nidn,
    required String progres,
    required String keterangan,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/bimbingan',
        data: {
          'tanggal': tanggal,
          'idauto': idauto,
          'nidn': nidn,
          'progres': progres,
          'keterangan': keterangan,
        },
      );
      return response.data ?? {'success': true, 'message': 'Catatan bimbingan berhasil disimpan'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SkripsiBimbinganItem> getDetailBimbingan(String id) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/bimbingan/detail',
        data: {'id': id},
      );
      final data = response.data['data'] ?? response.data;
      return SkripsiBimbinganItem.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateBimbingan({
    required String id,
    required String tanggal,
    required String progres,
    required String keterangan,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/skripsi/bimbingan',
        data: {
          'id': id,
          'tanggal': tanggal,
          'progres': progres,
          'keterangan': keterangan,
        },
      );
      return response.data ?? {'success': true, 'message': 'Catatan bimbingan berhasil diperbarui'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> downloadKartuBimbingan(String id) async {
    try {
      final dir = await _downloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final savePath = '$dir/Kartu_Bimbingan_Skripsi_${id}_$nim.pdf';

      await _dio.download(
        '/api/v1/skripsi/bimbingan/download/$id',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      return savePath;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 4. Tab Pendaftaran & Jadwal Ujian
  Future<List<SkripsiPendaftaranItem>> getPendaftaranList() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/pendaftaran');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((e) => SkripsiPendaftaranItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitPendaftaranUjian({
    required String judul,
    required String ukuranToga,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/pendaftaran',
        data: {
          'judul': judul,
          'ukuran_toga': ukuranToga,
        },
      );
      return response.data ?? {'success': true, 'message': 'Pendaftaran ujian skripsi berhasil diajukan'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deletePendaftaranUjian(String id) async {
    try {
      final response = await _dio.delete('/api/v1/skripsi/pendaftaran/$id');
      return response.data ?? {'success': true, 'message': 'Pengajuan ujian skripsi berhasil dibatalkan'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> downloadFormulirPendaftaran(String id) async {
    try {
      final dir = await _downloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final savePath = '$dir/Formulir_Pendaftaran_Skripsi_${id}_$nim.pdf';

      await _dio.download(
        '/api/v1/skripsi/pendaftaran/download/$id',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      return savePath;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 5. Tab Cek Plagiarisme
  Future<List<SkripsiPlagiarismeItem>> getPlagiarismeList() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/plagiarisme');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((e) => SkripsiPlagiarismeItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadPlagiarisme(File file) async {
    try {
      final fileName = file.path.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'dok_plagiarism': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/api/v1/skripsi/plagiarisme/upload',
        data: formData,
      );
      return response.data ?? {'success': true, 'message': 'Dokumen plagiarisme berhasil diunggah'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deletePlagiarisme(String id) async {
    try {
      final response = await _dio.delete('/api/v1/skripsi/plagiarisme/$id');
      return response.data ?? {'success': true, 'message': 'Dokumen plagiarisme berhasil dihapus'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 6. Pasca Ujian (Update Judul & Link Berkas)
  Future<Map<String, dynamic>> updateJudulSkripsi({
    required String judulId,
    required String judulEn,
  }) async {
    try {
      final nim = ApiClient.instance.nim ?? '';
      final response = await _dio.put(
        '/api/v1/skripsi/judul',
        data: {
          'judul_skripsi_id': judulId,
          'judul_skripsi_en': judulEn,
          'npm': nim,
        },
      );
      return response.data ?? {'success': true, 'message': 'Judul skripsi berhasil diperbarui'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitLinkBerkas({
    required String idJenis,
    required String linkFile,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/link',
        data: {
          'id_jenis': idJenis,
          'link_file': linkFile,
        },
      );
      return response.data ?? {'success': true, 'message': 'Link berkas berhasil disimpan'};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> _downloadDir() async {
    if (Platform.isAndroid) {
      final download = Directory('/storage/emulated/0/Download');
      if (await download.exists()) {
        return download.path;
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Exception _handleError(dynamic e) {
    if (e is DioException && e.response != null) {
      final msg = e.response?.data?['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return Exception(msg);
      }
      return Exception(e.message ?? 'Terjadi kesalahan pada layanan Skripsi');
    }
    return Exception(e.toString());
  }
}

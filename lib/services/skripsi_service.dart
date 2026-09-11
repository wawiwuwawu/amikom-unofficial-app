import 'dart:io';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/skripsi.dart';
import 'api_client.dart';

class SkripsiService {
  final _dio = ApiClient.instance.dio;

  // 1. Informasi Utama & Status
  Future<SkripsiMainData> getMainInfo() async {
    try {
      final response = await _dio.get('/api/v1/skripsi');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is Map<String, dynamic>) {
        return SkripsiMainData.fromJson(data);
      } else if (data is Map) {
        return SkripsiMainData.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Gagal memuat informasi utama skripsi');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat informasi utama skripsi');
    }
  }

  // 2. Tab Proposal
  Future<List<SkripsiProposalItem>> getProposals() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/proposal');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => SkripsiProposalItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data proposal skripsi');
    }
  }

  Future<MutationResult> submitProposalBaru({
    required String judul,
    required File filePdf,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      String filename;
      try {
        filename = filePdf.uri.pathSegments.isNotEmpty
            ? filePdf.uri.pathSegments.last
            : filePdf.path.split(Platform.isWindows ? r'\' : '/').last;
      } catch (_) {
        filename = filePdf.path.split(Platform.isWindows ? r'\' : '/').last;
      }
      if (RegExp(r'''[&"'<>]''').hasMatch(filename)) {
        throw Exception('Nama file tidak boleh memuat karakter khusus (&, ", \', <, >)');
      }

      final fileSize = await filePdf.length();
      if (fileSize > 3 * 1024 * 1024) {
        throw Exception('Ukuran file maksimal 3 MB');
      }

      final formData = FormData.fromMap({
        'judul': judul.trim(),
        'file': await MultipartFile.fromFile(
          filePdf.path,
          filename: filename,
        ),
      });

      final response = await _dio.post(
        '/api/v1/skripsi/proposal',
        data: formData,
        onSendProgress: onSendProgress,
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      if (e is DioException) {
        throw ApiClient.handleError(e, 'Gagal mengajukan proposal');
      }
      rethrow;
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengajukan proposal ulang');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengajukan tema ulang');
    }
  }

  // 3. Tab Kartu Bimbingan
  Future<List<SkripsiBimbinganItem>> getBimbinganList() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/bimbingan');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => SkripsiBimbinganItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menyimpan catatan bimbingan');
    }
  }

  Future<SkripsiBimbinganItem> getDetailBimbingan(String id) async {
    try {
      final response = await _dio.post(
        '/api/v1/skripsi/bimbingan/detail',
        data: {'id': id},
      );
      return SkripsiBimbinganItem.fromJson(
          ApiClient.unwrapData<Map<String, dynamic>>(response.data));
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat detail bimbingan');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memperbarui catatan bimbingan');
    }
  }

  Future<String> downloadKartuBimbingan(String id) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final savePath = '$dir/Kartu_Bimbingan_Skripsi_${id}_$nim.pdf';

      await _dio.download(
        '/api/v1/skripsi/bimbingan/download/$id',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      return savePath;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunduh kartu bimbingan');
    }
  }

  // 4. Tab Pendaftaran & Jadwal Ujian
  Future<List<SkripsiPendaftaranItem>> getPendaftaranList() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/pendaftaran');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => SkripsiPendaftaranItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data pendaftaran skripsi');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengajukan pendaftaran ujian skripsi');
    }
  }

  Future<Map<String, dynamic>> deletePendaftaranUjian(String id) async {
    try {
      final response = await _dio.delete('/api/v1/skripsi/pendaftaran/$id');
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal membatalkan pengajuan ujian skripsi');
    }
  }

  Future<String> downloadFormulirPendaftaran(String id) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final savePath = '$dir/Formulir_Pendaftaran_Skripsi_${id}_$nim.pdf';

      await _dio.download(
        '/api/v1/skripsi/pendaftaran/download/$id',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      return savePath;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunduh formulir pendaftaran');
    }
  }

  // 5. Tab Cek Plagiarisme
  Future<List<SkripsiPlagiarismeItem>> getPlagiarismeList() async {
    try {
      final response = await _dio.get('/api/v1/skripsi/plagiarisme');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => SkripsiPlagiarismeItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data plagiarisme');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunggah dokumen plagiarisme');
    }
  }

  Future<Map<String, dynamic>> deletePlagiarisme(String id) async {
    try {
      final response = await _dio.delete('/api/v1/skripsi/plagiarisme/$id');
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus dokumen plagiarisme');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memperbarui judul skripsi');
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
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menyimpan link berkas');
    }
  }
}

import 'package:dio/dio.dart';
import 'api_client.dart';

class AktivitasHelper {
  AktivitasHelper._();

  static Future<void> submit(
    String path,
    FormData data,
    String fallbackError,
  ) async {
    try {
      final response = await ApiClient.instance.dio.post(
        path,
        data: data,
      );
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, fallbackError);
    }
  }

  static Future<void> edit(
    String path,
    int id,
    FormData data,
    String fallbackError,
  ) async {
    try {
      final response = await ApiClient.instance.dio.put('$path/$id', data: data);
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, fallbackError);
    }
  }

  static Future<void> delete(
    String path,
    int id,
    String fallbackError,
  ) async {
    try {
      final response = await ApiClient.instance.dio.delete('$path/$id');
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, fallbackError);
    }
  }

  static Future<List<int>> download(
    String path,
    int id,
    String fallbackError,
  ) async {
    try {
      final response = await ApiClient.instance.dio.get<List<int>>(
        '$path/$id/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } catch (e) {
      throw ApiClient.handleError(e, fallbackError);
    }
  }

  static Future<String> downloadFile(
    String path,
    int id,
    String namaFile,
    String fallbackError,
  ) async {
    try {
      final dir = await ApiClient.getDownloadDir();
      final savePath = '$dir/$namaFile';
      await ApiClient.instance.dio.download(
        '$path/$id/file',
        savePath,
      );
      return savePath;
    } catch (e) {
      throw ApiClient.handleError(e, fallbackError);
    }
  }
}

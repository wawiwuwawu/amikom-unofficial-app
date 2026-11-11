import 'package:dio/dio.dart';
import 'api_client.dart';

class AktivitasHelper {
  AktivitasHelper._();

  static Future<void> submit(
    String path,
    FormData data,
    String fallbackError,
  ) =>
      ApiClient.guard<void>(() async {
        final response = await ApiClient.instance.dio.post(
          path,
          data: data,
        );
        ApiClient.unwrapMutation(response.data);
      }, fallbackError);

  static Future<void> edit(
    String path,
    int id,
    FormData data,
    String fallbackError,
  ) =>
      ApiClient.guard<void>(() async {
        final response =
            await ApiClient.instance.dio.put('$path/$id', data: data);
        ApiClient.unwrapMutation(response.data);
      }, fallbackError);

  static Future<void> delete(
    String path,
    int id,
    String fallbackError,
  ) =>
      ApiClient.guard<void>(() async {
        final response = await ApiClient.instance.dio.delete('$path/$id');
        ApiClient.unwrapMutation(response.data);
      }, fallbackError);

  static Future<String> downloadFile(
    String path,
    int id,
    String namaFile,
    String fallbackError,
  ) =>
      ApiClient.guard<String>(() async {
        final response = await ApiClient.instance.dio.get(
          '$path/$id/file',
          options: Options(responseType: ResponseType.bytes),
        );
        return ApiClient.simpanKeDownload(
          namaFile,
          response.data is List ? response.data as List<int> : const <int>[],
        );
      }, fallbackError);
}

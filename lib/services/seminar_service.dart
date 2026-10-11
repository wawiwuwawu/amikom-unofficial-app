import '../models/seminar.dart';
import 'api_client.dart';

class SeminarService {
  final ApiClient _client = ApiClient.instance;

  Future<List<Seminar>> getJadwalKP() => ApiClient.guard<List<Seminar>>(() async {
        final response = await _client.dio.get('/api/v1/seminar/kp');
        final list = ApiClient.unwrapData<List>(response.data);
        return list.map((e) => Seminar.fromJson(e)).toList();
      }, 'Gagal mengambil jadwal KP');

  Future<List<Seminar>> getJadwalSkripsi() =>
      ApiClient.guard<List<Seminar>>(() async {
        final response = await _client.dio.get('/api/v1/seminar/skripsi');
        final list = ApiClient.unwrapData<List>(response.data);
        return list.map((e) => Seminar.fromJson(e)).toList();
      }, 'Gagal mengambil jadwal Skripsi');
}

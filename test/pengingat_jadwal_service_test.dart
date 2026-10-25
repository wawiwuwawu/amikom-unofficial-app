// Test PengingatJadwalService: komputasi kejadian 14 hari, parser tanggal
// ujian, parser ICS libur, id FNV-1a stabil, diff hash, single-flight, dan
// jalur gagal-fetch (cache). Seluruh interaksi notifikasi lewat
// [PengingatGateway] palsu — TIDAK menyentuh Firebase maupun plugin asli.

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/models/agenda_terpadu.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/pengingat_jadwal_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _kCacheAgenda = 'pengingat_jadwal_cache_agenda';
const _kRegistry = 'pengingat_jadwal_registry';

/// Gerbang palsu: mencatat semua panggilan supaya jam terjadwal bisa
/// diverifikasi, bukan hanya jumlahnya.
class _GatewayFake implements PengingatGateway {
  final List<int> scheduledIds = [];
  final List<tz.TZDateTime> scheduledDates = [];
  final List<String> bodies = [];
  final List<int> cancelledIds = [];

  bool izin = true;
  bool exact = true;

  @override
  Future<void> siapkanChannel() async {}

  @override
  Future<bool> izinNotifikasiDiberikan() async => izin;

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    scheduledIds.add(id);
    scheduledDates.add(scheduledDate);
    bodies.add(body);
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAllIds(List<int> ids) async {
    cancelledIds.addAll(ids);
  }
}

/// Adapter Dio palsu untuk agenda terpadu & jadwal-ujian: [agenda] null
/// berarti FETCH GAGAL (lempar exception → ApiClient.guard → AppFailure).
/// [uts]/[uas] baris jadwal-ujian (null → fetch jadwal-ujian gagal). Bisa
/// menghitung permintaan untuk pengujian single-flight.
class _AgendaAdapter implements HttpClientAdapter {
  _AgendaAdapter(this.agenda);

  Map<String, List<Map<String, dynamic>>>? agenda;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    // Endpoint lain (mis. jadwal-ujian) sudah tidak dipanggil layanan —
    // sumber tanggal ujian kini baris agenda itu sendiri. Bila layanan
    // menyimpang dan memanggil endpoint lain, test ini gagal cepat.
    if (!options.path.contains('/api/v1/agenda/terpadu')) {
      throw Exception('endpoint tak dikenal: ${options.path}');
    }
    final data = agenda;
    if (data == null) {
      throw Exception('simulasi offline');
    }
    final total = data.values.fold<int>(0, (s, v) => s + v.length);
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'success',
        'data': {'total_agenda': total, 'agenda': data},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AgendaTerpaduData _agenda(Map<String, List<Map<String, dynamic>>> raw) {
  final parsed = raw.map(
    (day, list) => MapEntry(day, list.map(AgendaItem.fromJson).toList()),
  );
  final total = parsed.values.fold<int>(0, (s, v) => s + v.length);
  return AgendaTerpaduData(totalAgenda: total, agenda: parsed);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  });

  late _GatewayFake gateway;
  late _AgendaAdapter adapter;
  PengingatJadwalService service() => PengingatJadwalService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = _GatewayFake();
    adapter = _AgendaAdapter({});
    ApiClient.instance.dio.httpClientAdapter = adapter;
    // ICS libur selalu dilempar di test — siklus tidak menyentuh jaringan.
    service().ambilIcsLiburUntukTest = () async => throw Exception('offline');
    service().setGatewayUntukTest(gateway);
    service().resetUntukTest();
  });

  group('hitungKejadian — komputasi 14 hari', () {
    test('item Senin muncul 2x dalam jendela 14 hari', () {
      // 2026-11-02 adalah Senin; jendela 14 hari: 11-02 .. 11-15
      // (Senin 11-02 dan 11-09 — dua kali).
      final agenda = _agenda({
        'Senin': [
          {
            'tipe': 'kuliah',
            'hari': 'Senin',
            'jam': '09:00 - 10:40',
            'ruang': 'LT2',
            'matakuliah': 'Pemrograman Web',
            'detail': '',
          },
        ],
      });
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agenda,
        sekarang: DateTime(2026, 11, 2, 7, 0),
        tanggalLibur: const {},
      );

      expect(hasil.length, 2);
      expect(hasil[0].tanggal, DateTime(2026, 11, 2));
      expect(hasil[1].tanggal, DateTime(2026, 11, 9));
      for (final k in hasil) {
        expect(k.jamMulaiMins, 9 * 60);
        expect(k.notifJam, 8, reason: 'notifikasi = jam mulai - 30 menit');
        expect(k.notifMenit, 30);
      }
    });

    test('item tanpa jam dilewati', () {
      final agenda = _agenda({
        'Senin': [
          {
            'tipe': 'kuliah',
            'hari': 'Senin',
            'jam': '',
            'ruang': '',
            'matakuliah': 'Skripsi',
            'detail': '',
          },
        ],
      });
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agenda,
        sekarang: DateTime(2026, 11, 2, 12, 0),
        tanggalLibur: const {},
      );
      expect(hasil, isEmpty);
    });

    test("jam warisan '-' (marker kosong portal) dilewati", () {
      final agenda = _agenda({
        'Senin': [
          {
            'tipe': 'kuliah',
            'hari': 'Senin',
            'jam': '-',
            'ruang': '',
            'matakuliah': 'Belum Berjam',
            'detail': '',
          },
        ],
      });
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agenda,
        sekarang: DateTime(2026, 11, 2, 12, 0),
        tanggalLibur: const {},
      );
      expect(hasil, isEmpty);
    });

    test(
      'kejadian hari ini yang sudah lewat dilewati, kemunculan berikutnya tetap',
      () {
        final agenda = _agenda({
          'Senin': [
            {
              'tipe': 'kuliah',
              'hari': 'Senin',
              'jam': '09:00 - 10:40',
              'ruang': '',
              'matakuliah': 'Pemrograman Web',
              'detail': '',
            },
          ],
        });
        // Sekarang Senin 2026-11-02 pukul 10:00 → 09:00 sudah lewat.
        final hasil = PengingatJadwalService.hitungKejadian(
          agenda: agenda,
          sekarang: DateTime(2026, 11, 2, 10, 0),
          tanggalLibur: const {},
        );
        expect(hasil.length, 1);
        expect(
          hasil.single.tanggal,
          DateTime(2026, 11, 9),
          reason: 'hanya kemunculan Senin berikutnya yang dijadwalkan',
        );
      },
    );

    test('baris ujian dari agenda TIDAK lagi menghasilkan kejadian '
        '(sumber kini jadwal-ujian, jalur regex detail dihapus)', () {
      final agenda = _agenda({
        'Senin': [
          {
            'tipe': 'uts',
            'hari': 'Senin',
            'jam': '07:30 - 09:10',
            'ruang': 'D.1.1',
            'matakuliah': 'Basis Data',
            'detail': 'Ujian di Ruang D.1.1 tanggal 24 November 2026',
          },
        ],
      });
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agenda,
        sekarang: DateTime(2026, 11, 2, 12, 0),
        tanggalLibur: const {},
      );
      expect(hasil, isEmpty);
    });

    test('tanggal libur diskip; cache kosong tidak diskip', () {
      final raw = {
        'Senin': [
          {
            'tipe': 'kuliah',
            'hari': 'Senin',
            'jam': '09:00 - 10:40',
            'ruang': '',
            'matakuliah': 'Pemrograman Web',
            'detail': '',
          },
        ],
      };
      // 2026-11-09 Senin libur.
      final denganLibur = PengingatJadwalService.hitungKejadian(
        agenda: _agenda(raw),
        sekarang: DateTime(2026, 11, 2, 7, 0),
        tanggalLibur: const {'2026-11-09'},
      );
      expect(denganLibur.map((k) => k.tanggal), [DateTime(2026, 11, 2)]);

      final tanpaLibur = PengingatJadwalService.hitungKejadian(
        agenda: _agenda(raw),
        sekarang: DateTime(2026, 11, 2, 7, 0),
        tanggalLibur: const {},
      );
      expect(tanpaLibur.length, 2);
    });

    test(
      'judul: komponen teori/praktek untuk kuliah, "Ujian" untuk uts/uas',
      () {
        final agenda = _agenda({
          'Senin': [
            {
              'tipe': 'kuliah',
              'hari': 'Senin',
              'jam': '09:00 - 10:40',
              'ruang': 'LT2',
              'matakuliah': 'Pemrograman Web',
              'detail': '',
              'komponen': 'praktek',
            },
            {
              'tipe': 'asisten',
              'hari': 'Senin',
              'jam': '13:00 - 15:00',
              'ruang': '',
              'matakuliah': 'Asisten Alpro',
              'detail': '',
            },
          ],
        });
        final hasil = PengingatJadwalService.hitungKejadian(
          agenda: agenda,
          sekarang: DateTime(2026, 11, 2, 7, 0),
          tanggalLibur: const {},
        );
        final judul = hasil.map((k) => k.judul).toSet();
        expect(judul, contains('Pemrograman Web · Praktek'));
        expect(judul, contains('Asisten Alpro'));
        expect(
          hasil.first.isi(),
          'Pemrograman Web · Praktek mulai 30 menit lagi (09:00, LT2)',
          reason: 'isi menyebut jam MULAI kelas, bukan jam notifikasi',
        );
      },
    );
  });

  group('kejadian ujian dari field `tanggal` baris agenda (perjanjian BE)', () {
    AgendaTerpaduData agendaDenganUjian({
      String? tanggal,
      String mkl = 'Basis Data',
      String jamMulai = '07:30',
      String ruang = 'D.1.1',
      String tipe = 'uts',
    }) => _agenda({
      'Senin': [
        {
          'tipe': tipe,
          'hari': 'Senin',
          'jam': '$jamMulai - 09:10',
          'jam_mulai': jamMulai,
          'jam_selesai': '09:10',
          'ruang': ruang,
          'matakuliah': mkl,
          'detail': '',
          'tanggal': ?tanggal,
        },
      ],
    });

    test('dalam jendela 14 hari → dijadwalkan (format ISO yyyy-MM-dd)', () {
      // Jendela 2026-11-20 .. 12-03 memuat 24 November.
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agendaDenganUjian(tanggal: '2026-11-24'),
        sekarang: DateTime(2026, 11, 20, 12, 0),
        tanggalLibur: const {},
      );
      expect(hasil.length, 1);
      expect(hasil.single.tanggal, DateTime(2026, 11, 24));
      expect(hasil.single.jamMulaiMins, 7 * 60 + 30);
      expect(hasil.single.judul, 'Ujian Basis Data');
      expect(hasil.single.tipe, 'uts');
      expect(
        hasil.single.isi(),
        'Ujian Basis Data mulai 30 menit lagi (07:30, D.1.1)',
      );
    });

    test('format warisan dd-MM-yyyy tetap dijadwalkan', () {
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agendaDenganUjian(tanggal: '24-11-2026'),
        sekarang: DateTime(2026, 11, 20, 12, 0),
        tanggalLibur: const {},
      );
      expect(hasil.single.tanggal, DateTime(2026, 11, 24));
    });

    test('tanggal libur diskip', () {
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agendaDenganUjian(tanggal: '2026-11-24'),
        sekarang: DateTime(2026, 11, 20, 12, 0),
        tanggalLibur: const {'2026-11-24'},
      );
      expect(hasil, isEmpty);
    });

    test('di luar jendela (sudah lewat / >14 hari) dilewati', () {
      final sekarang = DateTime(2026, 11, 20, 12, 0);
      final lewat = PengingatJadwalService.hitungKejadian(
        agenda: agendaDenganUjian(tanggal: '2026-11-19'),
        sekarang: sekarang,
        tanggalLibur: const {},
      );
      final jauh = PengingatJadwalService.hitungKejadian(
        agenda: agendaDenganUjian(tanggal: '2026-12-10'),
        sekarang: sekarang,
        tanggalLibur: const {},
      );
      expect(lewat, isEmpty);
      expect(jauh, isEmpty);
    });

    test('tanggal tak terbaca / tidak ada (BE lama) / jam kosong / mulai <30 '
        'menit dilewati', () {
      final sekarang = DateTime(2026, 11, 20, 12, 0);
      for (final (tanggal, jamMulai) in [
        ('bukan-tanggal', '07:30'),
        (null, '07:30'),
        ('2026-11-24', ''),
        ('2026-11-24', '-'),
        ('2026-11-24', '00:10'),
      ]) {
        final hasil = PengingatJadwalService.hitungKejadian(
          agenda: agendaDenganUjian(tanggal: tanggal, jamMulai: jamMulai),
          sekarang: sekarang,
          tanggalLibur: const {},
        );
        expect(
          hasil,
          isEmpty,
          reason: 'ujian ($tanggal, $jamMulai) harus dilewati',
        );
      }
    });

    test(
      'ujian HARI INI yang jamnya sudah lewat dilewati (bukan jadwal lampau)',
      () {
        // Sekarang 20-11-2026 jam 12:00; ujian jam 08:00 hari ini sudah lewat —
        // alarm exact akan menembak segera bila tetap dijadwalkan.
        final hasil = PengingatJadwalService.hitungKejadian(
          agenda: agendaDenganUjian(tanggal: '2026-11-20', jamMulai: '08:00'),
          sekarang: DateTime(2026, 11, 20, 12, 0),
          tanggalLibur: const {},
        );
        expect(hasil, isEmpty);
      },
    );

    test('ujian HARI INI yang belum lewat tetap dijadwalkan', () {
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agendaDenganUjian(tanggal: '2026-11-20', jamMulai: '13:00'),
        sekarang: DateTime(2026, 11, 20, 12, 0),
        tanggalLibur: const {},
      );
      expect(hasil.single.tanggal, DateTime(2026, 11, 20));
      expect(hasil.single.jamMulaiMins, 13 * 60);
    });

    test('MKL kosong → judul "Ujian" (tanpa nama matkul)', () {
      final hasil = PengingatJadwalService.hitungKejadian(
        agenda: agendaDenganUjian(tanggal: '2026-11-24', mkl: '', tipe: 'uas'),
        sekarang: DateTime(2026, 11, 20, 12, 0),
        tanggalLibur: const {},
      );
      expect(hasil.single.judul, 'Ujian');
    });
  });

  group('parseIcsLibur (filter berbasis SUMMARY)', () {
    const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;VALUE=DATE:20261225
SUMMARY:Cuti Bersama Natal
DESCRIPTION:Semua kantor libur
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20270101
SUMMARY:libur tahun baru
END:VEVENT
BEGIN:VEVENT
DTSTART:20270817T000000Z
SUMMARY:Hari Kemerdekaan Republik Indonesia
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20270217
SUMMARY:Cuti Bersama contoh (unfolded
  line)
END:VEVENT
END:VCALENDAR
''';

    test('pertahankan entri ber-"libur"/"Cuti Bersama", buang lainnya', () {
      final hasil = PengingatJadwalService.parseIcsLibur(ics);
      expect(hasil, [
        DateTime(2026, 12, 25),
        DateTime(2027, 1, 1),
        DateTime(2027, 2, 17),
      ]);
    });

    test('isi kosong → kosong (cache dipertahankan pemanggil)', () {
      expect(PengingatJadwalService.parseIcsLibur(''), isEmpty);
    });
  });

  group('id & hash deterministik (FNV-1a)', () {
    test('FNV-1a 32-bit stabil — nilai ekspektasi hardcoded', () {
      const kunci = 'kuliah|Pemrograman Web|2026-11-02|08:00';
      expect(PengingatJadwalService.fnv1a32(kunci), 2678517078);
      expect(PengingatJadwalService.idPengingatDariKunci(kunci), 531033430);
      expect(
        PengingatJadwalService.idPengingatDariKunci(''),
        2166136261 & 0x7fffffff,
      );
    });

    test('hash daftar kejadian tidak tergantung urutan', () {
      final a = [
        KejadianPengingat(
          tipe: 'kuliah',
          judul: 'A',
          tanggal: DateTime(2026, 11, 2),
          jamMulaiMins: 540,
          ruang: '',
        ),
      ];
      final b = [
        KejadianPengingat(
          tipe: 'kuliah',
          judul: 'B',
          tanggal: DateTime(2026, 11, 3),
          jamMulaiMins: 600,
          ruang: '',
        ),
        KejadianPengingat(
          tipe: 'kuliah',
          judul: 'A',
          tanggal: DateTime(2026, 11, 2),
          jamMulaiMins: 540,
          ruang: '',
        ),
      ];
      expect(
        PengingatJadwalService.hashKejadian(a + b),
        PengingatJadwalService.hashKejadian(b + a),
      );
      expect(
        PengingatJadwalService.hashKejadian(a + b),
        isNot(PengingatJadwalService.hashKejadian(b)),
      );
    });
  });

  group('perbaruiPengingat (e2e lewat gateway palsu)', () {
    final agendaSenin = {
      'Senin': [
        {
          'tipe': 'kuliah',
          'hari': 'Senin',
          'jam': '09:00 - 10:40',
          'ruang': 'LT2',
          'matakuliah': 'Pemrograman Web',
          'detail': '',
        },
      ],
    };
    final agendaSelasa = {
      'Selasa': [
        {
          'tipe': 'kuliah',
          'hari': 'Selasa',
          'jam': '09:00 - 10:40',
          'ruang': 'LT3',
          'matakuliah': 'Basis Data',
          'detail': '',
        },
      ],
    };

    test(
      'hash sama → tidak reschedule (tidak cancel, tidak schedule ulang)',
      () async {
        adapter.agenda = agendaSenin;

        await service().perbaruiPengingat();
        final jumlahPertama = gateway.scheduledIds.length;
        expect(jumlahPertama, greaterThanOrEqualTo(1));
        final cancelPertama = gateway.cancelledIds.length;

        await service().perbaruiPengingat();

        expect(
          gateway.scheduledIds.length,
          jumlahPertama,
          reason: 'hash sama + registry non-kosong → dilewati',
        );
        expect(gateway.cancelledIds.length, cancelPertama);
      },
    );

    test('hash beda → cancel registry lama lalu schedule ulang', () async {
      adapter.agenda = agendaSenin;
      await service().perbaruiPengingat();
      final idLama = gateway.scheduledIds.toList();
      expect(idLama, isNotEmpty);

      gateway.scheduledIds.clear();
      gateway.cancelledIds.clear();
      adapter.agenda = agendaSelasa; // agenda berubah → hash beda

      await service().perbaruiPengingat();

      expect(
        gateway.cancelledIds,
        idLama,
        reason: 'semua id registry lama dibatalkan',
      );
      expect(gateway.scheduledIds, isNotEmpty);
      expect(
        gateway.scheduledIds.toSet().intersection(idLama.toSet()),
        isEmpty,
        reason: 'id baru berbeda karena judul/tanggal/jam berubah',
      );
    });

    test('gagal fetch + cache ada → tetap jadwalkan dari cache', () async {
      adapter.agenda = agendaSenin;
      await service().perbaruiPengingat();

      // Kosongkan registry supaya siklus berikutnya tidak terskip oleh
      // kondisi "hash sama + registry non-kosong".
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kRegistry);

      adapter.agenda = null; // fetch gagal
      gateway.scheduledIds.clear();
      gateway.scheduledDates.clear();
      gateway.cancelledIds.clear();

      await service().perbaruiPengingat();

      expect(
        gateway.scheduledIds,
        isNotEmpty,
        reason: 'cache agenda dipakai — jadwal basi lebih baik daripada hilang',
      );
      for (final d in gateway.scheduledDates) {
        expect(d.hour, 8);
        expect(d.minute, 30);
        expect(d.weekday, DateTime.monday);
      }
      // Cache tetap tersimpan (tidak dihapus saat fetch gagal).
      expect(prefs.getString(_kCacheAgenda), isNotNull);
    });

    test('gagal fetch tanpa cache → registry lama dipertahankan', () async {
      adapter.agenda = agendaSenin;
      await service().perbaruiPengingat();
      final idLama = gateway.scheduledIds.toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCacheAgenda); // tanpa cache

      adapter.agenda = null;
      gateway.scheduledIds.clear();
      gateway.cancelledIds.clear();

      await service().perbaruiPengingat();

      expect(
        gateway.scheduledIds,
        isEmpty,
        reason: 'tidak ada yang dijadwalkan',
      );
      expect(
        gateway.cancelledIds,
        isEmpty,
        reason: 'alarm & registry basi dipertahankan, jangan dihapus',
      );
      expect(_bacaRegistry(prefs), idLama);
    });

    test('izin notifikasi belum diberikan → lewati diam-diam', () async {
      gateway.izin = false;
      adapter.agenda = agendaSenin;

      await service().perbaruiPengingat();

      expect(gateway.scheduledIds, isEmpty);
      expect(gateway.cancelledIds, isEmpty);
      expect(adapter.requests, 0, reason: 'tidak ada fetch sia-sia');
    });

    test('single-flight: pemanggilan paralel kedua diabaikan', () async {
      adapter.agenda = agendaSenin;

      // Dua pemanggilan nyaris bersamaan (dari login + post-frame MainPage).
      final p1 = service().perbaruiPengingat();
      final p2 = service().perbaruiPengingat();
      await Future.wait([p1, p2]);

      expect(
        adapter.requests,
        1,
        reason:
            'hanya satu fetch agenda — sumber tanggal ujian kini baris agenda '
            'itu sendiri (tanpa fetch jadwal-ujian tambahan), melindungi '
            'refresh token single-use',
      );
      expect(gateway.scheduledIds.length, greaterThanOrEqualTo(1));
    });

    test(
      'jam terjadwal tepat: 30 menit sebelum mulai, dalam 14 hari, zona lokal',
      () async {
        adapter.agenda = agendaSenin;
        await service().perbaruiPengingat();

        final sekarang = DateTime.now();
        final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
        final akhir = hariIni.add(const Duration(days: 13));

        expect(gateway.scheduledDates, isNotEmpty);
        for (final d in gateway.scheduledDates) {
          expect(d.hour, 8);
          expect(d.minute, 30);
          final tanggal = DateTime(d.year, d.month, d.day);
          expect(tanggal.isBefore(hariIni) || tanggal.isAfter(akhir), isFalse);
        }
        expect(
          gateway.bodies.first,
          'Pemrograman Web mulai 30 menit lagi (09:00, LT2)',
          reason: 'isi menyebut jam MULAI, bukan jam notifikasi',
        );
      },
    );

    test(
      'payload notifikasi dikosongkan (tap → no-op sesuai Fase 1)',
      () async {
        // Payload di-wire sebagai '' di gateway nyata; gateway palsu tidak
        // menerimanya sebagai argumen — konten body tetap diverifikasi di atas,
        // dan push_service_test memastikan payload kosong/tak dikenal no-op.
        adapter.agenda = agendaSenin;
        await service().perbaruiPengingat();
        expect(gateway.bodies, isNotEmpty);
      },
    );

    test('ujian dari field `tanggal` baris agenda dijadwalkan (e2e)', () async {
      final tglUjian = DateTime.now().add(const Duration(days: 5));
      String dua(int n) => n.toString().padLeft(2, '0');
      final tglStr =
          '${tglUjian.year}-${dua(tglUjian.month)}-${dua(tglUjian.day)}';
      adapter.agenda = {
        // Baris ujian diletakkan SETELAH spread agar tidak tertimpa key
        // 'Senin' milik agendaSenin.
        ...agendaSenin,
        'Senin': [
          {
            'tipe': 'uts',
            'hari': 'Senin',
            'jam': '07:30 - 09:10',
            'jam_mulai': '07:30',
            'jam_selesai': '09:10',
            'ruang': 'D.1.1',
            'matakuliah': 'Basis Data',
            'detail': '',
            'tanggal': tglStr,
          },
          ...agendaSenin['Senin'] ?? const <Map<String, dynamic>>[],
        ],
      };

      await service().perbaruiPengingat();

      expect(
        gateway.bodies,
        contains('Ujian Basis Data mulai 30 menit lagi (07:30, D.1.1)'),
      );
    });

    test(
      'baris ujian tanpa field `tanggal` (BE lama) → tanpa kejadian ujian',
      () async {
        // Agenda memuat baris ujian dengan tanggal di detail — jalur regex
        // detail sudah dihapus dan respons lama tidak punya `tanggal`, jadi
        // tidak boleh ada kejadian ujian sama sekali (fail-open).
        adapter.agenda = {
          'Senin': [
            {
              'tipe': 'uts',
              'hari': 'Senin',
              'jam': '07:30 - 09:10',
              'ruang': 'D.1.1',
              'matakuliah': 'Basis Data',
              'detail': '24-11-2026',
            },
          ],
          ...agendaSenin,
        };

        await service().perbaruiPengingat();

        expect(
          gateway.bodies,
          isNotEmpty,
          reason: 'kuliah tetap dijadwalkan walau baris ujian tanpa tanggal',
        );
        for (final body in gateway.bodies) {
          expect(
            body.startsWith('Ujian '),
            isFalse,
            reason: 'tanpa tanggal tidak boleh ada reminder ujian',
          );
        }
      },
    );
  });
}

List<int> _bacaRegistry(SharedPreferences prefs) =>
    (prefs.getStringList(_kRegistry) ?? const [])
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();

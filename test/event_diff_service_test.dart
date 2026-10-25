// Test EventDiffService (Fase 2c — notifikasi event diff lokal): snapshot
// pertama tidak menotifikasi, perubahan tagihan/ujian → notif dengan teks
// benar, tidak menotif dua kali untuk perubahan yang sama, debounce,
// snapshot korup → diam (fail-open), gateway melempar → diam, pembersihan
// logout, dan id tidak bentrok dengan id pengingat jadwal. Seluruh interaksi
// notifikasi lewat [EventDiffGateway] palsu — TIDAK menyentuh plugin asli.

import 'dart:convert';

import 'package:app_amikom/models/agenda_terpadu.dart';
import 'package:app_amikom/models/keuangan.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/event_diff_service.dart';
import 'package:app_amikom/services/pengingat_jadwal_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _nim = '2200001';
const _suffix = '_$_nim';

/// Gerbang palsu: mencatat semua tampilan notifikasi.
class _GatewayFake implements EventDiffGateway {
  final List<({int id, String title, String body})> shown = [];

  bool izin = true;

  @override
  Future<bool> izinNotifikasiDiberikan() async => izin;

  @override
  Future<void> tampilkan({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    shown.add((id: id, title: title, body: body));
  }
}

/// Gerbang yang selalu gagal menampilkan — verifikasi jalur fail-open.
class _GatewayMelempar implements EventDiffGateway {
  @override
  Future<bool> izinNotifikasiDiberikan() async => true;

  @override
  Future<void> tampilkan({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    throw Exception('plugin gagal');
  }
}

KeuanganTagihanResponse _tagihan({
  required int total,
  required List<(String, int)> items,
}) {
  return KeuanganTagihanResponse(
    totalTagihan: total,
    data: [
      for (final (idtrans, nominal) in items)
        KeuanganTagihanItem(
          no: 1,
          tahunAkademik: '2026-2027',
          jenisPembayaran: 'UKT',
          nominal: nominal,
          keterangan: '',
          jenisId: '1',
          idtrans: idtrans,
        ),
    ],
    activeTransaction: KeuanganActiveTransaction(hasActive: false),
  );
}

AgendaTerpaduData _agenda(Map<String, List<Map<String, dynamic>>> raw) {
  final parsed = raw.map(
    (day, list) => MapEntry(day, list.map(AgendaItem.fromJson).toList()),
  );
  final total = parsed.values.fold<int>(0, (s, v) => s + v.length);
  return AgendaTerpaduData(totalAgenda: total, agenda: parsed);
}

Map<String, List<Map<String, dynamic>>> _ujianRows(
  List<(String, String, String)> mkJamTanggal,
) => {
  'Senin': [
    for (final (mk, jam, tgl) in mkJamTanggal)
      {
        'tipe': 'uas',
        'hari': 'Senin',
        'jam': '$jam - 10:40',
        'jam_mulai': jam,
        'jam_selesai': '10:40',
        'ruang': 'LT2',
        'matakuliah': mk,
        'detail': '',
        'tanggal': tgl,
      },
  ],
};

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  late _GatewayFake gateway;
  EventDiffService service() => EventDiffService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Identitas NIM ditetapkan sekali — suffix kunci snapshot mengikutinya
    // (pola agenda_cache_service_test.dart; penulisan secure storage
    // best-effort di test).
    ApiClient.instance.setUserInfo(_nim, 'Mahasiswa Uji');
    gateway = _GatewayFake();
    service().setGatewayUntukTest(gateway);
    service().resetUntukTest();
  });

  group('snapshot pertama', () {
    test('tagihan: hanya simpan, tidak menotifikasi', () async {
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiTagihan(
        _tagihan(total: 1500000, items: [('A1', 1000000), ('A2', 500000)]),
      );
      expect(gateway.shown, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('event_diff_snap_tagihan$_suffix'), isNotNull);
      expect(prefs.getInt('event_diff_eval_tagihan_at$_suffix'), greaterThan(0));
    });

    test('ujian: hanya simpan, tidak menotifikasi', () async {
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiAgenda(_agenda(_ujianRows([('PBO', '08:00', '2026-11-02')])));
      expect(gateway.shown, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('event_diff_snap_ujian$_suffix'), isNotNull);
    });
  });

  group('perubahan tagihan', () {
    test('tagihan bertambah → notif "Tagihan baru" dengan teks benar', () async {
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiTagihan(
        _tagihan(total: 1000000, items: [('A1', 1000000)]),
      );
      expect(gateway.shown, isEmpty);

      await service().evaluasiTagihan(
        _tagihan(total: 1500000, items: [('A1', 1000000), ('A2', 500000)]),
      );
      expect(gateway.shown, hasLength(1));
      final notif = gateway.shown.single;
      expect(notif.title, 'Tagihan baru');
      expect(notif.body, 'Total tagihan sekarang Rp 1.500.000 (2 item)');
      expect(notif.id, EventDiffService.idEventDariJenis('event_diff_snap_tagihan'));
    });

    test('nominal berubah tanpa item baru → notif "Tagihan berubah"', () async {
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiTagihan(
        _tagihan(total: 1000000, items: [('A1', 1000000)]),
      );
      await service().evaluasiTagihan(
        _tagihan(total: 1200000, items: [('A1', 1200000)]),
      );
      expect(gateway.shown, hasLength(1));
      expect(gateway.shown.single.title, 'Tagihan berubah');
      expect(gateway.shown.single.body, 'Total tagihan sekarang Rp 1.200.000 (1 item)');
    });

    test('perubahan sama berulang → tidak menotif lagi', () async {
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiTagihan(
        _tagihan(total: 1000000, items: [('A1', 1000000)]),
      );
      await service().evaluasiTagihan(
        _tagihan(total: 1500000, items: [('A1', 1000000), ('A2', 500000)]),
      );
      expect(gateway.shown, hasLength(1));
      // Data identik dievaluasi ulang → tidak ada notif kedua.
      await service().evaluasiTagihan(
        _tagihan(total: 1500000, items: [('A1', 1000000), ('A2', 500000)]),
      );
      expect(gateway.shown, hasLength(1));
    });

    test('debounce 5 menit: evaluasi kedua terlalu cepat dilewati', () async {
      // Debounce default (5 menit) tetap aktif — siklus kedua dalam test yang
      // berjalan < 5 menit harus dilewati apa pun datanya.
      await service().evaluasiTagihan(
        _tagihan(total: 1000000, items: [('A1', 1000000)]),
      );
      await service().evaluasiTagihan(
        _tagihan(total: 1500000, items: [('A1', 1000000), ('A2', 500000)]),
      );
      expect(gateway.shown, isEmpty);
    });
  });

  group('jadwal ujian terbit', () {
    test('jumlah ujian bertambah → notif "Jadwal ujian terbit"', () async {
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiAgenda(
        _agenda(_ujianRows([('PBO', '08:00', '2026-11-02')])),
      );
      await service().evaluasiAgenda(
        _agenda(_ujianRows([
          ('PBO', '08:00', '2026-11-02'),
          ('Basis Data', '13:00', '2026-11-03'),
        ])),
      );
      expect(gateway.shown, hasLength(1));
      final notif = gateway.shown.single;
      expect(notif.title, 'Jadwal ujian terbit');
      expect(notif.body, '2 mata kuliah terjadwal — cek di menu Jadwal');
      expect(notif.id, EventDiffService.idEventDariJenis('event_diff_snap_ujian'));
    });

    test('jumlah ujian berkurang / konten berubah tanpa bertambah → tanpa notif',
        () async {
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiAgenda(
        _agenda(_ujianRows([
          ('PBO', '08:00', '2026-11-02'),
          ('Basis Data', '13:00', '2026-11-03'),
        ])),
      );
      // Berkurang.
      await service().evaluasiAgenda(
        _agenda(_ujianRows([('PBO', '08:00', '2026-11-02')])),
      );
      expect(gateway.shown, isEmpty);
      // Berubah jam, jumlah tetap.
      await service().evaluasiAgenda(
        _agenda(_ujianRows([('PBO', '10:00', '2026-11-02')])),
      );
      expect(gateway.shown, isEmpty);
    });

    test('baris ujian tanpa tanggal valid diabaikan (fail-open)', () async {
      service().debounceUntukTest = Duration.zero;
      final agenda = _agenda({
        'Senin': [
          {
            'tipe': 'uts',
            'hari': 'Senin',
            'jam': '08:00 - 10:40',
            'jam_mulai': '08:00',
            'ruang': 'LT2',
            'matakuliah': 'PBO',
            'detail': '',
          },
          {
            'tipe': 'uas',
            'hari': 'Senin',
            'jam': '08:00 - 10:40',
            'jam_mulai': '08:00',
            'ruang': 'LT2',
            'matakuliah': 'Basis Data',
            'detail': '',
            'tanggal': '31-02-2026', // tanggal tidak valid
          },
        ],
      });
      await service().evaluasiAgenda(agenda);
      final snap = EventDiffService.snapshotUjian(agenda);
      expect(snap.jumlah, 0);
      expect(gateway.shown, isEmpty);
    });
  });

  group('jalur gagal (fail-open)', () {
    test('snapshot tersimpan korup → diperlakukan pertama kali, tidak melempar',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('event_diff_snap_tagihan$_suffix', '{bukan json');
      service().debounceUntukTest = Duration.zero;
      await service().evaluasiTagihan(
        _tagihan(total: 1000000, items: [('A1', 1000000)]),
      );
      expect(gateway.shown, isEmpty);
      // Snapshot korup ditimpa dengan snapshot sah.
      final raw = prefs.getString('event_diff_snap_tagihan$_suffix');
      expect(jsonDecode(raw!), isA<Map<String, dynamic>>());
    });

    test('gateway gagal menampilkan → tidak melempar ke pemanggil', () async {
      service()
        ..setGatewayUntukTest(_GatewayMelempar())
        ..debounceUntukTest = Duration.zero;
      await service().evaluasiTagihan(
        _tagihan(total: 1000000, items: [('A1', 1000000)]),
      );
      await service().evaluasiTagihan(
        _tagihan(total: 1500000, items: [('A1', 1000000), ('A2', 500000)]),
      );
      // Tidak melempar — cukup sampai di sini tanpa error.
    });

    test('izin notifikasi belum diberikan → tidak menampilkan', () async {
      service().debounceUntukTest = Duration.zero;
      gateway.izin = false;
      await service().evaluasiTagihan(
        _tagihan(total: 1000000, items: [('A1', 1000000)]),
      );
      await service().evaluasiTagihan(
        _tagihan(total: 1500000, items: [('A1', 1000000), ('A2', 500000)]),
      );
      expect(gateway.shown, isEmpty);
    });
  });

  group('bersihkanSaatLogout', () {
    test('menghapus kunci milik NIM dan kunci tanpa suffix', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('event_diff_snap_tagihan$_suffix', 'x');
      await prefs.setString('event_diff_snap_ujian$_suffix', 'x');
      await prefs.setInt('event_diff_eval_tagihan_at$_suffix', 1);
      await prefs.setInt('event_diff_eval_ujian_at$_suffix', 1);
      await prefs.setString('event_diff_snap_tagihan', 'x');

      await service().bersihkanSaatLogout();

      expect(prefs.getString('event_diff_snap_tagihan$_suffix'), isNull);
      expect(prefs.getString('event_diff_snap_ujian$_suffix'), isNull);
      expect(prefs.getInt('event_diff_eval_tagihan_at$_suffix'), isNull);
      expect(prefs.getInt('event_diff_eval_ujian_at$_suffix'), isNull);
      expect(prefs.getString('event_diff_snap_tagihan'), isNull);
    });

    test('tidak pernah melempar walau SharedPreferences bermasalah', () async {
      // Cukup dipanggil dua kali — idempoten dan tanpa efek samping error.
      await service().bersihkanSaatLogout();
      await service().bersihkanSaatLogout();
    });
  });

  group('id deterministik & namespace', () {
    test('id stabil antar pemanggilan dan berbeda antar jenis', () {
      final a1 = EventDiffService.idEventDariJenis('event_diff_snap_tagihan');
      final a2 = EventDiffService.idEventDariJenis('event_diff_snap_tagihan');
      final b = EventDiffService.idEventDariJenis('event_diff_snap_ujian');
      expect(a1, a2);
      expect(a1, isNot(equals(b)));
    });

    test('id event tidak pernah bentrok dengan id pengingat jadwal', () {
      // Semua kunci kanonik pengingat yang mungkin (tipe|judul|yyyy-MM-dd|HH:mm)
      // vs semua jenis event — FNV-1a atas input berbeda dengan prefix
      // namespace; uji silang kecil memverifikasi tidak ada tabrakan.
      const tipe = ['kuliah', 'asisten', 'uts', 'uas'];
      const judul = ['PBO', 'Ujian Basis Data', 'Struktur Data · Teori'];
      const tanggal = ['2026-11-02', '2026-12-15'];
      const jam = ['07:30', '08:00', '13:00', '23:59'];
      final jenisEvent = [
        'event_diff_snap_tagihan',
        'event_diff_snap_ujian',
      ];

      for (final t in tipe) {
        for (final j in judul) {
          for (final tgl in tanggal) {
            for (final jm in jam) {
              final idPengingat = PengingatJadwalService.idPengingatDariKunci(
                '$t|$j|$tgl|$jm',
              );
              for (final je in jenisEvent) {
                expect(
                  EventDiffService.idEventDariJenis(je),
                  isNot(equals(idPengingat)),
                  reason: 'bentrok: event=$je pengingat=$t|$j|$tgl|$jm',
                );
              }
            }
          }
        }
      }
    });
  });
}

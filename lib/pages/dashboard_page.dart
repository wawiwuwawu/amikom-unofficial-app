import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dashboard.dart';
import '../models/agenda_terpadu.dart';
import '../models/sp.dart';
import '../services/absensi_service.dart';
import '../services/agenda_cache_service.dart';
import '../services/api_client.dart';
import '../services/akademik_service.dart';
import '../services/event_diff_service.dart';
import '../services/periode_ujian_service.dart';
import '../services/sp_service.dart';
import '../theme/app_theme.dart';
import '../utils/waktu.dart';
import '../widgets/app_kit.dart';
import '../widgets/histori_ipk_sheet.dart';
import 'absensi_page.dart';
import 'jadwal_page.dart';
import 'sp_page.dart';
import 'keuangan_page.dart';

/// Beranda (Dashboard).
///
/// Prinsip: **beranda menampilkan INFORMASI, bukan navigasi.** Navigasi adalah
/// tugas bottom navigation.
///
/// Versi lama menaruh baris "aksi cepat" (Presensi / Jadwal / Nilai / Tagihan)
/// di sini, padahal 3 dari 4 tombolnya hanya menuju tab yang sudah ada di
/// bottom nav — dan Presensi bahkan sudah menjadi tombol QR di tengah bar.
/// Baris itu dihapus dan digantikan informasi yang benar-benar dibutuhkan saat
/// membuka aplikasi: jadwal hari ini, peringatan tagihan, dan ringkasan nilai.
class DashboardPage extends StatefulWidget {
  final int refreshTrigger;
  const DashboardPage({super.key, this.refreshTrigger = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _akademikService = AkademikService();
  final _spService = SpService();
  final _absensiService = AbsensiService();

  Dashboard? _data;
  AgendaTerpaduData? _agendaData;
  SpRekomendasiData? _spRekomendasiData;

  /// Hasil cek "sudah presensi?" untuk kartu berjalan: null = sedang mengecek
  /// (tampilan sama seperti belum tahu — tombol tetap ada, tanpa spinner agar
  /// tidak berkedip), false = belum/bisa-jadi-belah (tombol, fail-open),
  /// true = kartu berubah jadi pemberitahuan tanpa tombol.
  bool? _presensiSudahTercatat;

  /// Identitas item berjalan yang sedang/terakhir dicek (matakuliah + jam).
  /// Cek hanya SEKALI per item per sesi build — bukan polling; berganti item
  /// atau refresh/pull-to-reset me-reset nilainya.
  String? _presensiCekKey;

  /// True saat fetch agenda gagal tetapi data cache masih dirender — seksi
  /// "Jadwal Hari Ini" lalu menampilkan label kecil "data terakhir" alih-alih
  /// galat penuh (stale-while-revalidate).
  bool _agendaFetchGagal = false;

  /// Waktu cache agenda terakhir diperbarui (untuk label di atas).
  DateTime? _agendaTerakhirDisimpan;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _agendaFetchGagal = false;
      _agendaTerakhirDisimpan = null;
      // Pull-to-refresh/reset: cek presensi mulai segar sehingga item berjalan
      // dicek ulang sekali setelah agenda termuat.
      _presensiSudahTercatat = null;
      _presensiCekKey = null;
    });

    // Stale-while-revalidate: cache agenda dipakai HANYA untuk render instan;
    // setiap muat dengan koneksi tetap fetch ulang dan menimpa cache. Baca
    // cache sebelum fetch agar state agenda terpasang SEBELUM fetch selesai.
    final cacheAgenda = await AgendaCacheService.instance.baca();
    if (!mounted) return;
    if (cacheAgenda != null) {
      setState(() => _agendaData = cacheAgenda);
    }

    try {
      // Agenda gagal TIDAK dilempar (perilaku existing): flag lokal membedakan
      // "kosong sungguhan" dari "fetch gagal".
      var agendaGagal = false;
      final results = await Future.wait([
        ApiClient.instance.getDashboard(),
        _akademikService.getAgendaTerpadu().catchError((_) {
          agendaGagal = true;
          return AgendaTerpaduData(totalAgenda: 0, agenda: {});
        }),
        _spService.getRekomendasi().catchError(
          (_) => SpRekomendasiData(
            hasRekomendasi: false,
            warningMessage: '',
            totalRekomendasi: 0,
            totalSks: 0,
            kategoriSangatDianjurkan: [],
            kategoriOpsionalSksBesar: [],
          ),
        ),
      ]);
      if (!mounted) return;
      final agenda = agendaGagal ? null : results[1] as AgendaTerpaduData;
      setState(() {
        _data = results[0] as Dashboard;
        _spRekomendasiData = results[2] as SpRekomendasiData;
        _error = null;
        if (agenda != null) {
          _agendaData = agenda;
          _agendaFetchGagal = false;
          _agendaTerakhirDisimpan = null;
        }
        // agendaGagal + cache: _agendaData dari cache dipertahankan (placeholder
        // kosong tidak menimpanya); agendaGagal tanpa cache: perilaku existing
        // (agenda kosong tanpa galat penuh).
      });
      if (agenda != null) {
        // Fetch sukses → cache diperbarui (fire-and-forget; gagal simpan hanya
        // dilog di service).
        unawaited(AgendaCacheService.instance.simpan(agenda));
        // Fase 2c: diff lokal "jadwal ujian terbit" — evaluasi snapshot ujian
        // dari data yang SUDAH di tangan (tanpa fetch tambahan; seluruh jalur
        // fail-open di dalam service, tidak mengganggu halaman).
        unawaited(EventDiffService.instance.evaluasiAgenda(agenda));
      } else if (_agendaData != null) {
        // Fetch gagal tapi data terakhir masih tampil → label kecil, bukan
        // galat penuh untuk seksi agenda.
        final terakhir = await AgendaCacheService.instance.terakhirDisimpan();
        if (!mounted) return;
        setState(() {
          _agendaFetchGagal = true;
          _agendaTerakhirDisimpan = terakhir;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // `userErrorMessage` hanya memakai pesan ramah; detail teknis tidak
      // pernah sampai ke layar.
      setState(
        () => _error = userErrorMessage(
          e,
          'Gagal memuat beranda. Silakan coba lagi.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Bangun halaman ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading(message: 'Memuat beranda…');

    if (_error != null) {
      return SingleChildScrollView(
        padding: AppSpacing.page,
        child: AppErrorState(message: _error!, onRetry: _load),
      );
    }

    // Keadaan ini seharusnya tidak tercapai: beranda selalu punya isi saat
    // pemuatan sukses, dan setiap kegagalan mengisi `_error`. Kalau toh
    // tercapai, jangan tampilkan layar kosong — beri galat + tombol coba lagi.
    final d = _data;
    if (d == null) {
      return SingleChildScrollView(
        padding: AppSpacing.page,
        child: AppErrorState(
          message: 'Data beranda belum tersedia. Silakan muat ulang.',
          onRetry: _load,
        ),
      );
    }

    final perluBayar = d.status.status != 'Aktif' || d.status.status.isEmpty;
    final adaSp = _spRekomendasiData?.hasRekomendasi ?? false;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildGreeting(d.profile).animate().fadeIn(duration: 300.ms),

          // Peringatan hanya muncul bila memang ada masalah — tidak permanen.
          if (perluBayar) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildTagihanAlert().animate().fadeIn(delay: 80.ms),
          ],
          if (adaSp) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildSpRekomendasiBanner(
              _spRekomendasiData!,
            ).animate().fadeIn(delay: 120.ms),
          ],

          // Informasi paling dicari saat membuka aplikasi.
          _buildJadwalHariIni().animate().fadeIn(delay: 160.ms),

          _buildRingkasan(d).animate().fadeIn(delay: 200.ms),

          AppSection(
            title: 'Data Mahasiswa',
            child: _buildProfileCard(d.profile),
          ).animate().fadeIn(delay: 240.ms),
        ],
      ),
    );
  }

  // ── Sapaan ────────────────────────────────────────────────────────────────

  Widget _buildGreeting(Profile p) {
    final namaDepan = p.nama.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Halo, $namaDepan', style: AppText.display),
        const SizedBox(height: AppSpacing.xs),
        Text(p.prodi, style: AppText.bodySm),
      ],
    );
  }

  // ── Peringatan tagihan ────────────────────────────────────────────────────

  Widget _buildTagihanAlert() {
    return AppSurface(
      variant: AppSurfaceVariant.warning,
      onTap: () => _push(KeuanganPage()),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran tertunda',
                  style: AppText.h3.copyWith(color: AppColors.warning),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status akademik belum aktif. Ketuk untuk lihat tagihan.',
                  style: AppText.bodySm,
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  // ── Jadwal hari ini: daftar, bukan tombol menuju jadwal ────────────────────

  Widget _buildJadwalHariIni() {
    final todayName = namaHariDariWeekday(DateTime.now().weekday);
    // Gerbang tampil ujian (tanpa banner, fail-open): baris ujian di luar
    // jendela [PeriodeUjianService.ambangHariUjian] disembunyikan agar
    // "Jadwal Hari Ini" tidak menampilkan ujian sebulan sebelum terbit.
    final items = (_agendaData?.agenda[todayName] ?? const <AgendaItem>[])
        .where(_ujianTampil)
        .toList();
    final ongoing = _ongoingItem(items);

    // Kartu berjalan terdeteksi → cek sekali (unawaited) apakah presensinya
    // sudah tercatat. Tanpa item berjalan TIDAK ada request absensi sama
    // sekali (jangan menambah fetch sia-sia saat agenda kosong).
    if (ongoing != null) _mulaiCekPresensiOngoing(ongoing);

    return AppSection(
      title: 'Jadwal Hari Ini',
      trailing: TextButton(
        onPressed: () => _push(const JadwalPage()),
        child: const Text('Lihat semua'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SWR: fetch gagal tapi cache masih tampil → label kecil, bukan
          // galat penuh.
          if (_agendaFetchGagal) ...[
            Row(
              children: [
                const Icon(
                  CupertinoIcons.info_circle,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    _labelDataTerakhir,
                    style: AppText.label.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (items.isEmpty)
            const AppSurface(
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Tidak ada agenda kuliah atau ujian hari ini.'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                if (ongoing != null) ...[
                  _buildOngoingCard(ongoing),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppListGroup.from([
                  for (final item in items)
                    _agendaRow(item, isOngoing: identical(item, ongoing)),
                ]),
              ],
            ),
        ],
      ),
    );
  }

  /// Label SWR untuk seksi "Jadwal Hari Ini": "Menampilkan data terakhir
  /// (dd/mm hh:mm)" — format manual agar pola token waktu konsisten.
  String get _labelDataTerakhir {
    final t = _agendaTerakhirDisimpan;
    if (t == null) return 'Menampilkan data terakhir';
    String dua(int n) => n.toString().padLeft(2, '0');
    return 'Menampilkan data terakhir '
        '(${dua(t.day)}/${dua(t.month)} ${dua(t.hour)}:${dua(t.minute)})';
  }

  /// Gerbang ujian "Jadwal Hari Ini": non-ujian selalu tampil; ujian tampil
  /// bila tanggal ujiannya sendiri (field `tanggal` baris) dalam jendela —
  /// respons lama tanpa tanggal fail-open (tampil).
  bool _ujianTampil(AgendaItem item) {
    final tipe = item.tipe.trim().toLowerCase();
    if (tipe != 'uts' && tipe != 'uas') return true;
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    return PeriodeUjianService.dalamJendela(
      tanggalDariPortal(item.tanggal ?? ''),
      hariIni,
    );
  }

  AgendaItem? _ongoingItem(List<AgendaItem> items) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    for (final item in items) {
      final range = ongoingRange(item);
      if (range == null) continue;
      final (start, end) = range;
      if (nowMins >= start && nowMins <= end) return item;
    }
    return null;
  }

  /// Mulai cek presensi untuk item berjalan — sekali per item (kunci
  /// matakuliah+jam); item lain menimpa kunci dan cek hasilnya dibuang bila
  /// kunci sudah berganti lagi. Dipanggil saat build; hasil dikirim lewat
  /// setState setelah future selesai.
  void _mulaiCekPresensiOngoing(AgendaItem item) {
    final key = '${item.matakuliah}|${item.jam}';
    if (key == _presensiCekKey) return;
    _presensiCekKey = key;
    _presensiSudahTercatat = null;
    unawaited(_cekPresensiOngoing(item, key));
  }

  Future<void> _cekPresensiOngoing(AgendaItem item, String key) async {
    // Fail-open ganda: service sudah menelan galat, dan catch di sini menutup
    // galat apa pun yang lolos — kartu hanya boleh berubah jadi "tercatat"
    // bila cek BENAR-BENAR sukses dan positif; selain itu tampilan lama.
    bool sudah;
    try {
      sudah = await _absensiService.sudahPresensiHariIni(
        makul: item.matakuliah,
      );
    } catch (_) {
      sudah = false;
    }
    if (!mounted) return;
    if (_presensiCekKey != key) return;
    setState(() => _presensiSudahTercatat = sudah);
  }

  Widget _agendaRow(AgendaItem item, {required bool isOngoing}) {
    final tempat = [
      if (item.ruang.isNotEmpty) item.ruang,
      if (item.detail.isNotEmpty) item.detail,
    ].join(' • ');

    return AppListRow(
      leading: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Text(
          item.jam.split('-').first.trim(),
          style: AppText.h3.copyWith(fontSize: 12.5, color: AppColors.primary),
        ),
      ),
      title: item.matakuliah,
      subtitle: tempat.isEmpty ? null : tempat,
      trailing: isOngoing
          ? const AppPill('Berlangsung', tone: AppPillTone.danger)
          : null,
    );
  }

  Widget _buildOngoingCard(AgendaItem item) {
    // true = ganti tombol dengan pemberitahuan; null (sedang mengecek) dan
    // false (belum tercatat / cek gagal — fail-open) sama-sama menampilkan
    // tombol seperti sebelumnya, sehingga tidak ada perubahan visual
    // perantara (tanpa spinner/disabled yang bisa berkedip).
    final sudahTercatat = _presensiSudahTercatat == true;
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppPill('Sedang berlangsung', tone: AppPillTone.danger),
              const Spacer(),
              Text(item.jam, style: AppText.label),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.matakuliah, style: AppText.h2),
          if (item.ruang.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location_solid,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(item.ruang, style: AppText.bodySm),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (sudahTercatat)
            // Sudah presensi → informatif, tanpa tombol (navigasi tetap bisa
            // lewat baris agenda / tab Presensi).
            Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Presensi tercatat — menunggu validasi dosen',
                    style: AppText.bodySm.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _push(AbsensiPage()),
                icon: const Icon(CupertinoIcons.qrcode_viewfinder, size: 18),
                label: const Text('Presensi Sekarang'),
              ),
            ),
        ],
      ),
    );
  }

  // ── Ringkasan statistik ───────────────────────────────────────────────────

  Widget _buildRingkasan(Dashboard d) {
    return AppSection(
      title: 'Ringkasan Studi',
      child: Row(
        children: [
          Expanded(
            child: AppStatTile(
              value: d.statistik.ipk.toStringAsFixed(2),
              label: 'IPK Kumulatif',
              icon: CupertinoIcons.rosette,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppStatTile(
              value: '${d.statistik.totalSks}',
              label: 'SKS Terkumpul',
              icon: CupertinoIcons.book_fill,
              accent: AppColors.info,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppSurface(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              onTap: () => showHistoriIpkBottomSheet(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.chart_bar_square,
                    size: 16,
                    color: AppColors.primarySoft,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Tren', style: AppText.metric.copyWith(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text('Grafik IPK', style: AppText.label, maxLines: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu data mahasiswa ──────────────────────────────────────────────────

  Widget _buildProfileCard(Profile p) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    p.fotoUrl,
                    width: 48,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 48,
                      height: 64,
                      alignment: Alignment.center,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        CupertinoIcons.person_alt,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.nama, style: AppText.h3),
                      const SizedBox(height: 2),
                      Text('${p.npm} • ${p.prodi}', style: AppText.bodySm),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: AppSpacing.card,
            child: Column(
              children: [
                AppKeyValue(label: 'Angkatan', value: p.angkatan.toString()),
                AppKeyValue(label: 'Fakultas', value: p.fakultas),
                AppKeyValue(label: 'Email', value: p.email),
                AppKeyValue(
                  label: 'No. HP',
                  value: p.noHp.isNotEmpty ? p.noHp : '—',
                ),
                AppKeyValue(
                  label: 'Dosen PA',
                  value: p.pembimbingAkademik.isEmpty
                      ? '—'
                      : p.pembimbingAkademik,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner rekomendasi Semester Pendek ────────────────────────────────────

  Widget _buildSpRekomendasiBanner(SpRekomendasiData rekomendasi) {
    return AppSurface(
      variant: AppSurfaceVariant.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Rekomendasi Semester Pendek',
                  style: AppText.h3.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${rekomendasi.totalRekomendasi} mata kuliah • '
            '${rekomendasi.totalSks} SKS disarankan',
            style: AppText.label.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(rekomendasi.warningMessage, style: AppText.bodySm),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _push(SpPage()),
              icon: const Icon(
                CupertinoIcons.arrow_right_circle_fill,
                size: 18,
              ),
              label: const Text('Lihat Rekomendasi'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilitas ──────────────────────────────────────────────────────────────

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

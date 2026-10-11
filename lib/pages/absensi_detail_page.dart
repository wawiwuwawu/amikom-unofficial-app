import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/absensi.dart';
import '../services/absensi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Detail satu pertemuan presensi.
///
/// Dibuka dari riwayat di halaman absensi. Jika pertemuan belum divalidasi,
/// halaman ini menampilkan form validasi; jika sudah, form disembunyikan dan
/// hanya informasi pertemuan yang tampil.
class AbsensiDetailPage extends StatefulWidget {
  final String idPresensi;

  /// Pertemuan terpilih dari halaman daftar (opsional). Dipakai untuk
  /// mengisi `jenispilih`/`kuliahteori`/`kuliahpraktek` dari field portal
  /// (hanya ada untuk status 'B'), bukan menebak dari keterangan.
  final RiwayatPertemuan? pertemuan;

  const AbsensiDetailPage({
    super.key,
    required this.idPresensi,
    this.pertemuan,
  });

  @override
  State<AbsensiDetailPage> createState() => _AbsensiDetailPageState();
}

class _AbsensiDetailPageState extends State<AbsensiDetailPage> {
  final _service = AbsensiService();
  PresensiDetail? _detail;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _kesesuaianPerkuliahan = TextEditingController(text: '1');
  final _kesesuaianMateri = TextEditingController(text: '1');
  final _penilaianMhs = TextEditingController(text: '4');
  final _kritikSaran = TextEditingController();

  final Map<String, String> _asdosPenilaian = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _kesesuaianPerkuliahan.dispose();
    _kesesuaianMateri.dispose();
    _penilaianMhs.dispose();
    _kritikSaran.dispose();
    super.dispose();
  }

  /// Satu-satunya urutan yang dipakai form: seeding nilai, render dropdown,
  /// dan key `asdospenilaian` WAJIB identik. Praktikum mengirim `asdoss[]`
  /// (satu set kriteria per asdos, indeks = posisi npm di `asdos_npms`);
  /// selain itu dipakai kriteria tingkat atas dengan indeks 0.
  ///
  /// Komponen ketiga adalah label asdos (hanya bila >1 asdos, agar dropdown
  /// bernama sama tetap bisa dibedakan) — dikosongkan untuk kasus lainnya.
  List<(int, Kriteria, String?)> _formPairs(PresensiDetail d) {
    if (d.asdoss.isEmpty) {
      return [for (final k in d.kriterias) (0, k, null)];
    }
    if (d.asdoss.length == 1) {
      return [for (final k in d.asdoss.first.kriterias) (0, k, null)];
    }
    return [
      for (var i = 0; i < d.asdoss.length; i++)
        for (var j = 0; j < d.asdoss[i].kriterias.length; j++)
          (
            i,
            d.asdoss[i].kriterias[j],
            j == 0 && d.asdoss[i].nama.isNotEmpty ? d.asdoss[i].nama : null,
          ),
    ];
  }

  /// Key kiriman `asdospenilaian`: "{indeksAsdos}_{kriteriaId}".
  static String _penilaianKey(int asdosIndex, Kriteria k) =>
      '${asdosIndex}_${k.id}';

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getPresensiDetail(widget.idPresensi);
      if (!mounted) return;
      setState(() {
        _detail = data;
        _error = null;
        for (final (asdosIndex, k, _) in _formPairs(data)) {
          final best = k.nilai.isNotEmpty
              ? k.nilai.reduce((a, b) => a.nilai >= b.nilai ? a : b)
              : null;
          if (best != null) {
            _asdosPenilaian[_penilaianKey(asdosIndex, k)] = best.id;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitValidasi() async {
    final d = _detail;
    if (d == null) return;
    setState(() => _submitting = true);
    try {
      await _service.validasi({
        'jenispilih': widget.pertemuan?.jenis ?? 'teori',
        'idpresensimhstexs': d.idPresensiMhs,
        'idpresensidosen': d.idPresensiDosen,
        'kuliahteori': widget.pertemuan?.idKuliahTeori ?? d.kuliahTpId,
        'kuliahpraktek': widget.pertemuan?.idKuliahPraktek ?? '0',
        'kesesuaian_perkuliahan': _kesesuaianPerkuliahan.text,
        'kesesuaian_materi': _kesesuaianMateri.text,
        'penilaianmhs': _penilaianMhs.text,
        'kritiksaran': _kritikSaran.text,
        'asdos_npms': [for (final a in d.asdoss) a.npm],
        'asdospenilaian': _asdosPenilaian,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validasi berhasil'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final message = userErrorMessage(e).trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty
                  ? message
                  : 'Gagal melakukan validasi presensi',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static AppPillTone _statusTone(String status) {
    switch (status.toUpperCase()) {
      case 'H':
        return AppPillTone.success;
      case 'B':
        return AppPillTone.danger;
      case 'I':
        return AppPillTone.info;
      case 'S':
        return AppPillTone.warning;
      default:
        return AppPillTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detail Presensi',
      subtitle: 'Validasi kehadiran satu pertemuan',
      body: AppAsyncView<PresensiDetail>(
        loading: _loading,
        error: _error,
        data: _detail,
        onRetry: _load,
        loadingMessage: 'Memuat detail presensi…',
        emptyTitle: 'Detail presensi tidak tersedia',
        emptyMessage:
            'Data pertemuan ini belum bisa ditampilkan. Coba muat ulang.',
        emptyIcon: CupertinoIcons.time,
        builder: _buildContent,
      ),
    );
  }

  Widget _buildContent(PresensiDetail d) {
    final tone = _statusTone(d.keterangan);
    final (bg, fg) = AppPill.toneColors(tone);
    final sudahValidasi = d.validasi != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status pertemuan — dibaca lebih dulu sebelum detail lainnya.
        AppSurface(
          variant: AppSurfaceVariant.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('STATUS KEHADIRAN', style: AppText.overline),
                  ),
                  AppPill(
                    sudahValidasi ? 'Tervalidasi' : 'Belum divalidasi',
                    tone: sudahValidasi
                        ? AppPillTone.success
                        : AppPillTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      d.keterangan.toUpperCase(),
                      style: AppText.h3.copyWith(
                        color: fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusLabel(d.keterangan), style: AppText.h2),
                        const SizedBox(height: 2),
                        Text('${d.tanggal} · ${d.jam}', style: AppText.bodySm),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSection(
          title: 'Informasi pertemuan',
          child: AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppKeyValue(label: 'Dosen', value: d.nama),
                AppKeyValue(label: 'NIK', value: d.nik),
                AppKeyValue(label: 'Tanggal', value: d.tanggal),
                AppKeyValue(
                  label: 'Materi',
                  value: d.judulMateri,
                  emphasize: true,
                ),
                AppKeyValue(label: 'Jam', value: d.jam),
                AppKeyValue(label: 'Status', value: _statusLabel(d.keterangan)),
                if (d.validasi != null)
                  AppKeyValue(
                    label: 'Validasi',
                    value: d.validasi!,
                    emphasize: true,
                  ),
              ],
            ),
          ),
        ),
        if (!sudahValidasi)
          AppSection(
            title: 'Form validasi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormDropdown(
                        'Kesesuaian Perkuliahan',
                        _kesesuaianPerkuliahan,
                        ['1 (Sesuai)'],
                        ['1'],
                      ),
                      _buildFormDropdown(
                        'Kesesuaian Materi',
                        _kesesuaianMateri,
                        ['1 (Ya)', '2 (Tidak)'],
                        ['1', '2'],
                      ),
                      _buildFormDropdown(
                        'Penilaian Mahasiswa',
                        _penilaianMhs,
                        [
                          '4 (Sangat Baik)',
                          '3 (Baik)',
                          '2 (Cukup)',
                          '1 (Kurang)',
                        ],
                        ['4', '3', '2', '1'],
                      ),
                      for (final (asdosIndex, k, asdosLabel) in _formPairs(
                        d,
                      )) ...[
                        if (asdosLabel != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Asdos $asdosLabel',
                            style: AppText.label.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _buildKriteriaDropdown(asdosIndex, k),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text('Kritik & Saran (opsional)', style: AppText.label),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _kritikSaran,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Tulis masukan untuk dosen atau kelas…',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submitValidasi,
                  icon: const Icon(CupertinoIcons.check_mark_circled_solid),
                  label: Text(
                    _submitting ? 'Memvalidasi…' : 'Validasi Presensi',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFormDropdown(
    String label,
    TextEditingController controller,
    List<String> labels,
    List<String> values,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: AppDeco.card(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: ValueKey('${label}_${controller.text}'),
                value: controller.text,
                isExpanded: true,
                icon: const Icon(
                  CupertinoIcons.chevron_down,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                items: List.generate(
                  labels.length,
                  (i) => DropdownMenuItem(
                    value: values[i],
                    child: Text(labels[i], style: AppText.body),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => controller.text = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKriteriaDropdown(int asdosIndex, Kriteria k) {
    final key = _penilaianKey(asdosIndex, k);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k.isi, style: AppText.label.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          decoration: AppDeco.card(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey('krit_${key}_${_asdosPenilaian[key]}'),
              value: _asdosPenilaian[key],
              isExpanded: true,
              icon: const Icon(
                CupertinoIcons.chevron_down,
                color: AppColors.textMuted,
                size: 16,
              ),
              items: k.nilai
                  .map(
                    (n) => DropdownMenuItem(
                      value: n.id,
                      child: Text('${n.isi} (${n.nilai})', style: AppText.body),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _asdosPenilaian[key] = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'H':
        return 'Hadir';
      case 'B':
        return 'Bolos';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      default:
        return s;
    }
  }
}

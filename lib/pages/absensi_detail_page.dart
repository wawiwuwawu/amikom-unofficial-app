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
  const AbsensiDetailPage({super.key, required this.idPresensi});

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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getPresensiDetail(widget.idPresensi);
      if (!mounted) return;
      setState(() {
        _detail = data;
        _error = null;
        for (final k in data.kriterias) {
          final best = k.nilai.isNotEmpty
              ? k.nilai.reduce((a, b) => a.nilai >= b.nilai ? a : b)
              : null;
          if (best != null) _asdosPenilaian[k.id] = best.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitValidasi() async {
    if (_detail == null) return;
    setState(() => _submitting = true);
    try {
      await _service.validasi({
        'jenispilih': _detail!.keterangan == 'H' ? 'teori' : _detail!.keterangan,
        'idpresensimhstexs': _detail!.idPresensiMhs,
        'idpresensidosen': _detail!.idPresensiDosen,
        'kuliahteori': _detail!.kuliahTpId,
        'kesesuaian_perkuliahan': _kesesuaianPerkuliahan.text,
        'kesesuaian_materi': _kesesuaianMateri.text,
        'penilaianmhs': _penilaianMhs.text,
        'kritiksaran': _kritikSaran.text,
        'asdos_npms': [],
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
        final message = e.toString().replaceFirst('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty ? message : 'Gagal melakukan validasi presensi',
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

  static (Color, Color) _toneColors(AppPillTone tone) {
    switch (tone) {
      case AppPillTone.success:
        return (AppColors.successBg, AppColors.success);
      case AppPillTone.warning:
        return (AppColors.warningBg, AppColors.warning);
      case AppPillTone.danger:
        return (AppColors.dangerBg, AppColors.danger);
      case AppPillTone.info:
        return (AppColors.infoBg, AppColors.info);
      case AppPillTone.neutral:
        return (AppColors.surfaceMuted, AppColors.textSecondary);
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
        emptyMessage: 'Data pertemuan ini belum bisa ditampilkan. Coba muat ulang.',
        emptyIcon: CupertinoIcons.time,
        builder: _buildContent,
      ),
    );
  }

  Widget _buildContent(PresensiDetail d) {
    final tone = _statusTone(d.keterangan);
    final (bg, fg) = _toneColors(tone);
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
                    tone: sudahValidasi ? AppPillTone.success : AppPillTone.warning,
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
                AppKeyValue(label: 'Materi', value: d.judulMateri, emphasize: true),
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
                        ['4 (Sangat Baik)', '3 (Baik)', '2 (Cukup)', '1 (Kurang)'],
                        ['4', '3', '2', '1'],
                      ),
                      for (final k in d.kriterias) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildKriteriaDropdown(k),
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
                  label: Text(_submitting ? 'Memvalidasi…' : 'Validasi Presensi'),
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
          Text(
            label,
            style: AppText.label.copyWith(color: AppColors.primary),
          ),
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

  Widget _buildKriteriaDropdown(Kriteria k) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k.isi,
          style: AppText.label.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          decoration: AppDeco.card(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey('krit_${k.id}_${_asdosPenilaian[k.id]}'),
              value: _asdosPenilaian[k.id],
              isExpanded: true,
              icon: const Icon(
                CupertinoIcons.chevron_down,
                color: AppColors.textMuted,
                size: 16,
              ),
              items: k.nilai
                  .map((n) => DropdownMenuItem(
                        value: n.id,
                        child: Text('${n.isi} (${n.nilai})', style: AppText.body),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _asdosPenilaian[k.id] = v);
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

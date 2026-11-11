import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/biodata.dart';
import '../services/api_client.dart';
import '../services/biodata_service.dart';
import '../services/wifi_kampus_service.dart';
import '../theme/app_theme.dart';
import '../utils/waktu.dart';
import '../widgets/app_kit.dart';

/// Halaman Profil mahasiswa (`GET /api/v1/biodata`) + pengaturan WiFi kampus.
///
/// Kontrak tampil (keputusan user): NULL/kosong → "-", jenis kelamin & agama
/// memakai label, PII tidak pernah di-cache/log (hanya di memori). Seksi WiFi
/// memuat toggle auto-login, override kredensial manual, dan trigger login
/// manual.
class ProfilPage extends StatefulWidget {
  /// Seam test: gateway/service palsu. Default = singleton produksi.
  /// Parameter ini TIDAK dipakai UI — hanya test widget.
  final WifiKampusService? wifiKampus;

  const ProfilPage({super.key, this.wifiKampus});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _service = BiodataService();

  WifiKampusService get _wifi => widget.wifiKampus ?? WifiKampusService.instance;

  Biodata? _data;
  bool _loading = true;
  String? _error;

  // Seksi WiFi.
  bool _autoLogin = true;
  bool? _overrideAktif;
  bool _wifiSedangCoba = false;
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _load();
    _muatWifiState();
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getBiodata();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = userErrorMessage(e, 'Gagal memuat biodata. Silakan coba lagi.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _muatWifiState() async {
    final autoLogin = await _wifi.autoLoginAktif();
    final override = await _wifi.overrideAktif();
    if (!mounted) return;
    setState(() {
      _autoLogin = autoLogin;
      _overrideAktif = override;
    });
  }

  String _tampil(String? v) => (v == null || v.isEmpty) ? '-' : v;

  String _tampilTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final t = tanggalDariPortal(iso);
    return t == null ? '-' : formatTanggalIndo(t);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profil',
      body: AppAsyncView<Biodata>(
        loading: _loading,
        error: _error,
        data: _data,
        onRetry: _load,
        emptyTitle: 'Biodata tidak tersedia',
        emptyMessage: 'Biodata portal belum terisi — lengkapi di portal mahasiswa.',
        emptyIcon: CupertinoIcons.person_crop_circle,
        builder: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(data),
            _seksiDataDiri(data),
            _seksiAlamat(data),
            _seksiPendidikan(data),
            _seksiOrangTua(data),
            _seksiWifi(data),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header(Biodata data) {
    return AppSurface(
      child: Row(
        children: [
          _avatar(data.fotoUrl),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tampil(data.dataDiri.nama),
                  style: AppText.h3,
                ),
                const SizedBox(height: 2),
                Text(
                  ApiClient.instance.nim ?? '-',
                  style:
                      AppText.bodySm.copyWith(color: AppColors.textSecondary),
                ),              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String fotoUrl) {
    final url = fotoUrl.trim();
    if (url.isEmpty) {
      return _avatarFallback();
    }
    return ClipOval(
      child: SizedBox(
        width: 64,
        height: 64,
        child: Image.network(
          url,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          // Fail-open: foto gagal dimuat → ikon orang (jangan merusak halaman).
          errorBuilder: (_, _, _) => _avatarFallback(),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.surfaceMuted,
      child: const Icon(
        CupertinoIcons.person_fill,
        size: 30,
        color: AppColors.textMuted,
      ),
    );
  }

  // ── Seksi biodata ─────────────────────────────────────────────────────────

  Widget _seksiDataDiri(Biodata data) {
    final d = data.dataDiri;
    return AppSection(
      title: 'Data Diri',
      child: AppSurface(
        child: AppListGroup(
          children: [
            AppKeyValue(label: 'Nama', value: _tampil(d.nama), emphasize: true),
            AppKeyValue(label: 'NIK', value: _tampil(d.nikktp)),
            AppKeyValue(label: 'Tempat Lahir', value: _tampil(d.tempatLahir)),
            AppKeyValue(label: 'Tanggal Lahir', value: _tampilTanggal(d.tanggalLahir)),
            AppKeyValue(label: 'Jenis Kelamin', value: _tampil(d.jenisKelamin.label)),
            AppKeyValue(label: 'Agama', value: _tampil(d.agama.label)),
            AppKeyValue(
                label: 'Status Perkawinan', value: _tampil(d.statusPerkawinan)),
            AppKeyValue(label: 'Jumlah Anak', value: _tampil(d.jumlahAnak)),
            AppKeyValue(label: 'Email', value: _tampil(d.email)),
            AppKeyValue(label: 'No. HP', value: _tampil(d.noHp)),
            AppKeyValue(label: 'NISN', value: _tampil(d.nisn)),
          ],
        ),
      ),
    );
  }

  Widget _seksiAlamat(Biodata data) {
    final a = data.alamat;
    return AppSection(
      title: 'Alamat',
      child: AppSurface(
        child: AppListGroup(
          children: [
            AppKeyValue(label: 'Alamat', value: _tampil(a.alamat)),
            AppKeyValue(label: 'RT/RW', value: _rtRw(a.rt, a.rw)),
            AppKeyValue(label: 'Kecamatan', value: _tampil(a.kecamatan)),
            AppKeyValue(label: 'Kabupaten', value: _tampil(a.kabupaten)),
            AppKeyValue(label: 'Provinsi', value: _tampil(a.propinsi)),
            AppKeyValue(label: 'Kode Pos', value: _tampil(a.kodePos)),
          ],
        ),
      ),
    );
  }

  String _rtRw(String rt, String rw) {
    if (rt.isEmpty && rw.isEmpty) return '-';
    return 'RT ${rt.isEmpty ? '-' : rt} / RW ${rw.isEmpty ? '-' : rw}';
  }

  Widget _seksiPendidikan(Biodata data) {
    final p = data.pendidikan;
    return AppSection(
      title: 'Pendidikan',
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sekolahBaris('SD', p.sd),
            _sekolahBaris('SMP', p.smp),
            _sekolahBaris('SMA', p.sma),
          ],
        ),
      ),
    );
  }

  Widget _sekolahBaris(String jenjang, BiodataSekolah s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(jenjang, style: AppText.bodySm),
          ),
          Expanded(
            child: Text(
              _tampil(s.nama),
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            _tampil(s.tahunLulus),
            style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _seksiOrangTua(Biodata data) {
    final o = data.orangTua;
    return AppSection(
      title: 'Orang Tua',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSurface(
            child: AppListGroup(
              children: [
                AppKeyValue(
                    label: 'Nama', value: _tampil(o.ayah.nama), emphasize: true),
                AppKeyValue(label: 'Pendidikan', value: _tampil(o.ayah.pendidikan)),
                AppKeyValue(label: 'Pekerjaan', value: _tampil(o.ayah.pekerjaan)),
                AppKeyValue(label: 'Status', value: _tampil(o.ayah.status)),
                AppKeyValue(label: 'No. HP', value: _tampil(o.ayah.noHp)),
                AppKeyValue(label: 'Instansi', value: _tampil(o.ayah.instansi)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            child: AppListGroup(
              children: [
                AppKeyValue(
                    label: 'Nama', value: _tampil(o.ibu.nama), emphasize: true),
                AppKeyValue(label: 'Pendidikan', value: _tampil(o.ibu.pendidikan)),
                AppKeyValue(label: 'Pekerjaan', value: _tampil(o.ibu.pekerjaan)),
                AppKeyValue(label: 'Status', value: _tampil(o.ibu.status)),
                AppKeyValue(label: 'No. HP', value: _tampil(o.ibu.noHp)),
                AppKeyValue(label: 'Instansi', value: _tampil(o.ibu.instansi)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Seksi WiFi kampus ─────────────────────────────────────────────────────

  Widget _seksiWifi(Biodata data) {
    return AppSection(
      title: 'WiFi Kampus',
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material transparan: ListTile/SwitchListTile menggambar
            // background di Material ancestor terdekat — AppSurface pakai
            // DecoratedBox, jadi butuh pembungkus ini (assertion framework).
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoLogin,
                onChanged: _ubahAutoLogin,
                activeThumbColor: AppColors.primary,
                title: Text('Auto-login WiFi kampus', style: AppText.body),
                subtitle: Text(
                  _autoLogin
                      ? 'Login otomatis saat tersambung ke Hotspot@Amikom'
                      : 'Login hanya lewat tombol "Coba login sekarang"',
                  style:
                      AppText.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _penjelasanSumberKredensial(),
              style: AppText.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Form di bawah opsional — kosongkan jika memakai kredensial '
              'dari server. Isi hanya saat kredensial otomatis ditolak portal.',
              style: AppText.bodySm.copyWith(color: AppColors.textMuted),
            ),
            TextField(
              controller: _usernameC,
              decoration: const InputDecoration(
                labelText: 'Username (opsional)',
                hintText: 'NIM / username portal WiFi',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _passwordC,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password (opsional)',
                hintText: 'Tanggal lahir (yyyymmdd)',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _simpanOverride,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Simpan manual'),
                ),
                if (_overrideAktif == true)
                  OutlinedButton.icon(
                    onPressed: _pulihkanServer,
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('Gunakan kredensial server lagi'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _wifiSedangCoba ? null : _cobaLoginSekarang,
              icon: _wifiSedangCoba
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi, size: 18),
              label: const Text('Coba login sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ubahAutoLogin(bool v) async {
    setState(() => _autoLogin = v);
    await _wifi.setAutoLogin(v);
  }

  /// Penjelasan sumber kredensial di seksi WiFi — bila BE pernah melaporkan
  /// biodata portal kosong (kontrak `code: biodata_tanggal_lahir_kosong`),
  /// sebutkan penyebabnya agar user tahu harus ke portal, bukan menebak.
  String _penjelasanSumberKredensial() {
    if (_overrideAktif == true) return 'Memakai kredensial manual (override).';
    if (_wifi.biodataKosong) {
      return 'Kredensial server belum bisa dibentuk — biodata portal (tanggal '
          'lahir) belum terisi. Isi biodata di portal mahasiswa, atau pakai '
          'kredensial manual di bawah.';
    }
    return 'Kredensial diambil otomatis dari server (NIM + tanggal lahir).';
  }

  Future<void> _simpanOverride() async {
    final username = _usernameC.text.trim();
    final password = _passwordC.text.trim();
    if (username.isEmpty || password.isEmpty) {
      AppSnack.show(
        context,
        'Username dan password harus diisi.',
        backgroundColor: AppColors.warning,
      );
      return;
    }
    await _wifi.simpanOverride(username, password);
    if (!mounted) return;
    setState(() => _overrideAktif = true);
    AppSnack.show(
      context,
      'Kredensial manual tersimpan.',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _pulihkanServer() async {
    await _wifi.hapusOverride();
    if (!mounted) return;
    setState(() => _overrideAktif = false);
    AppSnack.show(
      context,
      'Kembali memakai kredensial dari server.',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _cobaLoginSekarang() async {
    setState(() => _wifiSedangCoba = true);
    try {
      final hasil = await _wifi.cobaLoginManual();
      if (!mounted) return;
      switch (hasil) {
        case HasilPortal.berhasil:
          AppSnack.show(context, 'WiFi kampus terhubung.',
              backgroundColor: AppColors.success);
        case HasilPortal.kredensialSalah:
          AppSnack.show(
            context,
            'Kredensial ditolak portal — periksa pengaturan manual di bawah.',
            backgroundColor: AppColors.warning,
          );
        default:
          AppSnack.show(
            context,
            'Belum berhasil terhubung ke portal WiFi.',
            backgroundColor: AppColors.textSecondary,
          );
      }
    } finally {
      if (mounted) setState(() => _wifiSedangCoba = false);
    }
  }
}

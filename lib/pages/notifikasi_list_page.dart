import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/notifikasi.dart';
import '../services/notifikasi_service.dart';
import '../services/api_client.dart';
import '../services/pembaruan_service.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/notifikasi_push_card.dart';
import '../widgets/pembaruan_sheet.dart';
import 'notifikasi_detail_page.dart';

class NotifikasiListPage extends StatefulWidget {
  const NotifikasiListPage({super.key});

  @override
  State<NotifikasiListPage> createState() => _NotifikasiListPageState();
}

class _NotifikasiListPageState extends State<NotifikasiListPage>
    with WidgetsBindingObserver {
  final _service = NotifikasiService();
  List<NotifikasiItem> _list = [];
  Set<String> _readIds = {};
  bool _loading = true;
  String? _error;

  NotifikasiOptinStatus? _optinStatus;
  bool _optinLoading = true;
  bool _optinTidakTersedia = false;
  String? _optinError;

  /// Info pembaruan dari cek otomatis harian; null = tidak ada update atau
  /// sudah dilewati user.
  InfoPembaruan? _infoPembaruan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    unawaited(_muatBannerPembaruan());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Status push bisa berubah di server saat app di background (mis. BE
    // memperbaiki FCM, atau user mengizinkan notifikasi di Pengaturan
    // sistem) — muat ulang saat app dibuka kembali.
    if (state == AppLifecycleState.resumed) {
      unawaited(_pulihkanPushSaatResume());
    }
  }

  /// Memuat ulang status push saat resume; bila server masih Nonaktif, coba
  /// aktivasi lagi (guard sesi dilewati dengan paksa) lalu muat ulang sekali
  /// lagi supaya kartu langsung berubah menjadi Aktif begitu registrasi
  /// berhasil. Tanpa panggilan balik setelah aktivasi, kartu bisa tetap
  /// menampilkan snapshot lama seumur hidup halaman.
  Future<void> _pulihkanPushSaatResume() async {
    await _loadOptinStatus();
    final status = _optinStatus;
    if (status == null || status.enabled || _optinTidakTersedia) return;
    await PushService.instance.aktifkanJikaBelumPernah(paksa: true);
    await _loadOptinStatus();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _optinLoading = true;
      _optinError = null;
    });

    await Future.wait<void>([_loadNotifikasiList(), _loadOptinStatus()]);
  }

  Future<void> _loadNotifikasiList() async {
    try {
      final data = await _service.getNotifikasi();
      final readSet = await _service.getReadIds();
      if (mounted) {
        setState(() {
          _list = data;
          _readIds = readSet;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadOptinStatus() async {
    if (mounted) {
      setState(() {
        _optinLoading = true;
        _optinError = null;
      });
    }
    try {
      final status = await _service.getOptinStatus();
      if (!mounted) return;
      setState(() {
        _optinStatus = status;
        _optinTidakTersedia = false;
        _optinLoading = false;
      });
      // Aktivasi berjalan otomatis (izin diminta app sendiri), jadi panduan
      // cukup tampil SEKALI saat status sudah Aktif — bukan tombol in-app.
      await _tampilkanSheetBilaPerlu(status);
    } catch (e) {
      if (!mounted) return;
      final msg = userErrorMessage(e, 'Gagal memuat status notifikasi push');
      final dimatikanServer = msg.contains('dinonaktifkan oleh server');
      setState(() {
        _optinTidakTersedia = dimatikanServer;
        _optinError = dimatikanServer ? null : msg;
        _optinLoading = false;
      });
    }
  }

  /// Menampilkan panduan sistem (izin notifikasi + pengecualian optimasi
  /// baterai) sekali saja, tepat setelah push otomatis terdaftar aktif.
  /// Status "sudah pernah ditampilkan" disimpan oleh [PushService].
  Future<void> _tampilkanSheetBilaPerlu(NotifikasiOptinStatus status) async {
    if (!status.enabled) return;
    var sudahDitampilkan = true;
    try {
      sudahDitampilkan = await PushService.sheetSudahDitampilkan();
      if (sudahDitampilkan) return;
      await PushService.tandaiSheetDitampilkan();
    } catch (e) {
      debugPrint('Push: status sheet panduan gagal dibaca (${e.runtimeType})');
      return;
    }
    if (!mounted) return;
    await showNotifikasiPushSheet(context);
  }

  /// Tombol "Muat Ulang" pada kartu Nonaktif karena server bermasalah: /// muat ulang status DAN coba aktivasi ulang (server mungkin sudah
  /// diperbaiki). Aktivasi dipaksa melewati guard sesi supaya percobaan
  /// ulang benar-benar terjadi, bukan sekadar baca status lama.
  Future<void> _muatUlangPush() async {
    setState(() => _optinLoading = true);
    try {
      await PushService.instance.aktifkanJikaBelumPernah(paksa: true);
    } finally {
      await _loadOptinStatus();
    }
  }

  // ── Banner pembaruan (APK dari GitHub Releases) ─────────────────────────

  /// Baca hasil cek otomatis harian dari PembaruanService (fail-open, tidak
  /// pernah melempar) dan tampilkan banner bila update tersedia dan belum
  /// dilewati user.
  Future<void> _muatBannerPembaruan() async {
    final info = await PembaruanService.instance.cekOtomatis();
    if (info == null || !mounted) return;
    final dilewati = await PembaruanService.instance.dilewati(info);
    if (!mounted || dilewati) return;
    setState(() => _infoPembaruan = info);
  }

  Future<void> _bukaSheetPembaruan() async {
    final info = _infoPembaruan;
    if (info == null) return;
    final hasil = await showPembaruanSheet(context, info);
    if (hasil == 'lewati' && mounted) {
      setState(() => _infoPembaruan = null);
    }
  }

  /// Banner satu baris ala banner periode ujian di jadwal; hilang sendiri
  /// setelah versi terpasang atau user memilih lewati versi ini.
  Widget _buildBannerPembaruan() {
    final info = _infoPembaruan;
    if (info == null) return const SizedBox.shrink();
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      onTap: _bukaSheetPembaruan,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.arrow_down_circle_fill,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Pembaruan v${info.versi} tersedia — ketuk untuk memperbarui',
              style: AppText.bodySm,
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 14,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildPushCard() {
    return NotifikasiPushCard(
      status: _optinStatus,
      loading: _optinLoading,
      perangkatGagal:
          _optinStatus != null &&
          !_optinStatus!.enabled &&
          PushService.tokenGagalDiPerangkat,
      serverGagal:
          _optinStatus != null &&
          !_optinStatus!.enabled &&
          PushService.serverGagalTerakhir,
      onMuatUlang: _muatUlangPush,
      tidakTersedia: _optinTidakTersedia,
      pesanGagal: _optinError,
    );
  }

  Future<void> _retryWithSilentLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await ApiClient.instance.ensureSessionOrSilentLogin();
    await _loadData();
  }

  Future<void> _markAllAsRead() async {
    final allIds = _list.map((e) => e.id).toList();
    await _service.markAllAsRead(allIds);
    final readSet = await _service.getReadIds();
    setState(() {
      _readIds = readSet;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai telah dibaca'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _onTapItem(NotifikasiItem item) async {
    await _service.markAsRead(item.id);
    final readSet = await _service.getReadIds();
    setState(() {
      _readIds = readSet;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotifikasiDetailPage(id: item.id)),
    );
  }

  bool get _hasUnread => _list.any((item) => !_readIds.contains(item.id));

  int get _unreadCount =>
      _list.where((item) => !_readIds.contains(item.id)).length;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifikasi & Pengumuman',
      subtitle: 'Kabar terbaru dari kampus',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        if (_list.isNotEmpty && _hasUnread)
          TextButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(CupertinoIcons.checkmark_seal_fill, size: 16),
            label: const Text('Tandai Dibaca'),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoading(message: 'Memuat notifikasi…');
    }

    if (_error != null) {
      return ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildPushCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildBannerPembaruan(),
          const SizedBox(height: AppSpacing.lg),
          AppErrorState(message: _error!, onRetry: _retryWithSilentLogin),
        ],
      );
    }

    if (_list.isEmpty) {
      return ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildPushCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildBannerPembaruan(),
          const SizedBox(height: AppSpacing.xxl),
          const AppEmptyState(
            title: 'Tidak ada notifikasi saat ini',
            message: 'Notifikasi dan pengumuman baru akan tampil di sini.',
            icon: CupertinoIcons.bell_slash,
          ),
        ],
      );
    }

    return ListView(
      padding: AppSpacing.page,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildPushCard(),
        const SizedBox(height: AppSpacing.lg),
        _buildBannerPembaruan(),
        AppSection(
          title: 'Daftar Notifikasi',
          topGap: AppSpacing.lg,
          trailing: _hasUnread
              ? AppPill('$_unreadCount belum dibaca', tone: AppPillTone.info)
              : null,
          child: AppListGroup.from([for (final item in _list) _buildRow(item)]),
        ),
      ],
    );
  }

  /// Satu baris notifikasi. Item yang belum dibaca diberi latar lembut,
  /// ikon lonceng terisi, dan lencana "Baru" agar langsung tertangkap mata.
  Widget _buildRow(NotifikasiItem item) {
    final isRead = _readIds.contains(item.id);

    return Container(
      color: isRead ? null : AppColors.primary.withValues(alpha: 0.05),
      child: AppListRow(
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: isRead
              ? BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                )
              : AppDeco.softPrimary(radius: AppRadius.sm),
          child: Icon(
            isRead ? CupertinoIcons.bell : CupertinoIcons.bell_fill,
            size: 18,
            color: isRead ? AppColors.textMuted : AppColors.primary,
          ),
        ),
        title: item.judul,
        subtitle: item.tanggal,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRead) ...[
              const AppPill('Baru', tone: AppPillTone.info),
              const SizedBox(width: AppSpacing.sm),
            ],
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
        onTap: () => _onTapItem(item),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/notifikasi.dart';
import '../services/notifikasi_service.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';
import '../services/push_token_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/notifikasi_push_card.dart';
import 'notifikasi_detail_page.dart';

class NotifikasiListPage extends StatefulWidget {
  /// Sumber token FCM untuk perangkat ini.
  final PushTokenProvider pushTokenProvider;

  const NotifikasiListPage({
    super.key,
    this.pushTokenProvider = const FirebasePushTokenProvider(),
  });

  @override
  State<NotifikasiListPage> createState() => _NotifikasiListPageState();
}

class _NotifikasiListPageState extends State<NotifikasiListPage> {
  final _service = NotifikasiService();
  List<NotifikasiItem> _list = [];
  Set<String> _readIds = {};
  bool _loading = true;
  String? _error;

  NotifikasiOptinStatus? _optinStatus;
  bool _optinLoading = true;
  bool _optinBusy = false;
  bool _optinTidakTersedia = false;
  String? _optinError;
  int _retryCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startRetryCountdown(int seconds) {
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() => _retryCountdown = seconds);
    } else {
      _retryCountdown = seconds;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_retryCountdown <= 1) {
        timer.cancel();
        setState(() => _retryCountdown = 0);
      } else {
        setState(() => _retryCountdown--);
      }
    });
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
      if (mounted) {
        // Status segar membatalkan hitung mundur 429 sebelumnya, supaya tombol
        // tidak tetap terkunci padahal permintaan sudah boleh lagi.
        _countdownTimer?.cancel();
        _countdownTimer = null;
        setState(() {
          _optinStatus = status;
          _optinTidakTersedia = false;
          _optinLoading = false;
          _retryCountdown = 0;
        });
      }
    } on NotifikasiRateLimited catch (e) {
      if (!mounted) return;
      _startRetryCountdown(e.retryAfterSeconds);
      setState(() {
        _optinError = userErrorMessage(e);
        _optinLoading = false;
      });
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

  Future<void> _aktifkanPush() async {
    if (_optinBusy || _retryCountdown > 0) return;
    setState(() => _optinBusy = true);

    try {
      final diizinkan = await PushService.instance.mintaIzin();
      if (!diizinkan) {
        if (!mounted) return;
        const pesan =
            'Izin notifikasi ditolak. Aktifkan notifikasi untuk aplikasi ini '
            'di Pengaturan > Notifikasi > Ini Amikom?.';
        setState(() => _optinError = pesan);
        AppSnack.show(context, pesan, backgroundColor: AppColors.warning);
        return;
      }

      final token = await widget.pushTokenProvider.ambilToken();
      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;
        AppSnack.show(
          context,
          'Token notifikasi perangkat ini belum tersedia. Coba lagi sebentar lagi.',
          backgroundColor: AppColors.warning,
        );
        return;
      }

      final status = await _service.daftarkanToken(token.trim());
      if (!mounted) return;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      setState(() {
        _optinStatus = status;
        _optinTidakTersedia = false;
        _optinError = null;
        _retryCountdown = 0;
      });
      await showNotifikasiPushSheet(context);
    } on NotifikasiRateLimited catch (e) {
      if (!mounted) return;
      _startRetryCountdown(e.retryAfterSeconds);
      AppSnack.show(
        context,
        userErrorMessage(e),
        backgroundColor: AppColors.warning,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = userErrorMessage(e, 'Gagal mengaktifkan notifikasi push');
      if (msg.contains('dinonaktifkan oleh server')) {
        setState(() {
          _optinTidakTersedia = true;
          _optinError = null;
        });
        AppSnack.show(context, msg, backgroundColor: AppColors.warning);
      } else {
        AppSnack.show(context, msg, backgroundColor: AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _optinBusy = false);
    }
  }

  Future<void> _matikanPush() async {
    if (_optinBusy || _retryCountdown > 0) return;
    setState(() => _optinBusy = true);

    try {
      // Tanpa token lokal: body kosong = hapus SEMUA token milik NIM ini.
      await _service.hapusToken('');
      if (!mounted) return;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      setState(() {
        _optinStatus = const NotifikasiOptinStatus(enabled: false);
        _optinError = null;
        _retryCountdown = 0;
      });
      AppSnack.show(
        context,
        'Notifikasi push dimatikan.',
        backgroundColor: AppColors.primary,
      );
    } on NotifikasiRateLimited catch (e) {
      if (!mounted) return;
      _startRetryCountdown(e.retryAfterSeconds);
      AppSnack.show(
        context,
        userErrorMessage(e),
        backgroundColor: AppColors.warning,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        userErrorMessage(e, 'Gagal menonaktifkan notifikasi push'),
        backgroundColor: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _optinBusy = false);
    }
  }

  Widget _buildPushCard() {
    return NotifikasiPushCard(
      status: _optinStatus,
      loading: _optinLoading,
      busy: _optinBusy,
      tidakTersedia: _optinTidakTersedia,
      pesanGagal: _optinError,
      retryAfterSeconds: _retryCountdown,
      onAktifkan: _aktifkanPush,
      onMatikan: _matikanPush,
      onMuatUlang: _loadOptinStatus,
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

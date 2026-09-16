import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/notifikasi.dart';
import '../services/notifikasi_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import 'notifikasi_detail_page.dart';

class NotifikasiListPage extends StatefulWidget {
  final VoidCallback? onBack;

  const NotifikasiListPage({super.key, this.onBack});

  @override
  State<NotifikasiListPage> createState() => _NotifikasiListPageState();
}

class _NotifikasiListPageState extends State<NotifikasiListPage> {
  final _service = NotifikasiService();
  List<NotifikasiItem> _list = [];
  Set<String> _readIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
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
        children: [
          AppErrorState(message: _error!, onRetry: _retryWithSilentLogin),
        ],
      );
    }

    if (_list.isEmpty) {
      return ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: AppSpacing.xxl),
          AppEmptyState(
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
        AppSection(
          title: 'Daftar Notifikasi',
          topGap: 0,
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

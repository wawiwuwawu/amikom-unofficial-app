import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/pengumuman.dart';
import '../services/pengumuman_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import 'pengumuman_detail_page.dart';

/// Daftar Pengumuman Akademik.
///
/// Pengumuman tidak punya gambar dan isinya berupa judul + tanggal, jadi
/// disajikan sebagai DAFTAR (bukan kartu per item) — lebih ringkas dan lebih
/// cepat dipindai mata dibanding satu kartu besar per pengumuman.
class PengumumanListPage extends StatefulWidget {
  const PengumumanListPage({super.key});

  @override
  State<PengumumanListPage> createState() => _PengumumanListPageState();
}

class _PengumumanListPageState extends State<PengumumanListPage> {
  final _service = PengumumanService();
  List<PengumumanItem> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getList();
      if (!mounted) return;
      setState(() {
        _list = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pengumuman Akademik',
      subtitle: 'Informasi resmi dari bagian akademik',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: AppAsyncView<List<PengumumanItem>>(
          loading: _loading,
          error: _error,
          data: _list,
          onRetry: _load,
          loadingMessage: 'Memuat pengumuman…',
          emptyTitle: 'Belum ada pengumuman',
          emptyMessage: 'Pengumuman baru akan muncul di sini.',
          emptyIcon: CupertinoIcons.speaker_2_fill,
          isEmpty: (data) => data.isEmpty,
          builder: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                '${data.length} PENGUMUMAN',
                style: AppText.overline,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppListGroup.from([
                for (final item in data) _row(item),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(PengumumanItem item) {
    return AppListRow(
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: const Icon(
          CupertinoIcons.speaker_2_fill,
          size: 19,
          color: AppColors.primary,
        ),
      ),
      title: item.judul,
      subtitle: item.tanggal.isEmpty ? null : item.tanggal,
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 17,
        color: AppColors.textMuted,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PengumumanDetailPage(id: item.id),
        ),
      ),
    );
  }
}

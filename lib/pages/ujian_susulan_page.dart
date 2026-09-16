import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/ujian_susulan.dart';
import '../services/ujian_susulan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class UjianSusulanPage extends StatefulWidget {
  final VoidCallback? onBack;

  const UjianSusulanPage({super.key, this.onBack});

  @override
  State<UjianSusulanPage> createState() => _UjianSusulanPageState();
}

class _UjianSusulanPageState extends State<UjianSusulanPage> {
  final UjianSusulanService _service = UjianSusulanService();

  bool _isLoadingUts = true;
  String _errorUts = '';
  UjianSusulanData? _utsData;

  bool _isLoadingUas = true;
  String _errorUas = '';
  UjianSusulanData? _uasData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchUts(),
      _fetchUas(),
    ]);
  }

  Future<void> _fetchUts() async {
    setState(() {
      _isLoadingUts = true;
      _errorUts = '';
    });
    try {
      final res = await _service.getUtsData();
      if (mounted) {
        setState(() {
          _utsData = res;
          _isLoadingUts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorUts = e.toString().replaceFirst('Exception: ', '');
          _isLoadingUts = false;
        });
      }
    }
  }

  Future<void> _fetchUas() async {
    setState(() {
      _isLoadingUas = true;
      _errorUas = '';
    });
    try {
      final res = await _service.getUasData();
      if (mounted) {
        setState(() {
          _uasData = res;
          _isLoadingUas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorUas = e.toString().replaceFirst('Exception: ', '');
          _isLoadingUas = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Ujian Susulan',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(CupertinoIcons.doc_text_search, size: 20),
                    text: 'UTS Susulan',
                  ),
                  Tab(
                    icon: Icon(CupertinoIcons.doc_checkmark, size: 20),
                    text: 'UAS Susulan',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabContent(isUts: true),
                  _buildTabContent(isUts: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({required bool isUts}) {
    final bool isLoading = isUts ? _isLoadingUts : _isLoadingUas;
    final String error = isUts ? _errorUts : _errorUas;
    final UjianSusulanData? data = isUts ? _utsData : _uasData;
    final Future<void> Function() onRefresh = isUts ? _fetchUts : _fetchUas;

    if (isLoading) {
      return const AppLoading(message: 'Memuat jadwal ujian susulan…');
    }

    if (error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: error, onRetry: onRefresh),
        ),
      );
    }

    if (data == null || !data.isAvailable) {
      final msg = data?.message.isNotEmpty == true
          ? data!.message
          : 'Mohon maaf, Jadwal Belum Tersedia';

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page,
          children: [
            AppEmptyState(
              title: isUts ? 'Jadwal Ujian Susulan UTS' : 'Jadwal Ujian Susulan UAS',
              message: msg,
              icon: CupertinoIcons.calendar_badge_minus,
            ),
            AppSurface(
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle_fill,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Pendaftaran dan jadwal ujian susulan ditentukan oleh Bagian Akademik Amikom. Silakan cek secara berkala.',
                      style: AppText.bodySm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // When Available == true
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        children: [
          AppSurface(
            variant: AppSurfaceVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: AppColors.success,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(data.message, style: AppText.h3),
                    ),
                  ],
                ),
                if (data.badges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final b in data.badges)
                        AppPill(b.value, tone: AppPillTone.info),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AppSection(
            title: 'Daftar Mata Kuliah',
            child: data.items.isEmpty
                ? const AppEmptyState(
                    title: 'Belum ada matakuliah ujian susulan yang terdaftar',
                    icon: CupertinoIcons.doc_text_search,
                  )
                : AppListGroup.from([
                    for (final item in data.items) _buildItem(item),
                  ]),
          ),
        ],
      ),
    );
  }

  /// Satu baris mata kuliah ujian susulan: identitas MK + status pengajuan.
  Widget _buildItem(UjianSusulanItem item) {
    final subtitle = [
      item.kode,
      '${item.sks} SKS • Kelas ${item.kelas}',
      if (item.dosen.isNotEmpty) item.dosen,
    ].join(' • ');

    return AppListRow(
      title: item.mkl,
      subtitle: subtitle,
      trailing: AppPill(item.status, tone: _statusTone(item.status)),
    );
  }

  AppPillTone _statusTone(String status) {
    switch (status.toLowerCase().trim()) {
      case 'diterima':
      case 'disetujui':
        return AppPillTone.success;
      case 'ditolak':
        return AppPillTone.danger;
      case 'diproses':
        return AppPillTone.info;
      case 'diajukan':
        return AppPillTone.warning;
      default:
        return AppPillTone.neutral;
    }
  }
}

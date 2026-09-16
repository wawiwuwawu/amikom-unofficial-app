import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/pusat_studi.dart';
import '../../services/pusat_studi_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_kit.dart';
import 'pusat_studi_detail_page.dart';
import 'pusat_studi_joined_page.dart';

class PusatStudiPage extends StatefulWidget {
  const PusatStudiPage({super.key});

  @override
  State<PusatStudiPage> createState() => _PusatStudiPageState();
}

class _PusatStudiPageState extends State<PusatStudiPage> {
  final PusatStudiService _service = PusatStudiService();
  bool _isLoading = true;
  String _error = '';
  List<PusatStudi> _listSemua = [];
  List<PusatStudi> _listJoined = [];
  String _activeTab = 'semua'; // 'semua' or 'tergabung'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Set<String> _joinedIds = {};

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      // Selalu tarik data yang sudah di-join untuk state
      final joined = await _service.getJoinedPusatStudi();
      _listJoined = joined;
      _joinedIds = joined.map((e) => e.id).toSet();

      if (_activeTab == 'semua') {
        final all = await _service.getPusatStudiList();

        // Gabungkan karena endpoint 'semua' mungkin mengecualikan yang sudah di-join
        final Map<String, PusatStudi> combinedMap = {};
        for (var ps in all) {
          combinedMap[ps.id] = ps;
        }
        for (var ps in joined) {
          combinedMap[ps.id] = ps;
        }
        _listSemua = combinedMap.values.toList();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pusat Studi',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: _buildToggle(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoading();

    if (_error.isNotEmpty) {
      return Padding(
        padding: AppSpacing.page,
        child: Align(
          alignment: Alignment.topCenter,
          child: AppErrorState(message: _error, onRetry: _loadData),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _activeTab == 'semua' ? _buildListSemua() : _buildListJoined(),
    );
  }

  /// Pengalih "Semua / Tergabung" — sebelumnya kartu kaca, kini segmen ringkas.
  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: AppDeco.listGroup(),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Semua', 'semua')),
          Expanded(child: _buildTabButton('Tergabung', 'tergabung')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, String type) {
    final isSelected = _activeTab == type;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _activeTab = type;
            _loadData();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text(
            title,
            style: AppText.button.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsetsGeometry _buildBodyPadding() {
    return EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
    );
  }

  Widget _buildListSemua() {
    if (_listSemua.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          AppEmptyState(
            title: 'Tidak ada daftar pusat studi.',
            icon: CupertinoIcons.building_2_fill,
          ),
        ],
      );
    }
    return ListView(
      padding: _buildBodyPadding(),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        AppListGroup.from([
          for (final ps in _listSemua) _buildSemuaRow(ps),
        ]),
      ],
    );
  }

  /// Baris daftar (bukan kartu per item) — status tergabung jadi pil.
  Widget _buildSemuaRow(PusatStudi ps) {
    final isJoined = _joinedIds.contains(ps.id);
    return AppListRow(
      leading: Container(
        width: AppSpacing.xxl + AppSpacing.sm,
        height: AppSpacing.xxl + AppSpacing.sm,
        alignment: Alignment.center,
        decoration: isJoined
            ? BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              )
            : AppDeco.softPrimary(radius: AppRadius.sm),
        child: Icon(
          isJoined ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.building_2_fill,
          size: 20,
          color: isJoined ? AppColors.success : AppColors.primary,
        ),
      ),
      title: ps.nama,
      trailing: isJoined
          ? const AppPill('Tergabung', tone: AppPillTone.success)
          : const Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.textMuted),
      onTap: () {
        // Selalu buka Detail Page dari tab Semua, berikan parameter isJoined agar FAB di-hide
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PusatStudiDetailPage(pusatStudi: ps, isJoined: isJoined),
        )).then((joined) {
          if (joined == true) _loadData(); // Refresh jika user barusan gabung
        });
      },
    );
  }

  Widget _buildListJoined() {
    if (_listJoined.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          AppEmptyState(
            title: 'Anda belum tergabung di pusat studi manapun.',
            icon: CupertinoIcons.checkmark_seal,
          ),
        ],
      );
    }
    return ListView(
      padding: _buildBodyPadding(),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        AppListGroup.from([
          for (final ps in _listJoined)
            AppListRow(
              leading: Container(
                width: AppSpacing.xxl + AppSpacing.sm,
                height: AppSpacing.xxl + AppSpacing.sm,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
              title: ps.nama,
              subtitle: (ps.grupWa != null && ps.grupWa!.isNotEmpty)
                  ? 'Grup WA tersedia'
                  : null,
              trailing: const Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: AppColors.textMuted,
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PusatStudiJoinedPage(pusatStudi: ps),
                ));
              },
            ),
        ]),
      ],
    );
  }
}

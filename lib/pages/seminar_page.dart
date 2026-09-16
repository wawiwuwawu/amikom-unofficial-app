import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/seminar.dart';
import '../services/seminar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman Jadwal Seminar (Kerja Praktik & Skripsi).
///
/// Redesign memakai design system:
///   * kerangka halaman memakai [AppScaffold]; dua tab tetap dipertahankan dan
///     digambar oleh `tabBarTheme` global;
///   * kolom pencarian memakai [AppSearchField];
///   * tiap jadwal jadi baris [AppListRow] dalam [AppListGroup] (bukan satu
///     kartu per jadwal) — judul sebagai title, tanggal/jam sebagai subtitle,
///     jenis ujian sebagai [AppPill], detail mahasiswa & ruang lewat
///     [AppKeyValue];
///   * keadaan memuat / galat / kosong memakai [AppLoading], [AppErrorState],
///     [AppEmptyState].
/// Semua panggilan service, state, filter, dan navigasi tidak berubah.
class SeminarPage extends StatefulWidget {
  final VoidCallback? onBack;
  const SeminarPage({super.key, this.onBack});

  @override
  State<SeminarPage> createState() => _SeminarPageState();
}

class _SeminarPageState extends State<SeminarPage> with SingleTickerProviderStateMixin {
  final _service = SeminarService();
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  List<Seminar> _listKP = [];
  List<Seminar> _listSkripsi = [];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final kp = await _service.getJadwalKP();
      final skripsi = await _service.getJadwalSkripsi();

      if (mounted) {
        setState(() {
          _listKP = kp;
          _listSkripsi = skripsi;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Seminar> _getFilteredList(List<Seminar> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((s) {
      return s.judul.toLowerCase().contains(q) ||
             s.nama.toLowerCase().contains(q) ||
             s.npm.toLowerCase().contains(q) ||
             s.prodi.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Jadwal Seminar',
      subtitle: 'Jadwal ujian Kerja Praktik & Skripsi',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Cari judul, nama, atau NPM...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Kerja Praktik'),
              Tab(text: 'Skripsi'),
            ],
          ),
          Expanded(
            child: _loading
                ? const AppLoading()
                : _error != null
                    ? Padding(
                        padding: AppSpacing.page,
                        child: Center(
                          child: AppErrorState(
                            message: _error!,
                            onRetry: _loadData,
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_getFilteredList(_listKP), isSkripsi: false),
                          _buildList(_getFilteredList(_listSkripsi), isSkripsi: true),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Seminar> list, {required bool isSkripsi}) {
    if (list.isEmpty) {
      return AppEmptyState(
        title: _searchQuery.isNotEmpty
            ? 'Pencarian tidak ditemukan'
            : 'Belum ada jadwal tersedia',
        icon: CupertinoIcons.doc_text_search,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          AppListGroup(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                _buildCard(list[i], i, isSkripsi: isSkripsi),
              ],
            ],
          ).animate().fadeIn(duration: 220.ms),
        ],
      ),
    );
  }

  /// Satu blok jadwal: baris utama + detail mahasiswa/penguji.
  Widget _buildCard(Seminar s, int index, {required bool isSkripsi}) {
    final typeLabel = isSkripsi ? 'SKRIPSI' : 'KERJA PRAKTIK';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          title: s.judul,
          subtitle: '${s.hari}, ${s.tglUjian} • ${s.jam} • ${s.ruang}',
          trailing: AppPill(
            typeLabel,
            tone: isSkripsi ? AppPillTone.warning : AppPillTone.info,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppKeyValue(label: 'Mahasiswa', value: '${s.nama} • ${s.npm}'),
              AppKeyValue(label: 'Prodi', value: s.prodi),
              AppKeyValue(label: 'ID Pengajuan', value: s.idPengajuan),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/panduan.dart';
import '../services/panduan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class PanduanListPage extends StatefulWidget {
  const PanduanListPage({super.key});

  @override
  State<PanduanListPage> createState() => _PanduanListPageState();
}

class _PanduanListPageState extends State<PanduanListPage> {
  final _service = PanduanService();
  final _searchController = TextEditingController();
  List<PanduanItem> _list = [];
  List<PanduanItem> _filteredList = [];
  bool _loading = true;
  String? _error;
  bool _showSearch = false;

  String? _downloadingLink;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(_list);
      } else {
        _filteredList = _list.where((item) {
          return item.judul.toLowerCase().contains(query) ||
              item.tanggal.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getList();
      if (!mounted) return;
      setState(() {
        _list = data;
        _filteredList = List.from(data);
        _error = null;
      });
      _onSearchChanged(); // Re-apply filter if search text exists
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadAndOpen(PanduanItem item) async {
    if (_downloadingLink != null) return; // Prevent multiple downloads at once

    setState(() {
      _downloadingLink = item.link;
      _downloadProgress = 0.0;
    });

    try {
      final String filename = item.judul.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-\.]'),
        '_',
      );
      final savePath = await _service.downloadPanduan(item.link, filename, (
        received,
        total,
      ) {
        if (total != -1 && mounted) {
          setState(() {
            _downloadProgress = received / total;
          });
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tersimpan di $savePath'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengunduh: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingLink = null;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Panduan Akademik',
      subtitle: 'Dokumen & pedoman perkuliahan',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: Icon(
            _showSearch ? CupertinoIcons.xmark : CupertinoIcons.search,
          ),
          onPressed: _toggleSearch,
        ),
      ],
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: AppSearchField(
                controller: _searchController,
                hint: 'Cari panduan...',
                onClear: () => _searchController.clear(),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoading(message: 'Memuat panduan…');
    }

    if (_error != null) {
      return ListView(
        padding: AppSpacing.page,
        children: [AppErrorState(message: _error!, onRetry: _load)],
      );
    }

    if (_list.isEmpty) {
      return const AppEmptyState(
        title: 'Tidak ada panduan akademik',
        message: 'Dokumen panduan akan tampil di sini setelah tersedia.',
        icon: CupertinoIcons.book,
      );
    }

    if (_filteredList.isEmpty && _searchController.text.isNotEmpty) {
      return AppEmptyState(
        title: 'Tidak ada hasil',
        message: 'Tidak ditemukan panduan untuk "${_searchController.text}"',
        icon: CupertinoIcons.search,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppSection(
            title: 'Dokumen Panduan',
            topGap: 0,
            child: AppListGroup.from([
              for (final item in _filteredList) _buildRow(item),
            ]),
          ),
        ],
      ),
    );
  }

  /// Baris dokumen panduan: judul + keterangan, dengan aksi unduh/buka.
  Widget _buildRow(PanduanItem item) {
    final bool isDownloading = _downloadingLink == item.link;

    return AppListRow(
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: const Icon(
          CupertinoIcons.book,
          size: 18,
          color: AppColors.primary,
        ),
      ),
      title: item.judul,
      subtitle: item.tanggal,
      trailing: isDownloading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          : Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: AppDeco.softPrimary(),
              child: const Icon(
                CupertinoIcons.cloud_download,
                size: 18,
                color: AppColors.primary,
              ),
            ),
      onTap: isDownloading ? null : () => _downloadAndOpen(item),
    );
  }
}

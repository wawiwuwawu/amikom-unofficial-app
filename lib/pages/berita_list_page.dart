import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/berita.dart';
import '../services/berita_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import 'berita_detail_page.dart';

/// Daftar Berita Kampus.
///
/// Berbeda dengan pengumuman, berita punya gambar dan ringkasan — jadi di sini
/// kartu memang tepat dipakai (konten visual), hanya dibuat lebih ringkas:
/// thumbnail kecil, judul maksimal 2 baris, ringkasan, lalu meta.
class BeritaListPage extends StatefulWidget {
  const BeritaListPage({super.key});

  @override
  State<BeritaListPage> createState() => _BeritaListPageState();
}

class _BeritaListPageState extends State<BeritaListPage> {
  final _service = BeritaService();
  final List<Berita> _list = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final offset = (page - 1) * 5;
      final res = await _service.getBerita(offset: offset);
      if (!mounted) return;
      final rawList = res['data'] as List? ?? [];
      final data = rawList
          .map((e) => Berita.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = res['pagination'] is Map<String, dynamic>
          ? Pagination.fromJson(res['pagination'] as Map<String, dynamic>)
          : null;
      setState(() {
        _list
          ..clear()
          ..addAll(data);
        _hasMore = pagination != null
            ? (pagination.hasMore ||
                (pagination.nextOffset != null && pagination.nextOffset! > 0))
            : data.length >= 5;
        _page = page;
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
      title: 'Berita Kampus',
      subtitle: 'Kabar dan kegiatan terbaru',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(1),
              color: AppColors.primary,
              child: AppAsyncView<List<Berita>>(
                loading: _loading,
                error: _error,
                data: _list,
                onRetry: () => _load(1),
                loadingMessage: 'Memuat berita…',
                emptyTitle: 'Belum ada berita',
                emptyMessage: 'Berita terbaru akan muncul di sini.',
                emptyIcon: CupertinoIcons.news_solid,
                isEmpty: (data) => data.isEmpty,
                builder: (data) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => _beritaCard(data[i]),
                ),
              ),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _page > 1 ? () => _load(_page - 1) : null,
              icon: const Icon(CupertinoIcons.chevron_left, size: 18),
              label: const Text('Sebelumnya'),
            ),
            Text('Halaman $_page', style: AppText.label),
            TextButton(
              onPressed: _hasMore ? () => _load(_page + 1) : null,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Selanjutnya'),
                  SizedBox(width: AppSpacing.xs),
                  Icon(CupertinoIcons.chevron_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _beritaCard(Berita b) {
    return AppSurface(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BeritaDetailPage(id: b.id)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.gambar.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
              child: Image.network(
                b.gambar,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  color: AppColors.surfaceMuted,
                  child: const Icon(
                    CupertinoIcons.photo,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    b.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h3,
                  ),
                  if (b.excerpt.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      b.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySm,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    [
                      if (b.author.isNotEmpty) b.author,
                      if (b.tanggal.isNotEmpty) b.tanggal,
                    ].join(' · '),
                    style: AppText.label,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

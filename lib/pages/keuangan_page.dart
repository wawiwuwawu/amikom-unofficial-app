import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/keuangan.dart';
import '../services/keuangan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import 'panduan_pembayaran_page.dart';

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Keuangan & Pembayaran',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(
                  icon: Icon(CupertinoIcons.clock_fill, size: 20),
                  text: 'Riwayat Pembayaran',
                ),
                Tab(
                  icon: Icon(CupertinoIcons.creditcard, size: 20),
                  text: 'Tagihan & Pembayaran',
                ),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _RiwayatPembayaranTab(),
                  _TagihanPembayaranTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiwayatPembayaranTab extends StatefulWidget {
  const _RiwayatPembayaranTab();

  @override
  State<_RiwayatPembayaranTab> createState() => _RiwayatPembayaranTabState();
}

class _RiwayatPembayaranTabState extends State<_RiwayatPembayaranTab> {
  final _service = KeuanganService();
  bool _loading = true;
  bool _downloadingAll = false;
  String? _error;
  List<KeuanganHistoryItem> _historyList = [];
  int _totalBayar = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _service.getHistory();
      if (mounted) {
        setState(() {
          _historyList = res.data;
          _totalBayar = res.totalBayar;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatRupiah(int number) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(number);
  }

  String _semesterLabel(int semester) {
    return semester == 1
        ? 'Ganjil'
        : semester == 2
            ? 'Genap'
            : 'Semester $semester';
  }

  Future<void> _downloadHistoryPdf() async {
    setState(() => _downloadingAll = true);
    try {
      final path = await _service.downloadHistoryPdf();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tersimpan di $path'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh PDF: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  void _showDetailBottomSheet(KeuanganHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _KeuanganDetailSheet(item: item, service: _service),
    );
  }

  Widget _buildSummaryHeader() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppDeco.softPrimary(),
                child: const Icon(
                  CupertinoIcons.money_dollar_circle_fill,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Total Akumulasi Pembayaran',
                  style: AppText.label,
                ),
              ),
              AppPill('${_historyList.length} Kwitansi'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_formatRupiah(_totalBayar), style: AppText.metric),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _downloadingAll ? null : _downloadHistoryPdf,
              icon: _downloadingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.arrow_down_doc_fill, size: 18),
              label: Text(
                _downloadingAll
                    ? 'Mengunduh...'
                    : 'Unduh PDF Histori Keseluruhan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(KeuanganHistoryItem item) {
    final hasKwitansi =
        item.nomorKwitansi != null && item.nomorKwitansi!.isNotEmpty;
    final hasRefBank = item.norefBank != null && item.norefBank!.isNotEmpty;

    final meta = [
      '${item.channelBank} • Angsuran ${item.angsuranKe}',
      'TA ${item.tahunAkademik} • Semester ${_semesterLabel(item.semester)} (Smt Tempuh ${item.semesterTempuh})',
      'Tgl Bayar: ${item.tglBayar}',
      if (hasKwitansi) 'No. Kwitansi: ${item.nomorKwitansi}',
      if (hasRefBank) 'No. Ref Bank: ${item.norefBank}',
    ];

    return AppListRow(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: AppDeco.softPrimary(),
        child: const Icon(
          CupertinoIcons.checkmark_seal_fill,
          size: 18,
          color: AppColors.primary,
        ),
      ),
      title: _formatRupiah(item.jumlahBayar),
      subtitle: meta.join('\n'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppPill('Lunas', tone: AppPillTone.success),
          if (hasKwitansi) ...[
            const SizedBox(height: AppSpacing.xs),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
      onTap: hasKwitansi ? () => _showDetailBottomSheet(item) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoading();
    }
    if (_error != null) {
      return SingleChildScrollView(
        padding: AppSpacing.page,
        child: AppErrorState(message: _error!, onRetry: _load),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        children: [
          _buildSummaryHeader().animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: AppSpacing.xl),
          if (_historyList.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: const AppEmptyState(
                title: 'Belum Ada Riwayat Pembayaran',
                message:
                    'Riwayat pembayaran kuliah Anda akan muncul di sini setelah transaksi dikonfirmasi oleh sistem.',
                icon: CupertinoIcons.money_dollar_circle,
              ),
            )
          else
            AppListGroup.from([
              for (var item in _historyList) _buildHistoryRow(item),
            ])
                .animate()
                .fadeIn()
                .slideY(begin: 0.04, end: 0),
        ],
      ),
    );
  }
}

class _KeuanganDetailSheet extends StatefulWidget {
  final KeuanganHistoryItem item;
  final KeuanganService service;

  const _KeuanganDetailSheet({
    required this.item,
    required this.service,
  });

  @override
  State<_KeuanganDetailSheet> createState() => _KeuanganDetailSheetState();
}

class _KeuanganDetailSheetState extends State<_KeuanganDetailSheet> {
  bool _loading = true;
  bool _downloading = false;
  String? _error;
  List<KeuanganDetailItem> _details = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final res = await widget.service.getHistoryDetail(widget.item);
      if (mounted) {
        setState(() {
          _details = res;
          _error = null;
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

  Future<void> _downloadKwitansiPdf() async {
    setState(() => _downloading = true);
    try {
      final path = await widget.service.downloadDetailPdf(widget.item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kwitansi tersimpan di $path'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh kwitansi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _formatRupiah(int number) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(number);
  }

  String _semesterLabel(int semester) {
    return semester == 1
        ? 'Ganjil'
        : semester == 2
            ? 'Genap'
            : 'Semester $semester';
  }

  @override
  Widget build(BuildContext context) {
    final totalNominal = _details.fold<int>(0, (sum, e) => sum + e.nominal);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text('Rincian Komponen Biaya', style: AppText.h2),
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'TA ${widget.item.tahunAkademik} • Semester ${_semesterLabel(widget.item.semester)} (${widget.item.channelBank})',
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            Expanded(
              child: _loading
                  ? const AppLoading()
                  : _error != null
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: AppErrorState(
                            message: _error!,
                            onRetry: _loadDetail,
                          ),
                        )
                      : _details.isEmpty
                          ? const AppEmptyState(
                              title: 'Tidak ada rincian komponen biaya.',
                              icon: CupertinoIcons.doc_text,
                            )
                          : ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              children: [
                                AppListGroup.from([
                                  for (final d in _details)
                                    AppListRow(
                                      title: d.jenisBiaya,
                                      subtitle: 'Ref: ${d.noReferensi}',
                                      trailing: Text(
                                        _formatRupiah(d.nominal),
                                        style: AppText.h3.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ]),
                              ],
                            ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Biaya Rincian:', style: AppText.h3),
                  Text(
                    _formatRupiah(
                      totalNominal > 0 ? totalNominal : widget.item.jumlahBayar,
                    ),
                    style: AppText.metric.copyWith(
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _downloading ? null : _downloadKwitansiPdf,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(CupertinoIcons.arrow_down_doc_fill, size: 18),
                label: Text(
                  _downloading
                      ? 'Mengunduh Kwitansi...'
                      : 'Unduh Kwitansi Detail (PDF)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagihanPembayaranTab extends StatefulWidget {
  const _TagihanPembayaranTab();

  @override
  State<_TagihanPembayaranTab> createState() => _TagihanPembayaranTabState();
}

class _TagihanPembayaranTabState extends State<_TagihanPembayaranTab> {
  final _service = KeuanganService();
  bool _loading = true;
  bool _processing = false;
  String? _error;
  KeuanganTagihanResponse? _tagihan;
  final Set<String> _selectedIdtrans = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _service.getTagihan();
      if (mounted) {
        setState(() {
          _tagihan = res;
          _selectedIdtrans.clear();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _hasActiveVa => _tagihan?.activeTransaction.hasActive ?? false;

  String _formatRupiah(int number) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(number);
  }

  String _formatTahunAkademik(String tahunAkademik) {
    final parts = tahunAkademik.split('-');
    if (parts.length == 2) {
      final semesterLabel = parts[1].trim();
      final num = int.tryParse(semesterLabel);
      if (num == 1) {
        return '${parts[0].trim()} - Ganjil';
      }
      if (num == 2) {
        return '${parts[0].trim()} - Genap';
      }
    }
    return tahunAkademik;
  }

  Future<void> _copyToClipboard(String text, {String label = 'Nomor disalin'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label: $text'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get _selectedNominal {
    final items = _tagihan?.data ?? [];
    int total = 0;
    for (var item in items) {
      if (_selectedIdtrans.contains(item.idtrans)) {
        total += item.nominal;
      }
    }
    return total;
  }

  void _showPilihBankSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Pilih Channel Pembayaran', style: AppText.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Total yang dibayar: ${_formatRupiah(_selectedNominal)}',
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildBankOption(
              ctx,
              label: 'BRI Virtual Account',
              subtitle: 'Bayar via transfer BRI',
              code: 'brivia',
              icon: CupertinoIcons.building_2_fill,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBankOption(
              ctx,
              label: 'Bank Muamalat',
              subtitle: 'Bayar via transfer Muamalat',
              code: 'muamalat',
              icon: CupertinoIcons.building_2_fill,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildBankOption(
    BuildContext ctx, {
    required String label,
    required String subtitle,
    required String code,
    required IconData icon,
  }) {
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      onTap: () async {
        Navigator.pop(ctx);
        await _prosesBayar(code);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDeco.softPrimary(),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppText.h3),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.bodySm),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Future<void> _prosesBayar(String channelBank) async {
    if (_selectedIdtrans.isEmpty) return;
    final items = (_tagihan?.data ?? [])
        .where((e) => _selectedIdtrans.contains(e.idtrans))
        .toList();

    setState(() => _processing = true);
    try {
      final res = await _service.bayarTagihan(channelBank, items);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _VaSuksesPage(result: res),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat VA: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _batalkanVa() async {
    final active = _tagihan?.activeTransaction;
    if (active == null || !active.hasActive) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Transaksi VA'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan transaksi Virtual Account yang aktif saat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await _service.batalTagihan(
        active.channelBank,
        active.va,
        active.items.isNotEmpty && active.items.first is Map
            ? (active.items.first as Map)['idtrans']?.toString() ?? ''
            : '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi pembayaran berhasil dibatalkan'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildSummaryHeader() {
    final list = _tagihan?.data ?? [];
    final hasTunggakan = list.isNotEmpty;
    final accent = hasTunggakan ? AppColors.warning : AppColors.primary;

    return AppSurface(
      variant: hasTunggakan ? AppSurfaceVariant.warning : AppSurfaceVariant.plain,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: AppStatTile(
                value: _formatRupiah(_tagihan?.totalTagihan ?? 0),
                label: 'Total Tagihan',
                icon: CupertinoIcons.doc_text_fill,
                accent: accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: AppStatTile(
                value: '${list.length}',
                label: 'Belum Lunas',
                icon: CupertinoIcons.exclamationmark_circle,
                accent: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanduanCard() {
    return AppListGroup(
      children: [
        AppListRow(
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDeco.softPrimary(),
            child: const Icon(
              CupertinoIcons.book,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          title: 'Panduan & Tata Cara Pembayaran',
          subtitle:
              'Ketuk untuk melihat langkah-langkah pembayaran via Bank Muamalat & BRI/BRIVA.',
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: AppColors.textMuted,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PanduanPembayaranPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveVaCard() {
    final active = _tagihan!.activeTransaction;
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.creditcard_fill,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Tagihan Aktif (Virtual Account)',
                  style: AppText.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Nomor Virtual Account', style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            active.va.isEmpty ? '-' : active.va,
            style: AppText.metric.copyWith(
              fontSize: 22,
              letterSpacing: 1.2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Total: ${_formatRupiah(active.totalNominal)} • ${active.channelBank.toUpperCase()}',
            style: AppText.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _copyToClipboard(active.va, label: 'Nomor VA disalin'),
                  icon: const Icon(CupertinoIcons.doc_on_doc, size: 14),
                  label: const Text('Copy Nomor VA'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextButton.icon(
                  onPressed: _processing ? null : _batalkanVa,
                  icon: _processing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(CupertinoIcons.xmark_circle, size: 14),
                  label: const Text('Batalkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaActiveWarning() {
    final totalNominal = _tagihan?.activeTransaction.totalNominal ?? 0;
    return AppSurface(
      variant: AppSurfaceVariant.warning,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Transaksi VA masih aktif (${_formatRupiah(totalNominal)})',
                  style: AppText.h3.copyWith(color: AppColors.warning),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Batalkan transaksi sebelum mengganti pilihan tagihan agar tidak terjadi transaksi ganda.',
                  style: AppText.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTagihan(KeuanganTagihanItem item, bool selected) {
    setState(() {
      if (selected) {
        _selectedIdtrans.add(item.idtrans);
      } else {
        _selectedIdtrans.remove(item.idtrans);
      }
    });
  }

  Widget _buildTagihanRow(KeuanganTagihanItem item) {
    final isSelected = _selectedIdtrans.contains(item.idtrans);
    final disabled = _hasActiveVa;

    return AppListRow(
      leading: Checkbox(
        value: isSelected,
        visualDensity: VisualDensity.compact,
        onChanged: disabled ? null : (val) => _toggleTagihan(item, val == true),
      ),
      title: item.jenisPembayaran,
      subtitle: 'TA ${_formatTahunAkademik(item.tahunAkademik)}',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatRupiah(item.nominal),
            style: AppText.h3.copyWith(
              color: disabled ? AppColors.textMuted : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppPill(
            'Belum bayar',
            tone: disabled ? AppPillTone.neutral : AppPillTone.warning,
          ),
        ],
      ),
      onTap: disabled ? null : () => _toggleTagihan(item, !isSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoading();
    }
    if (_error != null) {
      return SingleChildScrollView(
        padding: AppSpacing.page,
        child: AppErrorState(message: _error!, onRetry: _load),
      );
    }

    final tagihanList = _tagihan?.data ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        children: [
          _buildSummaryHeader().animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: AppSpacing.lg),
          _buildPanduanCard(),
          if (_hasActiveVa) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildActiveVaCard(),
            const SizedBox(height: AppSpacing.md),
            _buildVaActiveWarning(),
          ],
          if (!_hasActiveVa && tagihanList.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: const AppEmptyState(
                title: 'Tidak Ada Tagihan',
                message:
                    'Seluruh kewajiban pembayaran perkuliahan Anda saat ini sudah lunas.',
                icon: CupertinoIcons.checkmark_circle_fill,
              ),
            )
          else if (!_hasActiveVa) ...[
            AppSection(
              title: 'Daftar Tagihan',
              trailing: Text(
                'Terpilih: ${_formatRupiah(_selectedNominal)}',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: AppListGroup.from([
                for (var item in tagihanList) _buildTagihanRow(item),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildBayarButton(),
        ],
      ),
    );
  }

  Widget _buildBayarButton() {
    final canPay = _selectedIdtrans.isNotEmpty && !_hasActiveVa;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: (canPay && !_processing) ? _showPilihBankSheet : null,
        icon: _processing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(CupertinoIcons.creditcard_fill, size: 18),
        label: Text(
          _processing
              ? 'Memproses...'
              : _hasActiveVa
                  ? 'Batalkan VA Aktif untuk Bayar'
                  : 'Bayar Tagihan Terpilih',
        ),
      ),
    );
  }
}

class _VaSuksesPage extends StatelessWidget {
  final KeuanganVaResult result;

  const _VaSuksesPage({required this.result});

  String _formatRupiah(int number) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Virtual Account Berhasil Dibuat',
              textAlign: TextAlign.center,
              style: AppText.h1,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Silakan lakukan transfer ke nomor Virtual Account berikut sebelum batas waktu kedaluwarsa.',
              textAlign: TextAlign.center,
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSurface(
              child: Column(
                children: [
                  Text('Nomor Virtual Account', style: AppText.label),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    result.va,
                    textAlign: TextAlign.center,
                    style: AppText.metric.copyWith(
                      fontSize: 24,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${result.channelBank.toUpperCase()} • Total ${_formatRupiah(result.totalNominal)}',
                    textAlign: TextAlign.center,
                    style: AppText.bodySm,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppListGroup.from([
              for (var item in result.items)
                AppListRow(
                  title: item.jenisPembayaran,
                  trailing: Text(
                    _formatRupiah(item.nominal),
                    style: AppText.h3,
                  ),
                ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              variant: AppSurfaceVariant.warning,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.alarm,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Nomor VA berlaku sementara. Setelah transfer sukses, status pembayaran baru ter-update setelah proses settlement bank. Status dapat dicek kembali pada tab "Riwayat Pembayaran".',
                      style: AppText.bodySm,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: result.va));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nomor VA disalin'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                label: const Text('Copy Nomor VA'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

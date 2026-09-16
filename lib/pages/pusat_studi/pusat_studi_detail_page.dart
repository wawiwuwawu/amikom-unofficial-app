import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/pusat_studi.dart';
import '../../services/pusat_studi_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_kit.dart';
import '../../widgets/expandable_html.dart';

class PusatStudiDetailPage extends StatefulWidget {
  final PusatStudi pusatStudi;
  final bool isJoined;

  const PusatStudiDetailPage({super.key, required this.pusatStudi, this.isJoined = false});

  @override
  State<PusatStudiDetailPage> createState() => _PusatStudiDetailPageState();
}

class _PusatStudiDetailPageState extends State<PusatStudiDetailPage> {
  final PusatStudiService _service = PusatStudiService();
  bool _isLoading = true;
  bool _isJoining = false;
  String _error = '';
  PusatStudiDetail? _detail;
  String _activeTab = 'profil'; // 'profil', 'dosen', 'mahasiswa', 'tema'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      _detail = await _service.getDetailPusatStudi(widget.pusatStudi.detailId);
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

  Future<void> _join() async {
    setState(() {
      _isJoining = true;
    });
    try {
      await _service.joinPusatStudi(widget.pusatStudi.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil bergabung dengan Pusat Studi!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.pusatStudi.nama,
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: (!widget.isJoined && _detail != null)
          ? FloatingActionButton.extended(
              onPressed: _isJoining ? null : _join,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: _isJoining
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(CupertinoIcons.person_add_solid),
              label: Text(_isJoining ? 'Memproses...' : 'Gabung Pusat Studi'),
            )
          : null,
      body: _buildBody(),
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

    if (_detail == null) {
      return const AppEmptyState(
        title: 'Data tidak ditemukan',
        icon: CupertinoIcons.info_circle,
      );
    }

    return Column(
      children: [
        _buildTabToggle(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildActiveContent(),
          ),
        ),
      ],
    );
  }

  /// Pengalih seksi ringkas — memakai token, bukan kartu kaca.
  Widget _buildTabToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: AppDeco.listGroup(),
        child: Row(
          children: [
            _buildTabButton('Profil', 'profil'),
            _buildTabButton('Dosen', 'dosen'),
            _buildTabButton('Mahasiswa', 'mahasiswa'),
            _buildTabButton('Tema', 'tema'),
          ],
        ),
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
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          title,
          style: AppText.button.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeTab) {
      case 'profil':
        return _buildProfilSection();
      case 'dosen':
        return _buildDosenSection();
      case 'mahasiswa':
        return _buildMahasiswaSection();
      case 'tema':
        return _buildTemaSection();
      default:
        return const SizedBox();
    }
  }

  EdgeInsetsGeometry get _sectionPadding => EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xxl * 2,
      );

  /// Profil = data identitas → baris label/nilai di dalam satu permukaan.
  Widget _buildProfilSection() {
    final profil = _detail!.profil;
    return ListView(
      key: const ValueKey('profil'),
      padding: _sectionPadding,
      children: [
        AppSection(
          title: 'Profil Pusat Studi',
          topGap: 0,
          child: AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppKeyValue(label: 'Nama', value: profil.nama, emphasize: true),
                const Divider(height: AppSpacing.xl, color: AppColors.border),
                if (profil.keterangan.isEmpty)
                  Text('Tidak ada keterangan', style: AppText.body)
                else
                  Html(
                    data: profil.keterangan,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        color: AppColors.textPrimary,
                      ),
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDosenSection() {
    if (_detail!.dosen.isEmpty) {
      return const AppEmptyState(
        key: ValueKey('dosen-empty'),
        title: 'Belum ada dosen pembimbing',
        icon: CupertinoIcons.person_2,
      );
    }
    return ListView(
      key: const ValueKey('dosen'),
      padding: _sectionPadding,
      children: [
        AppListGroup.from([
          for (final dosen in _detail!.dosen)
            AppListRow(
              leading: _initialAvatar(dosen.no, AppColors.primary, AppColors.primary),
              title: dosen.nama,
              subtitle: 'NIK: ${dosen.nik}',
            ),
        ]),
      ],
    );
  }

  Widget _buildMahasiswaSection() {
    if (_detail!.mahasiswa.isEmpty) {
      return const AppEmptyState(
        key: ValueKey('mahasiswa-empty'),
        title: 'Belum ada mahasiswa yang tergabung',
        icon: CupertinoIcons.person_3,
      );
    }
    return ListView(
      key: const ValueKey('mahasiswa'),
      padding: _sectionPadding,
      children: [
        AppListGroup.from([
          for (final mhs in _detail!.mahasiswa)
            AppListRow(
              leading: Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.infoBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.person_fill, color: AppColors.info, size: 16),
              ),
              title: mhs.nama,
              subtitle: 'NPM: ${mhs.npm}\nJoin: ${mhs.tanggalJoin}',
            ),
        ]),
      ],
    );
  }

  /// Tema riset = konten panjang (HTML) → tetap berupa permukaan.
  Widget _buildTemaSection() {
    if (_detail!.tema.isEmpty) {
      return const AppEmptyState(
        key: ValueKey('tema-empty'),
        title: 'Belum ada tema riset',
        icon: CupertinoIcons.doc_text,
      );
    }
    return ListView(
      key: const ValueKey('tema'),
      padding: _sectionPadding,
      children: [
        for (final tema in _detail!.tema)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildTemaCard(tema),
          ),
      ],
    );
  }

  Widget _buildTemaCard(TemaPusatStudi tema) {
    return AppSurface(
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tema.judulTema, style: AppText.h3),
          const SizedBox(height: AppSpacing.sm),
          ExpandableHtml(htmlData: tema.deskripsi),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(CupertinoIcons.person_solid, size: 14, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(tema.pengusul, style: AppText.bodySm)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppPill('Jenis: ${tema.jenisTema}', tone: AppPillTone.info),
              AppPill('Kuota: ${tema.kuota}', tone: AppPillTone.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar(String text, Color foreground, Color accent) {
    return Container(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: AppText.label.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

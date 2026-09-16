import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/akademik_service.dart';
import '../models/agenda.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Agenda akademik — kalender bulanan di atas, lalu daftar kegiatan yang
/// disusun kronologis per bulan ([AppSection] = nama bulan, isinya
/// [AppListGroup] + [AppListRow] dengan lencana tanggal).
///
/// Memilih tanggal di kalender menyaring daftar ke hari itu (sama seperti
/// sebelumnya); tombol "Lihat Semua" mengembalikan ke seluruh agenda.
/// Tombol kembali disediakan otomatis oleh [AppScaffold], sehingga `onBack`
/// dipertahankan hanya untuk kompatibilitas pemanggil lama.
class AgendaAkademikPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AgendaAkademikPage({super.key, this.onBack});

  @override
  State<AgendaAkademikPage> createState() => _AgendaAkademikPageState();
}

/// Satu kegiatan + tanggal mulai terparsenya, dipakai untuk mengurutkan
/// tampilan daftar tanpa mengubah urutan data asli.
class _AgendaBertanggal {
  final int urutan;
  final DateTime? tanggal;
  final Agenda agenda;

  _AgendaBertanggal(this.urutan, this.tanggal, this.agenda);
}

/// Kelompok daftar agenda untuk satu bulan.
class _KelompokBulan {
  final String label;
  final List<Agenda> agenda;

  _KelompokBulan(this.label, this.agenda);
}

class _AgendaAkademikPageState extends State<AgendaAkademikPage> {
  final AkademikService _service = AkademikService();
  bool _isLoading = true;
  String _error = '';
  List<Agenda> _agendaList = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, int> _bulanIndo = {
    'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4,
    'Mei': 5, 'Juni': 6, 'Juli': 7, 'Agustus': 8,
    'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12,
  };

  final List<Color> _eventColors = [
    AppColors.primary,
    AppColors.primarySoft,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.danger,
    AppColors.textSecondary,
  ];

  Color _getColorForAgenda(Agenda agenda) {
    int index = _agendaList.indexOf(agenda);
    if (index == -1) index = agenda.title.hashCode.abs();
    return _eventColors[index % _eventColors.length];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getAgenda();
      setState(() {
        _agendaList = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  DateTime? _parseTanggal(String tgl) {
    try {
      final parts = tgl.trim().split(' ');
      if (parts.length >= 3) {
        int day = int.tryParse(parts[0]) ?? 1;
        int month = _bulanIndo[parts[1]] ?? 1;
        int year = int.tryParse(parts[2]) ?? DateTime.now().year;
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  List<Agenda> _getEventsForDay(DateTime day) {
    List<Agenda> events = [];
    for (var agenda in _agendaList) {
      final start = _parseTanggal(agenda.mulai);
      final end = _parseTanggal(agenda.selesai);

      if (start != null) {
        if (end == null && isSameDay(day, start)) {
          events.add(agenda);
        }
        else if (end != null) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final normalizedStart = DateTime(start.year, start.month, start.day);
          final normalizedEnd = DateTime(end.year, end.month, end.day);

          if (normalizedDay.isAfter(normalizedStart.subtract(const Duration(days: 1))) &&
              normalizedDay.isBefore(normalizedEnd.add(const Duration(days: 1)))) {
            events.add(agenda);
          }
        }
      }
    }
    return events;
  }

  Future<void> _addToGoogleCalendar(Agenda agenda) async {
    final start = _parseTanggal(agenda.mulai);
    final end = _parseTanggal(agenda.selesai) ?? start;

    if (start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format tanggal tidak valid')),
      );
      return;
    }

    final format = DateFormat('yyyyMMdd');
    final startDateStr = format.format(start);
    final endDateStr = format.format(end!.add(const Duration(days: 1)));

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(agenda.title)}'
      '&dates=$startDateStr/$endDateStr'
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Tidak dapat membuka kalender');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ── Pemetaan bulan untuk tampilan ──────────────────────────────────────────

  String _namaBulan(int bulan) {
    for (final entry in _bulanIndo.entries) {
      if (entry.value == bulan) return entry.key;
    }
    return '';
  }

  String _labelBulan(DateTime tanggal) {
    final nama = _namaBulan(tanggal.month);
    return nama.isEmpty ? '${tanggal.year}' : '$nama ${tanggal.year}';
  }

  String _labelBulanSingkat(DateTime tanggal) {
    final nama = _namaBulan(tanggal.month);
    if (nama.length < 3) return nama.toUpperCase();
    return nama.substring(0, 3).toUpperCase();
  }

  /// Kelompokkan agenda kronologis per bulan. Agenda tanpa tanggal valid
  /// diletakkan paling akhir agar tidak menutupi data utama.
  List<_KelompokBulan> _kelompokkanPerBulan(List<Agenda> items) {
    final entries = <_AgendaBertanggal>[
      for (var i = 0; i < items.length; i++)
        _AgendaBertanggal(i, _parseTanggal(items[i].mulai), items[i]),
    ];

    entries.sort((a, b) {
      final ta = a.tanggal;
      final tb = b.tanggal;
      if (ta == null && tb == null) return a.urutan.compareTo(b.urutan);
      if (ta == null) return 1;
      if (tb == null) return -1;
      final banding = ta.compareTo(tb);
      return banding != 0 ? banding : a.urutan.compareTo(b.urutan);
    });

    final hasil = <_KelompokBulan>[];
    for (final entry in entries) {
      final tanggal = entry.tanggal;
      final label = tanggal == null ? 'Tanggal belum tersedia' : _labelBulan(tanggal);
      if (hasil.isEmpty || hasil.last.label != label) {
        hasil.add(_KelompokBulan(label, [entry.agenda]));
      } else {
        hasil.last.agenda.add(entry.agenda);
      }
    }
    return hasil;
  }

  // ── Tampilan ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Agenda Akademik',
      subtitle: 'Kalender & jadwal kegiatan',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoading(message: 'Memuat agenda akademik…');

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: _error, onRetry: _loadData),
        ),
      );
    }

    // Agenda hari terpilih untuk ditampilkan di daftar bawah kalender.
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Agenda>[];
    final visible =
        _selectedDay != null && selectedEvents.isNotEmpty ? selectedEvents : _agendaList;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildRingkasanBulan(),
          AppSection(
            title: 'Kalender',
            child: AppSurface(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _buildCalendar(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDay != null
                      ? 'Agenda di ${DateFormat('dd MMM yyyy').format(_selectedDay!)}'
                      : 'Semua Agenda',
                  style: AppText.h2,
                ),
              ),
              if (_selectedDay != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = null;
                    });
                  },
                  child: const Text('Lihat Semua'),
                ),
            ],
          ),
          if (_agendaList.isEmpty)
            const AppEmptyState(
              title: 'Belum ada agenda akademik sama sekali.',
              icon: CupertinoIcons.calendar,
            )
          else if (visible.isEmpty)
            const AppEmptyState(
              title: 'Tidak ada agenda pada tanggal ini.',
              icon: CupertinoIcons.calendar_badge_minus,
            )
          else
            ..._buildKelompokBulan(visible),
        ],
      ),
    );
  }

  /// Sorotan bulan & hari berjalan (kartu hero ringkas).
  Widget _buildRingkasanBulan() {
    final now = DateTime.now();
    final agendaHariIni = _getEventsForDay(now).length;
    final agendaBulanIni = _agendaList.where((agenda) {
      final tanggal = _parseTanggal(agenda.mulai);
      return tanggal != null && tanggal.month == now.month && tanggal.year == now.year;
    }).length;

    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: AppDeco.softPrimary(),
            child: const Icon(CupertinoIcons.calendar_today, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelBulan(now), style: AppText.h3),
                const SizedBox(height: 2),
                Text(
                  'Hari ini: $agendaHariIni kegiatan • Bulan ini: $agendaBulanIni kegiatan',
                  style: AppText.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKelompokBulan(List<Agenda> items) {
    return [
      for (final kelompok in _kelompokkanPerBulan(items))
        AppSection(
          title: kelompok.label,
          trailing: Text(
            '${kelompok.agenda.length} kegiatan',
            style: AppText.label.copyWith(fontWeight: FontWeight.w400),
          ),
          child: AppListGroup.from([
            for (final agenda in kelompok.agenda) _buildAgendaRow(agenda),
          ]),
        ),
    ];
  }

  /// Satu baris kegiatan: lencana tanggal · nama kegiatan · waktu,
  /// plus aksi simpan ke Google Calendar.
  Widget _buildAgendaRow(Agenda agenda) {
    final tanggal = _parseTanggal(agenda.mulai);
    final waktu = agenda.selesai.isNotEmpty && agenda.mulai != agenda.selesai
        ? '${agenda.mulai} - ${agenda.selesai}'
        : agenda.mulai;

    return AppListRow(
      leading: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tanggal != null ? '${tanggal.day}' : '—',
              style: AppText.h3.copyWith(fontSize: 17, color: AppColors.primary),
            ),
            if (tanggal != null)
              Text(
                _labelBulanSingkat(tanggal),
                style: AppText.label.copyWith(color: AppColors.primarySoft),
              ),
          ],
        ),
      ),
      title: agenda.title,
      subtitle: waktu,
      trailing: IconButton(
        tooltip: 'Simpan ke Google Calendar',
        onPressed: () => _addToGoogleCalendar(agenda),
        icon: const Icon(
          CupertinoIcons.calendar_badge_plus,
          size: 20,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<Agenda>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      eventLoader: _getEventsForDay,
      calendarFormat: CalendarFormat.month,
      rowHeight: 70, // Ditinggikan agar event title muat di dalam kotak
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: AppText.h3.copyWith(color: AppColors.primary),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppText.label.copyWith(color: AppColors.textMuted),
        weekendStyle: AppText.label.copyWith(color: AppColors.textMuted),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: false, isSelected: false),
        todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: true, isSelected: false),
        selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: false, isSelected: true),
        outsideBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: false, isSelected: false, isOutside: true),
        markerBuilder: (context, day, events) {
          // Marker dirender manual di dalam cell builder agar lebih fleksibel.
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    final events = _getEventsForDay(day);

    return Container(
      margin: const EdgeInsets.all(2), // margin kecil agar membentuk grid
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : isToday
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, right: 6),
            child: Text(
              '${day.day}',
              textAlign: TextAlign.right,
              style: AppText.label.copyWith(
                fontSize: 12,
                fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isOutside
                        ? AppColors.textMuted
                        : isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (events.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: AppSpacing.xs),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length > 2 ? 2 : events.length,
                  itemBuilder: (context, index) {
                    final agenda = events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 3, left: 2, right: 2),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.4)
                            : _getColorForAgenda(agenda).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        agenda.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppText.label.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

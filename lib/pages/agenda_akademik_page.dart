import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/akademik_service.dart';
import '../models/agenda.dart';
import '../widgets/glass_card.dart';

class AgendaAkademikPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AgendaAkademikPage({super.key, this.onBack});

  @override
  State<AgendaAkademikPage> createState() => _AgendaAkademikPageState();
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
    const Color(0xFF501F66),
    Colors.blue.shade700,
    Colors.teal.shade700,
    Colors.orange.shade700,
    Colors.pink.shade700,
    Colors.indigo.shade700,
    Colors.green.shade700,
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // get events for selected day to show in the list below
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Agenda>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Agenda Akademik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF501F66),
                    child: ListView(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _buildCalendar().animate().fadeIn().slideY(begin: 0.1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDay != null 
                                    ? 'Agenda di ${DateFormat('dd MMM yyyy').format(_selectedDay!)}'
                                    : 'Semua Agenda',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF501F66),
                                ),
                              ).animate().fadeIn(delay: 100.ms),
                            ),
                            if (_selectedDay != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDay = null;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF501F66),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                              ).animate().fadeIn(delay: 100.ms),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey(_selectedDay?.toIso8601String() ?? 'all'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_agendaList.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('Belum ada agenda akademik sama sekali.', style: TextStyle(color: Colors.black54)),
                                  ),
                                )
                              else if (selectedEvents.isEmpty && _selectedDay != null)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('Tidak ada agenda pada tanggal ini.', style: TextStyle(color: Colors.black54)),
                                  ),
                                )
                              else
                                ...(_selectedDay != null && selectedEvents.isNotEmpty ? selectedEvents : _agendaList)
                                    .asMap().entries.map((entry) {
                                  return _buildAgendaCard(entry.value, entry.key)
                                      .animate()
                                      .fadeIn(delay: (100 + (entry.key * 50)).ms)
                                      .slideX(begin: 0.1);
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCalendar() {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      borderRadius: 20,
      opacity: 0.9,
      child: TableCalendar<Agenda>(
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
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: false, isSelected: false),
          todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: true, isSelected: false),
          selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: false, isSelected: true),
          outsideBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: false, isSelected: false, isOutside: true),
          markerBuilder: (context, day, events) {
            // Kita render manual marker di dalam cell builder agar lebih fleksibel
            return const SizedBox(); 
          },
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    final events = _getEventsForDay(day);
    
    return Container(
      margin: const EdgeInsets.all(2), // margin kecil agar membentuk grid
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF501F66) 
            : isToday 
                ? const Color(0xFF501F66).withOpacity(0.1) 
                : Colors.white,
        borderRadius: BorderRadius.circular(8), // Kotak dengan sudut membulat
        border: Border.all(color: isSelected ? const Color(0xFF501F66) : Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 6.0),
            child: Text(
              '${day.day}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Colors.white 
                    : isOutside 
                        ? Colors.grey 
                        : isToday 
                            ? const Color(0xFF501F66) 
                            : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (events.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2.0, right: 2.0, bottom: 4.0),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length > 2 ? 2 : events.length,
                  itemBuilder: (context, index) {
                    final agenda = events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 3, left: 2, right: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.4) : _getColorForAgenda(agenda).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        agenda.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF501F66) : Colors.white,
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

  Widget _buildAgendaCard(Agenda agenda, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        opacity: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF501F66).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.calendar_today, color: Color(0xFF501F66)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agenda.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF501F66),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.time, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              agenda.selesai.isNotEmpty && agenda.mulai != agenda.selesai
                                  ? '${agenda.mulai} - ${agenda.selesai}'
                                  : agenda.mulai,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToGoogleCalendar(agenda),
                icon: const Icon(CupertinoIcons.add, size: 18),
                label: const Text('Simpan ke Google Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF501F66),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF501F66), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

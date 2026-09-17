// lib/features/calendar/presentation/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/event_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/events_repository.dart';
import 'add_event_screen.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repository = EventsRepository();
  List<FamilyEventModel>? _events;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = _dateOnly(DateTime.now());
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final events = await _repository.getEvents();
      if (!mounted) return;
      setState(() => _events = events);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  List<FamilyEventModel> _eventsForDay(DateTime day) {
    final target = _dateOnly(day);
    return (_events ?? [])
        .where((e) => _dateOnly(e.dateEvenement) == target)
        .toList();
  }

  List<FamilyEventModel> get _upcoming {
    final now = _dateOnly(DateTime.now());
    final horizon = now.add(const Duration(days: 7));
    final list = (_events ?? [])
        .where((e) {
          final d = _dateOnly(e.dateEvenement);
          return !d.isBefore(now) && !d.isAfter(horizon);
        })
        .toList();
    list.sort((a, b) => a.dateEvenement.compareTo(b.dateEvenement));
    return list;
  }

  Future<void> _addEvent() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AddEventScreen(initialDate: _selectedDay),
    ));
    if (created == true) _load();
  }

  Future<void> _deleteEvent(FamilyEventModel event) async {
    try {
      await _repository.deleteEvent(event.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier familial')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vertForet,
        onPressed: _addEvent,
        child: const Icon(Icons.add, color: AppColors.blanc),
      ),
      body: _error != null
          ? Center(child: AppBanner(message: _error!))
          : _events == null
              ? const AppLoader()
              : ListView(
                  children: [
                    TableCalendar<FamilyEventModel>(
                      firstDay: DateTime(2000),
                      lastDay: DateTime(2100),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => _dateOnly(day) == _selectedDay,
                      calendarFormat: _format,
                      eventLoader: _eventsForDay,
                      onFormatChanged: (format) => setState(() => _format = format),
                      onPageChanged: (day) => _focusedDay = day,
                      onDaySelected: (selected, focused) => setState(() {
                        _selectedDay = _dateOnly(selected);
                        _focusedDay = focused;
                      }),
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(color: AppColors.or, shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: AppColors.vertForet, shape: BoxShape.circle),
                        markerDecoration: BoxDecoration(color: AppColors.vertClair, shape: BoxShape.circle),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonShowsNext: false,
                        titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const Divider(height: 1),
                    if (_upcoming.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: AppSectionHeader(title: 'À venir (7 prochains jours)'),
                      ),
                      ..._upcoming.map((e) => _EventTile(event: e, onDelete: () => _deleteEvent(e))),
                      const Divider(height: 1),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: AppSectionHeader(
                        title:
                            'Le ${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}',
                      ),
                    ),
                    if (_eventsForDay(_selectedDay).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text('Aucun événement ce jour-là.', style: TextStyle(color: AppColors.gris)),
                      )
                    else
                      ..._eventsForDay(_selectedDay).map((e) => _EventTile(event: e, onDelete: () => _deleteEvent(e))),
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final FamilyEventModel event;
  final VoidCallback onDelete;
  const _EventTile({required this.event, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        (kEventTypeLabels[event.typeEvenement] ?? '📌 Autre').split(' ').first,
        style: const TextStyle(fontSize: 22),
      ),
      title: Text(event.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        [
          if (event.heure != null) event.heure,
          if (event.personneConcernee != null) event.personneConcernee,
        ].whereType<String>().join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.erreur, size: 20),
        onPressed: onDelete,
      ),
    );
  }
}

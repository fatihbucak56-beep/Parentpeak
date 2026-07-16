import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/backend_service_factory.dart';
import 'package:parentpeak/logic/calendar_backend_service.dart';
import 'package:parentpeak/logic/notification_service.dart';
import 'package:parentpeak/logic/product_metrics_service.dart';
import 'package:parentpeak/ui/chat_screen.dart';
import 'package:parentpeak/ui/entwicklung_impulse_screen.dart';
import 'package:parentpeak/widgets/language_change_mixin.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with LanguageChangeMixin<CalendarScreen> {
  final List<_CalendarEvent> _events = [];
  final CalendarBackendService _calendarService =
      BackendServiceFactory.createCalendarService();
  final TextEditingController _titleController = TextEditingController();
  String? _syncError;
  String _filterPerson = 'Alle';
  static const int _smartReminderValue = -1;
  final List<int> _reminderOptions = [_smartReminderValue, 0, 10, 30, 60];
  final List<String> _recurrenceOptions = [
    'Einmalig',
    'Täglich',
    'Wöchentlich',
    'Monatlich'
  ];
  final List<String> _recurrenceEndOptions = [
    'Kein Ende',
    '5 Termine',
    '10 Termine',
    'Datum wählen'
  ];
  final String _recurrenceEndMode = 'Kein Ende';
  DateTime? _recurrenceEndDate;
  final int _recurrenceCount = 5;

  late DateTime _focusedDay;
  late DateTime _selectedDay;

  final Map<String, Color> _personColors = {
    'Eltern': const Color(0xFF4CAF50),
    'Mia': const Color(0xFFFF6B6B),
    'Ben': const Color(0xFF6C63FF),
    'Kindergarten': const Color(0xFFFFC107),
  };

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay =
        DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final saved = await _calendarService.fetchEvents();
    final syncError = _calendarService.lastSyncError;
    if (!mounted) return;

    if (saved.isEmpty) {
      if (!mounted) return;
      setState(() {
        _events.clear();
        _syncError = syncError;
      });

      await _scheduleRemindersFor(_events);
      return;
    }

    setState(() {
      _events
        ..clear()
        ..addAll(saved.map(_CalendarEvent.fromJson));
      _syncError = syncError;
    });

    await _scheduleRemindersFor(_events);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<_CalendarEvent> _expandRecurrence(_CalendarEvent base) {
    final List<_CalendarEvent> list = [base];
    Duration step;
    int occurrences = base.recurrenceCount ?? 3; // default fallback
    switch (base.recurrence) {
      case 'Täglich':
        step = const Duration(days: 1);
        break;
      case 'Wöchentlich':
        step = const Duration(days: 7);
        break;
      case 'Monatlich':
        // approximate by 30 days for demo
        step = const Duration(days: 30);
        break;
      default:
        return list;
    }

    int added = 0;
    DateTime nextStart = base.start.add(step);
    DateTime nextEnd = base.end.add(step);

    bool useCount = base.recurrenceEndMode.contains('Termine');
    bool useDate = base.recurrenceEndMode == 'Datum wählen';
    final endDate = base.recurrenceEndDate;

    while (true) {
      if (useCount && added >= (occurrences - 1)) break;
      if (useDate && endDate != null && nextStart.isAfter(endDate)) break;
      list.add(
        base.copyWith(
          id: '${base.id}_$added',
          start: nextStart,
          end: nextEnd,
        ),
      );
      added++;
      nextStart = nextStart.add(step);
      nextEnd = nextEnd.add(step);

      // falls weder Datum noch Count explizit: wenige Events erzeugen
      if (!useCount && !useDate && added >= 4) break;
    }
    return list;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<_CalendarEvent> get _eventsForSelectedDay {
    return _events
        .where((e) => _isSameDay(e.start, _selectedDay))
        .where((e) => _filterPerson == 'Alle' || e.person == _filterPerson)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  int _countEventsForDay(DateTime day) {
    return _events
        .where((e) => _isSameDay(e.start, day))
        .where((e) => _filterPerson == 'Alle' || e.person == _filterPerson)
        .length;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _focusedDay = DateTime(day.year, day.month, 1);
    });
  }

  Future<void> _openAddSheet() async {
    _titleController.clear();
    String person = 'Eltern';
    TimeOfDay start = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 11, minute: 0);
    String recurrence = 'Einmalig';
    int reminder = _smartReminderValue;
    String endMode = _recurrenceEndMode;
    DateTime? endDate =
        _recurrenceEndDate ?? _selectedDay.add(const Duration(days: 30));
    int endCount = _recurrenceCount;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Neuer Termin',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    hintText: 'z.B. Elternabend',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: person,
                  decoration: const InputDecoration(labelText: 'Für wen?'),
                  items: _personColors.keys
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) person = v;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimeButton(
                        label: 'Start',
                        initial: start,
                        onPicked: (t) => start = t,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeButton(
                        label: 'Ende',
                        initial: end,
                        onPicked: (t) => end = t,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: recurrence,
                  decoration: const InputDecoration(labelText: 'Wiederholung'),
                  items: _recurrenceOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) recurrence = v;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: reminder,
                  decoration: const InputDecoration(labelText: 'Erinnerung'),
                  items: _reminderOptions
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m == _smartReminderValue
                                  ? 'Smart: 1 Woche, 1 Tag, am Termin'
                                  : m == 0
                                      ? 'Keine'
                                      : '$m Min vorher',
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) reminder = v;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: endMode,
                  decoration: const InputDecoration(labelText: 'Endet'),
                  items: _recurrenceEndOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) endMode = v;
                    if (endMode == '5 Termine') endCount = 5;
                    if (endMode == '10 Termine') endCount = 10;
                  },
                ),
                if (endMode == 'Datum wählen') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: endDate ?? _selectedDay,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        endDate = picked;
                        // ignore: use_build_context_synchronously
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text(endDate == null
                        ? 'Enddatum wählen'
                        : 'Endet am ${DateFormat.yMMMd('de').format(endDate!)}'),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Speichern'),
                    onPressed: () async {
                      if (_titleController.text.trim().isEmpty) return;
                      final startDate = DateTime(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                        start.hour,
                        start.minute,
                      );
                      final endDate = DateTime(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                        end.hour,
                        end.minute,
                      );
                      final base = _CalendarEvent(
                        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
                        title: _titleController.text.trim(),
                        start: startDate,
                        end: endDate.isAfter(startDate)
                            ? endDate
                            : startDate.add(const Duration(hours: 1)),
                        person: person,
                        location: 'Familienkalender',
                        recurrence: recurrence,
                        reminderMinutes: reminder,
                        recurrenceEndMode: endMode,
                        recurrenceEndDate:
                            endMode == 'Datum wählen' ? endDate : null,
                        recurrenceCount:
                            endMode.contains('Termine') ? endCount : null,
                      );
                      final expanded = _expandRecurrence(base);
                      try {
                        for (final e in expanded) {
                          await _calendarService.addEvent(e.toJson());
                        }
                      } catch (_) {
                        if (!mounted) return;
                        setState(() {
                          _syncError = _calendarService.lastSyncError;
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _syncError ?? 'Termin konnte nicht gespeichert werden.',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _events.addAll(expanded);
                        _syncError = _calendarService.lastSyncError;
                      });
                      _scheduleRemindersFor(expanded);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDevelopmentFallback() async {
    await ProductMetricsService.instance.recordCalendarFallbackRouteTap(
      from: 'calendar',
      to: 'development',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EntwicklungImpulseScreen(initialTabIndex: 1),
      ),
    );
  }

  Future<void> _openChatFallback() async {
    await ProductMetricsService.instance.recordCalendarFallbackRouteTap(
      from: 'calendar',
      to: 'chat',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthTitle = DateFormat.yMMMM('de').format(_focusedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      appBar: AppBar(
        title: const Text('Kalender'),
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Familienkalender',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D3748)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: _loadEvents,
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    if (_syncError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Material(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_off_rounded),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Server-Sync fehlgeschlagen',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadEvents,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(_syncError!),
                                const SizedBox(height: 8),
                                const Text(
                                  'Du kannst ohne Wartezeit weitermachen:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _openDevelopmentFallback,
                                      icon: const Icon(Icons.insights_rounded),
                                      label: const Text('Zu Entwicklung'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _openChatFallback,
                                      icon: const Icon(Icons.tips_and_updates_rounded),
                                      label: const Text('Zur KI-Beratung'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                monthTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('Alle'),
                        ..._personColors.keys.map(_buildFilterChip),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MonthGrid(
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      onSelectDay: _selectDay,
                      eventCounter: _countEventsForDay,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          DateFormat.EEEE('de').add_d().format(_selectedDay),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _eventsForSelectedDay.isEmpty
                              ? 'Keine Termine'
                              : '${_eventsForSelectedDay.length} Termine',
                          style: const TextStyle(color: Color(0xFF718096)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._eventsForSelectedDay.map((e) => _EventCard(
                        event: e,
                        color: _personColors[e.person] ??
                            theme.colorScheme.primary)),
                    if (_eventsForSelectedDay.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keine Termine an diesem Tag',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF2D3748)),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Füge einen neuen Termin hinzu und teile ihn mit deiner Familie.',
                              style: TextStyle(color: Color(0xFF718096)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Termin'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _filterPerson == label;
    final color = label == 'Alle'
        ? const Color(0xFF2D3748)
        : _personColors[label] ?? const Color(0xFF4CAF50);
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? color : const Color(0xFF4A5568),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (_) => setState(() => _filterPerson = label),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.focusedDay,
    required this.selectedDay,
    required this.onSelectDay,
    required this.eventCounter,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final void Function(DateTime day) onSelectDay;
  final int Function(DateTime day) eventCounter;

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysBefore = first.weekday % 7; // Monday = 1
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final List<DateTime> days = [];
    for (int i = 0; i < daysBefore; i++) {
      days.add(first.subtract(Duration(days: daysBefore - i)));
    }
    for (int i = 0; i < daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(focusedDay);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mo'),
              Text('Di'),
              Text('Mi'),
              Text('Do'),
              Text('Fr'),
              Text('Sa'),
              Text('So'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (_, i) {
              final day = days[i];
              final isCurrentMonth = day.month == focusedDay.month;
              final isSelected = _isSameDay(day, selectedDay);
              final isToday = _isSameDay(day, now);
              final eventCount = eventCounter(day);

              Color textColor = const Color(0xFF4A5568);
              if (!isCurrentMonth) textColor = Colors.grey[400]!;
              if (isSelected) textColor = Colors.white;

              return GestureDetector(
                onTap: () => onSelectDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : isToday
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : isToday
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                              : Colors.grey[200]!,
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compactTile = constraints.maxHeight < 44;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          if (eventCount > 0) ...[
                            SizedBox(height: compactTile ? 2 : 4),
                            compactTile
                                ? Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : const Color(0xFF4CAF50)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$eventCount',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF2D3748),
                                      ),
                                    ),
                                  ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.color});

  final _CalendarEvent event;
  final Color color;

  String _fmt(DateTime dt) {
    return DateFormat.Hm('de').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 110,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.person,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_fmt(event.start)} - ${_fmt(event.end)}',
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (event.recurrence != 'Einmalig')
                          _Badge(
                            label: event.recurrence,
                            color: color,
                            icon: Icons.loop_rounded,
                          ),
                        if (event.reminderMinutes == _CalendarScreenState._smartReminderValue)
                          const _Badge(
                            label: 'Smart: 1W • 1T • Heute',
                            color: Color(0xFF5B7FFF),
                            icon: Icons.auto_awesome_rounded,
                          ),
                        if (event.reminderMinutes > 0)
                          _Badge(
                            label: '${event.reminderMinutes} Min vorher',
                            color: const Color(0xFF718096),
                            icon: Icons.alarm_rounded,
                          ),
                        if (event.recurrenceEndMode.contains('Termine') &&
                            event.recurrenceCount != null)
                          _Badge(
                            label:
                                'Endet nach ${event.recurrenceCount} Terminen',
                            color: const Color(0xFF718096),
                            icon: Icons.flag_rounded,
                          ),
                        if (event.recurrenceEndMode == 'Datum wählen' &&
                            event.recurrenceEndDate != null)
                          _Badge(
                            label:
                                'Endet ${DateFormat.yMMMd('de').format(event.recurrenceEndDate!)}',
                            color: const Color(0xFF718096),
                            icon: Icons.event_available_rounded,
                          ),
                      ],
                    ),
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 16, color: Color(0xFF718096)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: const TextStyle(color: Color(0xFF4A5568)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String person;
  final String? location;
  final bool allDay;
  final String recurrence;
  final int reminderMinutes;
  final String recurrenceEndMode;
  final DateTime? recurrenceEndDate;
  final int? recurrenceCount;

  _CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.person,
    this.location,
    this.allDay = false,
    this.recurrence = 'Einmalig',
    this.reminderMinutes = 0,
    this.recurrenceEndMode = 'Kein Ende',
    this.recurrenceEndDate,
    this.recurrenceCount,
  });

  _CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    String? person,
    String? location,
    bool? allDay,
    String? recurrence,
    int? reminderMinutes,
    String? recurrenceEndMode,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
  }) {
    return _CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      person: person ?? this.person,
      location: location ?? this.location,
      allDay: allDay ?? this.allDay,
      recurrence: recurrence ?? this.recurrence,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      recurrenceEndMode: recurrenceEndMode ?? this.recurrenceEndMode,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
    );
  }

  factory _CalendarEvent.fromJson(Map<String, dynamic> json) {
    final start =
      DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now();
    final person = json['person']?.toString() ?? 'Eltern';
    final title = json['title']?.toString() ?? '';
    final fallbackId =
      'legacy_${start.millisecondsSinceEpoch}_${title.hashCode}_${person.hashCode}';

    return _CalendarEvent(
      id: json['id']?.toString() ?? fallbackId,
      title: title,
      start: start,
      end: DateTime.tryParse(json['end']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      person: person,
      location: json['location']?.toString(),
      allDay: json['allDay'] == true,
      recurrence: json['recurrence']?.toString() ?? 'Einmalig',
      reminderMinutes:
        (json['reminderMinutes'] as num?)?.toInt() ?? _CalendarScreenState._smartReminderValue,
      recurrenceEndMode: json['recurrenceEndMode']?.toString() ?? 'Kein Ende',
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.tryParse(json['recurrenceEndDate'].toString())
          : null,
      recurrenceCount: (json['recurrenceCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'person': person,
      'location': location,
      'allDay': allDay,
      'recurrence': recurrence,
      'reminderMinutes': reminderMinutes,
      'recurrenceEndMode': recurrenceEndMode,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceCount': recurrenceCount,
    };
  }
}

extension on _CalendarScreenState {
  Future<void> _scheduleRemindersFor(List<_CalendarEvent> events) async {
    for (final event in events) {
      final body = '${event.person}: ${DateFormat.Hm('de').format(event.start)}';

      if (event.reminderMinutes == _CalendarScreenState._smartReminderValue) {
        await NotificationService.instance.scheduleStandardCalendarReminders(
          eventId: event.id,
          eventStart: event.start,
          title: event.title,
          body: body,
        );
        continue;
      }

      if (event.reminderMinutes > 0) {
        final when = event.start.subtract(Duration(minutes: event.reminderMinutes));
        await NotificationService.instance.scheduleEventReminder(
          eventId: event.id,
          when: when,
          title: event.title,
          body: body,
          reminderKey: 'custom_${event.reminderMinutes}',
        );
      }
    }
  }
}

class _TimeButton extends StatefulWidget {
  const _TimeButton(
      {required this.label, required this.initial, required this.onPicked});

  final String label;
  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onPicked;

  @override
  State<_TimeButton> createState() => _TimeButtonState();
}

class _TimeButtonState extends State<_TimeButton> {
  late TimeOfDay _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24))),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _value = picked);
      widget.onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _pick,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.label,
            style: const TextStyle(color: Color(0xFF4A5568)),
          ),
          Text(
            _value.format(context),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
          ),
        ],
      ),
    );
  }
}

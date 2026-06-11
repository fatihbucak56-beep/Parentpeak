class FamilyCalendarEvent {
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

  const FamilyCalendarEvent({
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

  FamilyCalendarEvent copyWith({
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
    return FamilyCalendarEvent(
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

  factory FamilyCalendarEvent.fromJson(Map<String, dynamic> json) {
    return FamilyCalendarEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      start: DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      person: json['person']?.toString() ?? 'Eltern',
      location: json['location']?.toString(),
      allDay: json['allDay'] == true,
      recurrence: json['recurrence']?.toString() ?? 'Einmalig',
      reminderMinutes: (json['reminderMinutes'] as num?)?.toInt() ?? 0,
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

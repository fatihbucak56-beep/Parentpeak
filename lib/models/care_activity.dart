enum CareActivityType {
  childSickCare,
  kindergartenOrganization,
  householdCare,
  appointmentCoordination,
  emotionalSupport,
  other,
}

class CareActivity {
  const CareActivity({
    required this.id,
    required this.parentId,
    required this.activityType,
    required this.durationHours,
    required this.financialCreditValue,
    required this.date,
    this.note,
  });

  final String id;
  final String parentId;
  final CareActivityType activityType;
  final double durationHours;
  final double financialCreditValue;
  final DateTime date;
  final String? note;

  CareActivity copyWith({
    String? id,
    String? parentId,
    CareActivityType? activityType,
    double? durationHours,
    double? financialCreditValue,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) {
    return CareActivity(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      activityType: activityType ?? this.activityType,
      durationHours: durationHours ?? this.durationHours,
      financialCreditValue: financialCreditValue ?? this.financialCreditValue,
      date: date ?? this.date,
      note: clearNote ? null : note ?? this.note,
    );
  }

  factory CareActivity.fromMap(Map<String, dynamic> map) {
    return CareActivity(
      id: map['id']?.toString() ?? '',
      parentId: map['parentId']?.toString() ?? '',
      activityType: CareActivityType.values.firstWhere(
        (item) => item.name == map['activityType']?.toString(),
        orElse: () => CareActivityType.other,
      ),
      durationHours: (map['durationHours'] as num?)?.toDouble() ?? 0,
      financialCreditValue:
          (map['financialCreditValue'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      note: map['note']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'activityType': activityType.name,
      'durationHours': durationHours,
      'financialCreditValue': financialCreditValue,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}

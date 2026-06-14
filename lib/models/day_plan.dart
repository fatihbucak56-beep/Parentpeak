class DayPlan {
  final DateTime date;
  final String? dinnerRecipeId;
  final String kitaLunch;
  final bool isChaosDay;
  final String? leftoverCode;

  const DayPlan({
    required this.date,
    required this.dinnerRecipeId,
    required this.kitaLunch,
    required this.isChaosDay,
    required this.leftoverCode,
  });

  DayPlan copyWith({
    DateTime? date,
    String? dinnerRecipeId,
    bool clearDinnerRecipeId = false,
    String? kitaLunch,
    bool? isChaosDay,
    String? leftoverCode,
    bool clearLeftoverCode = false,
  }) {
    return DayPlan(
      date: date ?? this.date,
      dinnerRecipeId:
          clearDinnerRecipeId ? null : (dinnerRecipeId ?? this.dinnerRecipeId),
      kitaLunch: kitaLunch ?? this.kitaLunch,
      isChaosDay: isChaosDay ?? this.isChaosDay,
      leftoverCode: clearLeftoverCode ? null : (leftoverCode ?? this.leftoverCode),
    );
  }

  factory DayPlan.fromMap(Map<String, dynamic> map) {
    return DayPlan(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      dinnerRecipeId: map['dinnerRecipeId']?.toString(),
      kitaLunch: map['kitaLunch']?.toString() ?? '',
      isChaosDay: map['isChaosDay'] == true,
      leftoverCode: map['leftoverCode']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'dinnerRecipeId': dinnerRecipeId,
      'kitaLunch': kitaLunch,
      'isChaosDay': isChaosDay,
      'leftoverCode': leftoverCode,
    };
  }
}
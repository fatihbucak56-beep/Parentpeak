class CookingHub {
  final String id;
  final String hubName;
  final List<String> memberUserIds;
  final Map<String, String> weeklyRotationalPlanner;
  final Map<String, Map<String, String>> weeklyRotationHistoryByWeekStart;
  final Map<String, int> fairnessCookCountByUserId;
  final Map<String, List<String>> childAllergiesByUserId;
  final Map<String, List<String>> childPreferencesByUserId;

  const CookingHub({
    required this.id,
    required this.hubName,
    required this.memberUserIds,
    required this.weeklyRotationalPlanner,
    this.weeklyRotationHistoryByWeekStart = const {},
    this.fairnessCookCountByUserId = const {},
    this.childAllergiesByUserId = const {},
    this.childPreferencesByUserId = const {},
  });

  CookingHub copyWith({
    String? id,
    String? hubName,
    List<String>? memberUserIds,
    Map<String, String>? weeklyRotationalPlanner,
    Map<String, Map<String, String>>? weeklyRotationHistoryByWeekStart,
    Map<String, int>? fairnessCookCountByUserId,
    Map<String, List<String>>? childAllergiesByUserId,
    Map<String, List<String>>? childPreferencesByUserId,
  }) {
    return CookingHub(
      id: id ?? this.id,
      hubName: hubName ?? this.hubName,
      memberUserIds: memberUserIds ?? this.memberUserIds,
      weeklyRotationalPlanner: weeklyRotationalPlanner ?? this.weeklyRotationalPlanner,
      weeklyRotationHistoryByWeekStart:
          weeklyRotationHistoryByWeekStart ?? this.weeklyRotationHistoryByWeekStart,
      fairnessCookCountByUserId:
          fairnessCookCountByUserId ?? this.fairnessCookCountByUserId,
      childAllergiesByUserId: childAllergiesByUserId ?? this.childAllergiesByUserId,
      childPreferencesByUserId: childPreferencesByUserId ?? this.childPreferencesByUserId,
    );
  }

  factory CookingHub.fromMap(Map<String, dynamic> map) {
    final memberRaw = map['memberUserIds'];
    final memberIds = <String>[];
    if (memberRaw is List) {
      for (final item in memberRaw) {
        final value = item.toString().trim();
        if (value.isNotEmpty) {
          memberIds.add(value);
        }
      }
    }

    Map<String, List<String>> parseNestedStringList(dynamic source) {
      final result = <String, List<String>>{};
      if (source is! Map) return result;

      source.forEach((key, value) {
        if (value is List) {
          result[key.toString()] = value.map((item) => item.toString()).toList();
        }
      });
      return result;
    }

    final planner = <String, String>{};
    final plannerRaw = map['weeklyRotationalPlanner'];
    if (plannerRaw is Map) {
      plannerRaw.forEach((key, value) {
        planner[key.toString()] = value.toString();
      });
    }

    final history = <String, Map<String, String>>{};
    final historyRaw = map['weeklyRotationHistoryByWeekStart'];
    if (historyRaw is Map) {
      historyRaw.forEach((weekKey, plannerValue) {
        if (plannerValue is Map) {
          final weekPlanner = <String, String>{};
          plannerValue.forEach((dayKey, assignedUser) {
            weekPlanner[dayKey.toString()] = assignedUser.toString();
          });
          history[weekKey.toString()] = weekPlanner;
        }
      });
    }

    final fairness = <String, int>{};
    final fairnessRaw = map['fairnessCookCountByUserId'];
    if (fairnessRaw is Map) {
      fairnessRaw.forEach((key, value) {
        if (value is num) {
          fairness[key.toString()] = value.toInt();
        }
      });
    }

    return CookingHub(
      id: map['id']?.toString() ?? '',
      hubName: map['hubName']?.toString() ?? '',
      memberUserIds: memberIds,
      weeklyRotationalPlanner: planner,
      weeklyRotationHistoryByWeekStart: history,
      fairnessCookCountByUserId: fairness,
      childAllergiesByUserId: parseNestedStringList(map['childAllergiesByUserId']),
      childPreferencesByUserId: parseNestedStringList(map['childPreferencesByUserId']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hubName': hubName,
      'memberUserIds': memberUserIds,
      'weeklyRotationalPlanner': weeklyRotationalPlanner,
      'weeklyRotationHistoryByWeekStart': weeklyRotationHistoryByWeekStart,
      'fairnessCookCountByUserId': fairnessCookCountByUserId,
      'childAllergiesByUserId': childAllergiesByUserId,
      'childPreferencesByUserId': childPreferencesByUserId,
    };
  }
}

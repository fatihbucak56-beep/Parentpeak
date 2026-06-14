class LocalHelpProfile {
  const LocalHelpProfile({
    required this.userId,
    required this.displayName,
    required this.optedInForKitchenSos,
    required this.maxSupportRadiusMeters,
    required this.trustedByUserIds,
  });

  final String userId;
  final String displayName;
  final bool optedInForKitchenSos;
  final double maxSupportRadiusMeters;
  final List<String> trustedByUserIds;

  bool isTrustedBy(String userId) {
    return trustedByUserIds.contains(userId);
  }

  factory LocalHelpProfile.fromMap(Map<String, dynamic> map) {
    final trustedRaw = map['trustedByUserIds'];
    final trusted = <String>[];
    if (trustedRaw is List) {
      for (final item in trustedRaw) {
        final value = item.toString().trim();
        if (value.isNotEmpty) {
          trusted.add(value);
        }
      }
    }

    return LocalHelpProfile(
      userId: map['userId']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      optedInForKitchenSos: map['optedInForKitchenSos'] == true,
      maxSupportRadiusMeters: (map['maxSupportRadiusMeters'] as num?)?.toDouble() ?? 500,
      trustedByUserIds: trusted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'optedInForKitchenSos': optedInForKitchenSos,
      'maxSupportRadiusMeters': maxSupportRadiusMeters,
      'trustedByUserIds': trustedByUserIds,
    };
  }
}

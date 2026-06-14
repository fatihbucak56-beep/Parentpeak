enum KitchenSosResponseStatus {
  pending,
  accepted,
  enRoute,
  resolved,
}

class KitchenSosResponse {
  const KitchenSosResponse({
    required this.sosId,
    required this.responderUserId,
    required this.status,
    this.etaMinutes,
    required this.updatedAt,
  });

  final String sosId;
  final String responderUserId;
  final KitchenSosResponseStatus status;
  final int? etaMinutes;
  final DateTime updatedAt;

  KitchenSosResponse copyWith({
    String? sosId,
    String? responderUserId,
    KitchenSosResponseStatus? status,
    int? etaMinutes,
    bool clearEtaMinutes = false,
    DateTime? updatedAt,
  }) {
    return KitchenSosResponse(
      sosId: sosId ?? this.sosId,
      responderUserId: responderUserId ?? this.responderUserId,
      status: status ?? this.status,
      etaMinutes: clearEtaMinutes ? null : etaMinutes ?? this.etaMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory KitchenSosResponse.fromMap(Map<String, dynamic> map) {
    return KitchenSosResponse(
      sosId: map['sosId']?.toString() ?? '',
      responderUserId: map['responderUserId']?.toString() ?? '',
      status: KitchenSosResponseStatus.values.firstWhere(
        (item) => item.name == map['status']?.toString(),
        orElse: () => KitchenSosResponseStatus.pending,
      ),
      etaMinutes: (map['etaMinutes'] as num?)?.toInt(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sosId': sosId,
      'responderUserId': responderUserId,
      'status': status.name,
      'etaMinutes': etaMinutes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

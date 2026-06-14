enum KitchenSosStatus {
  active,
  resolved,
}

class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory GeoCoordinates.fromMap(Map<String, dynamic> map) {
    return GeoCoordinates(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class KitchenSos {
  final String id;
  final String senderId;
  final GeoCoordinates geoCoordinates;
  final KitchenSosStatus status;
  final String? resolvedById;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const KitchenSos({
    required this.id,
    required this.senderId,
    required this.geoCoordinates,
    required this.status,
    this.resolvedById,
    required this.createdAt,
    this.resolvedAt,
  });

  KitchenSos copyWith({
    String? id,
    String? senderId,
    GeoCoordinates? geoCoordinates,
    KitchenSosStatus? status,
    String? resolvedById,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return KitchenSos(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      geoCoordinates: geoCoordinates ?? this.geoCoordinates,
      status: status ?? this.status,
      resolvedById: resolvedById ?? this.resolvedById,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  factory KitchenSos.fromMap(Map<String, dynamic> map) {
    return KitchenSos(
      id: map['id']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      geoCoordinates: GeoCoordinates.fromMap(
        Map<String, dynamic>.from(map['geoCoordinates'] as Map? ?? const {}),
      ),
      status: (map['status']?.toString() ?? '') == 'resolved'
          ? KitchenSosStatus.resolved
          : KitchenSosStatus.active,
      resolvedById: map['resolvedById']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: DateTime.tryParse(map['resolvedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'geoCoordinates': geoCoordinates.toMap(),
      'status': status.name,
      'resolvedById': resolvedById,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}

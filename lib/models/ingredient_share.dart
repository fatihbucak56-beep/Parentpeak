import 'package:parentpeak/models/kitchen_sos.dart';

enum IngredientShareStatus {
  available,
  reserved,
}

class IngredientShare {
  const IngredientShare({
    required this.id,
    required this.userId,
    required this.ingredientName,
    required this.status,
    required this.geoHash,
    required this.location,
    this.note,
  });

  final String id;
  final String userId;
  final String ingredientName;
  final IngredientShareStatus status;
  final String geoHash;
  final GeoCoordinates location;
  final String? note;

  bool get isAvailable => status == IngredientShareStatus.available;

  IngredientShare copyWith({
    String? id,
    String? userId,
    String? ingredientName,
    IngredientShareStatus? status,
    String? geoHash,
    GeoCoordinates? location,
    String? note,
  }) {
    return IngredientShare(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ingredientName: ingredientName ?? this.ingredientName,
      status: status ?? this.status,
      geoHash: geoHash ?? this.geoHash,
      location: location ?? this.location,
      note: note ?? this.note,
    );
  }

  factory IngredientShare.fromMap(Map<String, dynamic> map) {
    return IngredientShare(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      ingredientName: map['ingredientName']?.toString() ?? '',
      status: map['status']?.toString() == IngredientShareStatus.reserved.name
          ? IngredientShareStatus.reserved
          : IngredientShareStatus.available,
      geoHash: map['geoHash']?.toString() ?? '',
      location: GeoCoordinates.fromMap(
        Map<String, dynamic>.from(map['location'] as Map? ?? const {}),
      ),
      note: map['note']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'ingredientName': ingredientName,
      'status': status.name,
      'geoHash': geoHash,
      'location': location.toMap(),
      'note': note,
    };
  }
}

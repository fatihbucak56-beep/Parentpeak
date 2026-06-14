class MealMemory {
  final String id;
  final DateTime date;
  final String? recipeId;
  final String note;
  final String? photoPath;

  const MealMemory({
    required this.id,
    required this.date,
    required this.recipeId,
    required this.note,
    required this.photoPath,
  });

  MealMemory copyWith({
    String? id,
    DateTime? date,
    String? recipeId,
    bool clearRecipeId = false,
    String? note,
    String? photoPath,
    bool clearPhotoPath = false,
  }) {
    return MealMemory(
      id: id ?? this.id,
      date: date ?? this.date,
      recipeId: clearRecipeId ? null : (recipeId ?? this.recipeId),
      note: note ?? this.note,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
    );
  }

  factory MealMemory.fromMap(Map<String, dynamic> map) {
    return MealMemory(
      id: map['id']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      recipeId: map['recipeId']?.toString(),
      note: map['note']?.toString() ?? '',
      photoPath: map['photoPath']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'recipeId': recipeId,
      'note': note,
      'photoPath': photoPath,
    };
  }
}
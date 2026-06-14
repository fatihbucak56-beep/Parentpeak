class RecipeIngredient {
  final String name;
  final String amount;
  final String? babyOption;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    this.babyOption,
  });

  RecipeIngredient copyWith({
    String? name,
    String? amount,
    String? babyOption,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      babyOption: babyOption ?? this.babyOption,
    );
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['name']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '',
      babyOption: map['babyOption']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'babyOption': babyOption,
    };
  }
}

class Recipe {
  final String id;
  final String title;
  final List<RecipeIngredient> ingredients;
  final int durationMinutes;
  final bool isPickEaterFriendly;
  final bool isOnePot;
  final bool hideVegetables;

  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.durationMinutes,
    required this.isPickEaterFriendly,
    required this.isOnePot,
    required this.hideVegetables,
  });

  Recipe copyWith({
    String? id,
    String? title,
    List<RecipeIngredient>? ingredients,
    int? durationMinutes,
    bool? isPickEaterFriendly,
    bool? isOnePot,
    bool? hideVegetables,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isPickEaterFriendly: isPickEaterFriendly ?? this.isPickEaterFriendly,
      isOnePot: isOnePot ?? this.isOnePot,
      hideVegetables: hideVegetables ?? this.hideVegetables,
    );
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    final rawIngredients = map['ingredients'];
    final parsedIngredients = <RecipeIngredient>[];

    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is Map) {
          parsedIngredients.add(
            RecipeIngredient.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return Recipe(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      ingredients: parsedIngredients,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      isPickEaterFriendly: map['isPickEaterFriendly'] == true,
      isOnePot: map['isOnePot'] == true,
      hideVegetables: map['hideVegetables'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients.map((item) => item.toMap()).toList(),
      'durationMinutes': durationMinutes,
      'isPickEaterFriendly': isPickEaterFriendly,
      'isOnePot': isOnePot,
      'hideVegetables': hideVegetables,
    };
  }
}
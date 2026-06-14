import 'package:trusted_circle_demo/models/recipe.dart';

class AiTarnStep {
  final String hiddenIngredient;
  final String camouflageMethod;
  final String textureHint;
  final String colorHint;

  const AiTarnStep({
    required this.hiddenIngredient,
    required this.camouflageMethod,
    required this.textureHint,
    required this.colorHint,
  });

  factory AiTarnStep.fromMap(Map<String, dynamic> map) {
    return AiTarnStep(
      hiddenIngredient: map['hiddenIngredient']?.toString() ?? '',
      camouflageMethod: map['camouflageMethod']?.toString() ?? '',
      textureHint: map['textureHint']?.toString() ?? '',
      colorHint: map['colorHint']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hiddenIngredient': hiddenIngredient,
      'camouflageMethod': camouflageMethod,
      'textureHint': textureHint,
      'colorHint': colorHint,
    };
  }
}

class GuerillaRecipe extends Recipe {
  final Map<String, AiTarnStep> aiTarnMapping;

  const GuerillaRecipe({
    required super.id,
    required super.title,
    required super.ingredients,
    required super.durationMinutes,
    required super.isPickEaterFriendly,
    required super.isOnePot,
    required super.hideVegetables,
    required this.aiTarnMapping,
  });

  factory GuerillaRecipe.fromMap(Map<String, dynamic> map) {
    final base = Recipe.fromMap(map);
    final mapping = <String, AiTarnStep>{};
    final raw = map['aiTarnMapping'];

    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          mapping[key.toString()] = AiTarnStep.fromMap(Map<String, dynamic>.from(value));
        }
      });
    }

    return GuerillaRecipe(
      id: base.id,
      title: base.title,
      ingredients: base.ingredients,
      durationMinutes: base.durationMinutes,
      isPickEaterFriendly: base.isPickEaterFriendly,
      isOnePot: base.isOnePot,
      hideVegetables: base.hideVegetables,
      aiTarnMapping: mapping,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['aiTarnMapping'] = aiTarnMapping.map((key, value) => MapEntry(key, value.toMap()));
    return map;
  }
}

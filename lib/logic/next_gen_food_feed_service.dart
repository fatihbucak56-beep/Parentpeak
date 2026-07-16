import 'dart:math' as math;

import 'package:parentpeak/logic/kettenbrecher_service.dart';
import 'package:parentpeak/models/audio_hack.dart';
import 'package:parentpeak/models/community_snack.dart';
import 'package:parentpeak/models/ingredient_share.dart';
import 'package:parentpeak/models/kitchen_sos.dart';
import 'package:parentpeak/models/recipe.dart';

class NextGenFoodFeedService {
  const NextGenFoodFeedService({KettenbrecherService? kettenbrecherService})
      : _kettenbrecherService = kettenbrecherService ?? const KettenbrecherService();

  final KettenbrecherService _kettenbrecherService;

  Recipe recipeFromSnack({
    required CommunitySnack snack,
    required List<Recipe> recipes,
  }) {
    return recipes.firstWhere(
      (recipe) => recipe.id == snack.linkedRecipeId,
      orElse: () => recipes.first,
    );
  }

  List<AudioHack> orderedAudioHacksForRecipe({
    required String recipeId,
    required List<AudioHack> allAudioHacks,
  }) {
    final filtered = allAudioHacks.where((item) => item.recipeId == recipeId).toList();
    filtered.sort((a, b) => b.upvotes.compareTo(a.upvotes));
    return filtered;
  }

  List<IngredientShare> findIngredientSharesForWeeklyPlan({
    required List<Recipe> weeklyPlan,
    required List<IngredientShare> allShares,
    required GeoCoordinates center,
    double radiusMeters = 2000,
  }) {
    final needed = <String>{};
    for (final recipe in weeklyPlan) {
      for (final ingredient in recipe.ingredients) {
        final key = ingredient.name.trim().toLowerCase();
        if (key.isNotEmpty) needed.add(key);
      }
    }

    return allShares.where((share) {
      if (!share.isAvailable) return false;
      final key = share.ingredientName.trim().toLowerCase();
      if (!needed.contains(key)) return false;
      final distance = _kettenbrecherService.distanceMeters(center, share.location);
      return distance <= radiusMeters;
    }).toList()
      ..sort((a, b) {
        final aDistance = _kettenbrecherService.distanceMeters(center, a.location);
        final bDistance = _kettenbrecherService.distanceMeters(center, b.location);
        return aDistance.compareTo(bDistance);
      });
  }

  int estimateCommunityReachScore(CommunitySnack snack) {
    final base = snack.viewsCount ~/ 10;
    return math.max(1, base + snack.likesCount);
  }
}

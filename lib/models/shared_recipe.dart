import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/models/food_share_post.dart';

enum RecipeDifficulty { einfach, mittel, fortgeschritten }

class SharedRecipe {
  final String id;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final Color authorColor;
  final String title;
  final String description;
  final String imageEmoji;
  final int durationMinutes;
  final RecipeDifficulty difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> tags; // e.g. ['vegan', 'schnell', 'baby-geeignet']
  final List<String> likedByUserIds;
  final List<FoodShareComment> comments;
  final bool isSavedByMe;
  final DateTime createdAt;

  const SharedRecipe({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorColor,
    required this.title,
    required this.description,
    required this.imageEmoji,
    required this.durationMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    this.tags = const [],
    this.likedByUserIds = const [],
    this.comments = const [],
    this.isSavedByMe = false,
    required this.createdAt,
  });

  String get difficultyLabel {
    switch (difficulty) {
      case RecipeDifficulty.einfach:
        return 'Einfach';
      case RecipeDifficulty.mittel:
        return 'Mittel';
      case RecipeDifficulty.fortgeschritten:
        return 'Fortgeschritten';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case RecipeDifficulty.einfach:
        return const Color(0xFF16A34A);
      case RecipeDifficulty.mittel:
        return const Color(0xFFF59E0B);
      case RecipeDifficulty.fortgeschritten:
        return const Color(0xFFE8543A);
    }
  }

  SharedRecipe copyWith({
    List<String>? likedByUserIds,
    List<FoodShareComment>? comments,
    bool? isSavedByMe,
  }) {
    return SharedRecipe(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorInitials: authorInitials,
      authorColor: authorColor,
      title: title,
      description: description,
      imageEmoji: imageEmoji,
      durationMinutes: durationMinutes,
      difficulty: difficulty,
      ingredients: ingredients,
      steps: steps,
      tags: tags,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      comments: comments ?? this.comments,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      createdAt: createdAt,
    );
  }
}

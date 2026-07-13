import 'package:flutter/material.dart';

/// Represents a shared meal post from a parent
class FoodSharePost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final Color authorColor;
  final String title;
  final String description;
  final int totalPortions;
  final int remainingPortions;
  final String pickupWindow; // e.g. "Heute 17:00 - 19:00 Uhr"
  final double distanceKm;
  final DateTime createdAt;
  final List<String> likedByUserIds;
  final List<FoodShareComment> comments;
  final String? imageEmoji; // placeholder for real images
  final bool isReservedByMe;

  const FoodSharePost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorColor,
    required this.title,
    required this.description,
    required this.totalPortions,
    required this.remainingPortions,
    required this.pickupWindow,
    required this.distanceKm,
    required this.createdAt,
    this.likedByUserIds = const [],
    this.comments = const [],
    this.imageEmoji,
    this.isReservedByMe = false,
  });

  bool get isAvailable => remainingPortions > 0;

  FoodSharePost copyWith({
    List<String>? likedByUserIds,
    List<FoodShareComment>? comments,
    int? remainingPortions,
    bool? isReservedByMe,
  }) {
    return FoodSharePost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorInitials: authorInitials,
      authorColor: authorColor,
      title: title,
      description: description,
      totalPortions: totalPortions,
      remainingPortions: remainingPortions ?? this.remainingPortions,
      pickupWindow: pickupWindow,
      distanceKm: distanceKm,
      createdAt: createdAt,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      comments: comments ?? this.comments,
      imageEmoji: imageEmoji,
      isReservedByMe: isReservedByMe ?? this.isReservedByMe,
    );
  }
}

class FoodShareComment {
  final String id;
  final String authorName;
  final String authorInitials;
  final Color authorColor;
  final String text;
  final DateTime createdAt;

  const FoodShareComment({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.authorColor,
    required this.text,
    required this.createdAt,
  });
}

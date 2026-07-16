import 'package:flutter/material.dart';

enum MealType { breakfast, lunch, snack, dinner }

extension MealTypeLabel on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Frühstück';
      case MealType.lunch:
        return 'Mittagessen';
      case MealType.snack:
        return 'Snack';
      case MealType.dinner:
        return 'Abendessen';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🥐';
      case MealType.lunch:
        return '🍽️';
      case MealType.snack:
        return '🍎';
      case MealType.dinner:
        return '🍜';
    }
  }

  Color get color {
    switch (this) {
      case MealType.breakfast:
        return const Color(0xFFF59E0B);
      case MealType.lunch:
        return const Color(0xFF3B82F6);
      case MealType.snack:
        return const Color(0xFF10B981);
      case MealType.dinner:
        return const Color(0xFFE8543A);
    }
  }
}

class Meal {
  final String id;
  final String title;
  final MealType type;
  final String? description;
  final List<String> ingredients;

  const Meal({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.ingredients = const [],
  });

  Meal copyWith({
    String? id,
    String? title,
    MealType? type,
    String? description,
    List<String>? ingredients,
  }) {
    return Meal(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}

class DayPlan {
  final DateTime date;
  final List<Meal> meals;

  const DayPlan({
    required this.date,
    this.meals = const [],
  });

  String get dayName {
    final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return days[date.weekday - 1];
  }

  int get dayOfMonth => date.day;

  bool get isToday => date.toDateOnly == DateTime.now().toDateOnly;

  bool get isPast => date.isBefore(DateTime.now().toDateOnly);

  bool get isFuture => date.isAfter(DateTime.now().toDateOnly);

  Meal? getMeal(MealType type) {
    try {
      return meals.firstWhere((m) => m.type == type);
    } catch (e) {
      return null;
    }
  }

  DayPlan addMeal(Meal meal) {
    final updated = List<Meal>.from(meals);
    // Entferne existing meal des gleichen Typs
    updated.removeWhere((m) => m.type == meal.type);
    updated.add(meal);
    return DayPlan(date: date, meals: updated);
  }

  DayPlan removeMeal(MealType type) {
    final updated = List<Meal>.from(meals);
    updated.removeWhere((m) => m.type == type);
    return DayPlan(date: date, meals: updated);
  }
}

class WeekPlan {
  final DateTime weekStart;
  final List<DayPlan> days;

  const WeekPlan({
    required this.weekStart,
    this.days = const [],
  });

  factory WeekPlan.fromDateTime(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return WeekPlan(weekStart: startOfWeek);
  }

  List<DayPlan> get sortedDays => [...days]..sort((a, b) => a.date.compareTo(b.date));

  DayPlan? getDay(int dayIndex) {
    final targetDate = weekStart.add(Duration(days: dayIndex));
    try {
      return sortedDays.firstWhere((d) => d.date.toDateOnly == targetDate.toDateOnly);
    } catch (e) {
      return DayPlan(date: targetDate);
    }
  }

  WeekPlan updateDay(DayPlan updatedDay) {
    final updated = List<DayPlan>.from(days);
    final index =
        updated.indexWhere((d) => d.date.toDateOnly == updatedDay.date.toDateOnly);
    if (index >= 0) {
      updated[index] = updatedDay;
    } else {
      updated.add(updatedDay);
    }
    return WeekPlan(weekStart: weekStart, days: updated);
  }
}

extension DateExtension on DateTime {
  DateTime get toDateOnly => DateTime(year, month, day);
}

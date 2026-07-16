import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/models/meal_plan.dart';

class MealPlannerService {
  static Uri? _resolveUri(String relativePath) {
    final baseUrl = APIConfig.getBackendBaseUrl();
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return null;
    }

    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final normalizedPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return Uri.parse(normalizedBase).resolve(normalizedPath);
  }

  static String _mealPlansBasePath() {
    return APIConfig.getBackendMealPlansPath();
  }
  
  /// Fetch meal plan for a specific day
  static Future<DayPlan?> getMealPlan(String familyId, DateTime date) async {
    final endpoint = _resolveUri('${_mealPlansBasePath()}/$familyId?date=${date.toIso8601String().split('T')[0]}');
    if (endpoint == null) return null;

    try {
      final response = await http.get(
        endpoint,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDayPlan(data);
      }
      return null;
    } catch (e) {
      debugPrint('MealPlannerService.getMealPlan(): failed: $e');
      return null;
    }
  }

  /// Fetch week meal plan (7 days starting from startDate)
  static Future<WeekPlan?> getWeekMealPlan(String familyId, DateTime startDate) async {
    final endpoint = _resolveUri(
      '${_mealPlansBasePath()}/$familyId/week?startDate=${startDate.toIso8601String().split('T')[0]}',
    );
    if (endpoint == null) return null;

    try {
      final response = await http.get(
        endpoint,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final days = data.map<DayPlan>((dayData) => _parseDayPlan(dayData)).toList();
        
        return WeekPlan(
          weekStart: startDate,
          days: days,
        );
      }
      return null;
    } catch (e) {
      debugPrint('MealPlannerService.getWeekMealPlan(): failed: $e');
      return null;
    }
  }

  /// Create or update a day's meal plan
  static Future<DayPlan?> saveMealPlan(
    String familyId,
    DateTime date,
    List<Meal> meals,
  ) async {
    final endpoint = _resolveUri('${_mealPlansBasePath()}/$familyId');
    if (endpoint == null) return null;

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final payload = {
        'date': dateStr,
        'meals': meals.map((meal) => {
          'title': meal.title,
          'type': meal.type.name,
          'description': meal.description,
          'ingredients': meal.ingredients,
        }).toList(),
      };

      final response = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return _parseDayPlan(data);
      }
      return null;
    } catch (e) {
      debugPrint('MealPlannerService.saveMealPlan(): failed: $e');
      return null;
    }
  }

  /// Add a single meal to a meal plan
  static Future<Meal?> addMeal(String mealPlanId, Meal meal) async {
    final endpoint = _resolveUri('/meals/$mealPlanId');
    if (endpoint == null) return null;

    try {
      final payload = {
        'title': meal.title,
        'type': meal.type.name,
        'description': meal.description,
        'ingredients': meal.ingredients,
      };

      final response = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return _parseMeal(data);
      }
      return null;
    } catch (e) {
      debugPrint('MealPlannerService.addMeal(): failed: $e');
      return null;
    }
  }

  /// Update a meal
  static Future<Meal?> updateMeal(String mealId, Meal meal) async {
    final endpoint = _resolveUri('/meals/$mealId');
    if (endpoint == null) return null;

    try {
      final payload = {
        'title': meal.title,
        'type': meal.type.name,
        'description': meal.description,
        'ingredients': meal.ingredients,
      };

      final response = await http.put(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMeal(data);
      }
      return null;
    } catch (e) {
      debugPrint('MealPlannerService.updateMeal(): failed: $e');
      return null;
    }
  }

  /// Delete a meal
  static Future<bool> deleteMeal(String mealId) async {
    final endpoint = _resolveUri('/meals/$mealId');
    if (endpoint == null) return false;

    try {
      final response = await http.delete(
        endpoint,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('MealPlannerService.deleteMeal(): failed: $e');
      return false;
    }
  }

  // ============================================================
  // Helper methods
  // ============================================================

  static DayPlan _parseDayPlan(Map<String, dynamic> data) {
    final meals = <Meal>[];
    if (data['meals'] != null) {
      for (var mealData in data['meals']) {
        meals.add(_parseMeal(mealData));
      }
    }

    return DayPlan(
      date: DateTime.parse(data['date'] as String),
      meals: meals,
    );
  }

  static Meal _parseMeal(Map<String, dynamic> data) {
    final rawIngredients = data['ingredients'];
    final ingredients = rawIngredients is String
      ? List<String>.from(json.decode(rawIngredients))
      : rawIngredients is List
        ? List<String>.from(rawIngredients)
        : <String>[];

    final typeString = data['type'] as String;
    final mealType = MealType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => MealType.breakfast,
    );

    return Meal(
      id: data['id'] as String,
      title: data['title'] as String,
      type: mealType,
      description: data['description'] as String?,
      ingredients: ingredients,
    );
  }
}

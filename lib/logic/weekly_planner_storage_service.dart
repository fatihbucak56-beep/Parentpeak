import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/models/day_plan.dart';
import 'package:trusted_circle_demo/models/meal_memory.dart';

import 'backend_api_client.dart';

class WeeklyPlannerStorageService {
  WeeklyPlannerStorageService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _storagePrefix = 'planner.week.v1.';
  static const String _pantryKey = 'planner.pantry.v1';
  static const String _mealMemoriesKey = 'planner.meal_memories.v1';

  Future<List<DayPlan>> loadWeek(DateTime weekStart) async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final path =
            '${APIConfig.getBackendMealPlansPath()}?weekStart=${Uri.encodeQueryComponent(_normalizeDate(weekStart).toIso8601String())}';
        final payload = await apiClient!.getJson(path);
        final parsed = _parsePlans(payload);
        if (parsed.isNotEmpty) {
          await _persistLocal(weekStart, parsed);
          return parsed;
        }
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Server-Sync nicht verfügbar',
          error: e,
        );
      }
    }

    return _readLocal(weekStart);
  }

  Future<void> saveWeek(DateTime weekStart, List<DayPlan> plans) async {
    lastSyncError = null;
    await _persistLocal(weekStart, plans);

    if (apiClient != null) {
      try {
        await apiClient!.postJsonAny(
          APIConfig.getBackendMealPlansPath(),
          {
            'weekStart': _normalizeDate(weekStart).toIso8601String(),
            'plans': plans.map((plan) => plan.toMap()).toList(),
          },
        );
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Server-Sync nicht verfügbar',
          error: e,
        );
      }
    }
  }

  Future<Set<String>> loadPantryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pantryKey);
    if (raw == null || raw.isEmpty) return <String>{};

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>{};

    return decoded
        .map((item) => item.toString().trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<void> savePantryItems(Set<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = items
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList()
      ..sort();

    await prefs.setString(_pantryKey, jsonEncode(normalized));
  }

  Future<List<MealMemory>> loadMealMemoriesForYear(int year) async {
    final all = await _loadAllMealMemories();
    final filtered = all.where((entry) => entry.date.year == year).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> saveMealMemory(MealMemory memory) async {
    final all = await _loadAllMealMemories();
    final index = all.indexWhere((entry) => entry.id == memory.id);
    if (index >= 0) {
      all[index] = memory;
    } else {
      all.insert(0, memory);
    }
    await _saveAllMealMemories(all);
  }

  Future<List<MealMemory>> _loadAllMealMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealMemoriesKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => MealMemory.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _saveAllMealMemories(List<MealMemory> memories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mealMemoriesKey,
      jsonEncode(memories.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<DayPlan>> _readLocal(DateTime weekStart) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(weekStart));
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => DayPlan.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _persistLocal(DateTime weekStart, List<DayPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(weekStart),
      jsonEncode(plans.map((plan) => plan.toMap()).toList()),
    );
  }

  List<DayPlan> _parsePlans(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => DayPlan.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (payload is Map && payload['plans'] is List) {
      final rawPlans = payload['plans'] as List;
      return rawPlans
          .whereType<Map>()
          .map((item) => DayPlan.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return [];
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _storageKey(DateTime weekStart) {
    final normalized = _normalizeDate(weekStart);
    return '$_storagePrefix${normalized.toIso8601String()}';
  }

  String _friendlySyncError({
    required String action,
    required Object error,
  }) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('handshakeexception') ||
        raw.contains('tls') ||
        raw.contains('ssl') ||
        raw.contains('certificate')) {
      return 'Lokaler Modus aktiv. Verbindung zum Server ist aktuell nicht sicher verfügbar.';
    }

    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('timed out') ||
        raw.contains('timeout')) {
      return 'Lokaler Modus aktiv. Server derzeit nicht erreichbar.';
    }

    return '$action: $error';
  }
}
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_client.dart';

class CalendarBackendService {
  CalendarBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _storageKey = 'backend.calendar.v1';

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    lastSyncError = null;
    if (apiClient != null) {
      try {
        final remote = await apiClient!.getList('/calendar/events');
        final events = remote
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await _persist(events);
        return events;
      } catch (e) {
        lastSyncError = 'Server-Sync fehlgeschlagen: $e';
      }
    }

    return _readLocal();
  }

  Future<void> addEvent(Map<String, dynamic> event) async {
    final current = await _readLocal();
    current.add(event);
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.postJson('/calendar/events', event);
      } catch (e) {
        lastSyncError = 'Kalender-Event konnte nicht auf Server gespeichert werden: $e';
      }
    }
  }

  Future<void> seedIfEmpty(List<Map<String, dynamic>> seedEvents) async {
    final current = await _readLocal();
    if (current.isNotEmpty) return;
    await _persist(seedEvents);
  }

  Future<List<Map<String, dynamic>>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Future<void> _persist(List<Map<String, dynamic>> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(events));
  }
}

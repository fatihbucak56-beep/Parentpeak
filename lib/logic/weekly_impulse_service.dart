import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/models_and_widgets/weekly_impulse_feature.dart';

import 'backend_api_client.dart';

class WeeklyImpulseService {
  const WeeklyImpulseService({required this.apiClient});

  final BackendApiClient? apiClient;
  static const String _cacheKey = 'weekly_impulse.cache.v1';
  static const List<String> _requiredFields = [
    'id',
    'title',
    'content_body',
    'practical_tip',
    'category',
    'publish_date',
  ];

  Future<WeeklyImpulse> fetchWeeklyImpulse() async {
    if (apiClient != null) {
      try {
        final decoded =
            await apiClient!.getJson(APIConfig.getBackendWeeklyImpulsePath());
        final impulse = _parseIfValid(decoded);
        if (impulse != null) {
          await _saveCache(decoded as Map<String, dynamic>);
          return impulse;
        }
      } catch (e) {
        debugPrint('WeeklyImpulse backend fallback: $e');
      }
    }

    final cached = await _readCache();
    final cachedImpulse = _parseIfValid(cached);
    if (cachedImpulse != null) {
      return cachedImpulse;
    }

    return WeeklyImpulse.fromJson(_fallbackImpulseJson());
  }

  WeeklyImpulse? _parseIfValid(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    for (final field in _requiredFields) {
      final value = decoded[field];
      if (value is! String || value.trim().isEmpty) {
        return null;
      }
    }

    try {
      return WeeklyImpulse.fromJson(decoded);
    } catch (e) {
      debugPrint('WeeklyImpulse parse invalid payload: $e');
      return null;
    }
  }

  Future<void> _saveCache(Map<String, dynamic> raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(raw));
    } catch (e) {
      debugPrint('WeeklyImpulse cache save failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('WeeklyImpulse cache read failed: $e');
      return null;
    }
  }

  Map<String, dynamic> _fallbackImpulseJson() {
    final now = DateTime.now();
    return {
      'id': 'imp_3y_gfk_w2',
      'title': 'Warum-Phase ohne Machtkampf begleiten',
      'content_body':
          'Dein Kind stellt gerade viele Warum-Fragen und testet Grenzen. Das ist kein Trotz gegen dich, sondern echte Entwicklung.\n\nAntworte kurz, klar und in einfachen Bildern. So bleibt ihr in Verbindung, auch wenn es im Alltag schnell gehen muss.\n\nWenn eine Grenze noetig ist, bleib bei Ich-Botschaften statt Vorwuerfen.',
      'practical_tip':
          'Heute bei der naechsten Warum-Frage: Erst Gefuehl spiegeln, dann eine kurze Antwort geben und eine klare Grenze freundlich benennen.',
      'audio_script':
          'Hallo, schoen dass du da bist. Die Warum-Phase zeigt, dass dein Kind die Welt verstehen will. Mit kurzen Antworten und klaren Grenzen auf Augenhoehe gibst du Sicherheit und Verbindung. Du machst das gut.',
      'category': 'gfk',
      'publish_date': now.toIso8601String(),
    };
  }
}

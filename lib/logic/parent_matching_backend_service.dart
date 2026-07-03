import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/config/api_config.dart';

import 'backend_api_client.dart';

class ParentMatchingBackendService {
  ParentMatchingBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _profilesStorageKey = 'backend.parent_matching.profiles.v1';

  bool get _allowSeedFallback => !kReleaseMode;

  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!
            .getJson(APIConfig.getBackendParentMatchingProfilesPath());
        final profiles = _parseProfiles(payload);
        if (profiles.isNotEmpty) {
          await _persistProfiles(profiles);
          return profiles;
        }
      } catch (e) {
        lastSyncError = 'Server-Sync fehlgeschlagen: $e';
      }
    }

    final local = await _readLocalProfiles();
    if (local.isNotEmpty) {
      return local;
    }

    if (_allowSeedFallback) {
      final seeded = _seedProfiles();
      await _persistProfiles(seeded);
      return seeded;
    }

    return [];
  }

  Future<void> sendAction({
    required String profileId,
    required String action,
    String? userId,
  }) async {
    if (apiClient == null) return;

    try {
      await apiClient!.postJsonAny(
        APIConfig.getBackendParentMatchingActionsPath(),
        {
          'familyId': APIConfig.getBackendFamilyId(),
          'profileId': profileId,
          'action': action,
          'userId': userId,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'schemaVersion': APIConfig.getBackendApiVersion(),
        },
      );
    } catch (e) {
      lastSyncError = 'Matching-Aktion konnte nicht synchronisiert werden: $e';
    }
  }

  List<Map<String, dynamic>> _parseProfiles(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((e) => _normalizeProfile(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (payload is Map) {
      final mapPayload = Map<String, dynamic>.from(payload);
      for (final key in const ['profiles', 'items', 'data', 'results']) {
        final value = mapPayload[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => _normalizeProfile(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _normalizeProfile(Map<String, dynamic> raw) {
    List<String> toStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    return {
      'id': (raw['id'] ?? raw['_id'] ?? raw['uuid'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
      'name': (raw['name'] ?? 'Unbekannt').toString(),
      'age': (raw['age'] is num) ? (raw['age'] as num).toInt() : int.tryParse('${raw['age']}') ?? 30,
      'city': (raw['city'] ?? 'Unbekannt').toString(),
      'bio': (raw['bio'] ?? '').toString(),
      'interests': toStringList(raw['interests']),
      'languages': toStringList(raw['languages']),
      'valuesFocus': toStringList(raw['valuesFocus'] ?? raw['values']),
      'childAges': toStringList(raw['childAges']),
      'familyForm': (raw['familyForm'] ?? 'Kernfamilie').toString(),
      'verificationLevel': (raw['verificationLevel'] ?? 'basic').toString(),
    };
  }

  Future<List<Map<String, dynamic>>> _readLocalProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesStorageKey);
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

  Future<void> _persistProfiles(List<Map<String, dynamic>> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesStorageKey, jsonEncode(profiles));
  }

  List<Map<String, dynamic>> _seedProfiles() {
    return [
      {
        'id': 'p1',
        'name': 'Miriam',
        'age': 34,
        'city': 'Berlin',
        'bio': 'Ich suche Eltern für gemeinsame Wochenendaktivitäten und ehrlichen Austausch.',
        'interests': ['Spielplatz', 'Outdoor', 'Familienzeit', 'Bildung'],
        'languages': ['Deutsch', 'Englisch'],
        'valuesFocus': ['Gewaltfrei', 'Empathie', 'Inklusion'],
        'childAges': ['3-5', '6-9'],
        'familyForm': 'Kernfamilie',
        'verificationLevel': 'recommended',
      },
      {
        'id': 'p2',
        'name': 'Sibel',
        'age': 37,
        'city': 'Köln',
        'bio': 'Alleinerziehend, offen für neue Freundschaften mit Eltern in ähnlicher Situation.',
        'interests': ['Gesundheit', 'Bildung', 'Kreativ'],
        'languages': ['Deutsch', 'Türkisch'],
        'valuesFocus': ['Respekt', 'Offenheit', 'Empathie'],
        'childAges': ['6-9', '10-13'],
        'familyForm': 'Alleinerziehend',
        'verificationLevel': 'checked',
      },
      {
        'id': 'p3',
        'name': 'Jonas',
        'age': 40,
        'city': 'Hamburg',
        'bio': 'Wir sind eine Patchwork-Familie und suchen entspannte Eltern für Spieltreffen.',
        'interests': ['Sport', 'Outdoor', 'Spielplatz'],
        'languages': ['Deutsch'],
        'valuesFocus': ['Gewaltfrei', 'Tradition', 'Respekt'],
        'childAges': ['0-2', '3-5'],
        'familyForm': 'Patchwork',
        'verificationLevel': 'basic',
      },
      {
        'id': 'p4',
        'name': 'Lina',
        'age': 32,
        'city': 'München',
        'bio': 'Ich liebe Lernideen für Kinder und suche Eltern für kleine Bildungsprojekte.',
        'interests': ['Bildung', 'Kreativ', 'Familienzeit'],
        'languages': ['Deutsch', 'Französisch', 'Englisch'],
        'valuesFocus': ['Inklusion', 'Offenheit', 'Empathie'],
        'childAges': ['6-9'],
        'familyForm': 'Kernfamilie',
        'verificationLevel': 'recommended',
      },
      {
        'id': 'p5',
        'name': 'Baran',
        'age': 35,
        'city': 'Dortmund',
        'bio': 'Vater von zwei Kindern, interessiert an gewaltfreier Kommunikation und Community.',
        'interests': ['Gesundheit', 'Familienzeit', 'Sport'],
        'languages': ['Deutsch', 'Kurdisch'],
        'valuesFocus': ['Gewaltfrei', 'Respekt', 'Empathie'],
        'childAges': ['3-5', '10-13'],
        'familyForm': 'Kernfamilie',
        'verificationLevel': 'checked',
      },
    ];
  }
}

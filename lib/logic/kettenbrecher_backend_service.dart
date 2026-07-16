import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/config/api_config.dart';
import 'package:parentpeak/logic/backend_api_client.dart';
import 'package:parentpeak/models/cooking_hub.dart';
import 'package:parentpeak/models/kitchen_sos.dart';
import 'package:parentpeak/models/kitchen_sos_response.dart';
import 'package:parentpeak/models/local_help_profile.dart';

class KettenbrecherBackendService {
  KettenbrecherBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _hubStorageKey = 'kettenbrecher.hub.v1';
  static const String _helpProfilesStorageKey = 'kettenbrecher.help_profiles.v1';

  Future<CookingHub> loadCookingHub({required CookingHub fallbackHub}) async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(APIConfig.getBackendKettenbrecherHubPath());
        final parsed = _parseHub(payload);
        if (parsed != null) {
          await _saveHubLocal(parsed);
          return parsed;
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('Hub-Sync lokal aktiv', e);
      }
    }

    final local = await _readHubLocal();
    return local ?? fallbackHub;
  }

  Future<void> saveCookingHub(CookingHub hub) async {
    lastSyncError = null;
    await _saveHubLocal(hub);

    if (apiClient != null) {
      try {
        await apiClient!.postJsonAny(APIConfig.getBackendKettenbrecherHubPath(), hub.toMap());
      } catch (e) {
        lastSyncError = _friendlySyncError('Hub konnte nicht synchronisiert werden', e);
      }
    }
  }

  Future<List<LocalHelpProfile>> loadLocalHelpProfiles({
    required List<LocalHelpProfile> fallbackProfiles,
  }) async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(APIConfig.getBackendKettenbrecherLocalHelpProfilesPath());
        final parsed = _parseProfiles(payload);
        if (parsed.isNotEmpty) {
          await _saveProfilesLocal(parsed);
          return parsed;
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('Trust-Profile konnten nicht geladen werden', e);
      }
    }

    final local = await _readProfilesLocal();
    if (local.isNotEmpty) {
      return local;
    }

    await _saveProfilesLocal(fallbackProfiles);
    return fallbackProfiles;
  }

  Future<Map<String, dynamic>> triggerKitchenSos({
    required KitchenSos sos,
    required List<String> recipientUserIds,
    required double radiusMeters,
  }) async {
    lastSyncError = null;

    final payload = {
      ...sos.toMap(),
      'recipientUserIds': recipientUserIds,
      'radiusMeters': radiusMeters,
    };

    if (apiClient != null) {
      try {
        final response = await apiClient!.postJsonAny(
          APIConfig.getBackendKettenbrecherSosPath(),
          payload,
        );
        final map = _asMap(response);
        if (map != null) {
          final normalized = _unwrapDataObject(map);
          final status = normalized['status']?.toString() ?? map['status']?.toString() ?? 'sent';
          return {
            ...normalized,
            'status': status,
          };
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('SOS lokal ausgeliefert', e);
      }
    }

    return {
      'status': 'local_only',
      'queued': true,
      'sosId': sos.id,
      'recipientUserIds': recipientUserIds,
      'radiusMeters': radiusMeters,
      'createdAt': sos.createdAt.toIso8601String(),
    };
  }

  Future<KitchenSosResponse> updateKitchenSosResponderAction({
    required String sosId,
    required String responderUserId,
    required KitchenSosResponseStatus status,
    int? etaMinutes,
  }) async {
    lastSyncError = null;

    final payload = {
      'sosId': sosId,
      'responderUserId': responderUserId,
      'status': status.name,
      'etaMinutes': etaMinutes,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (apiClient != null) {
      try {
        final response = await apiClient!.postJsonAny(
          APIConfig.getBackendKettenbrecherSosResponderActionPath(),
          payload,
        );

        final parsed = _parseResponderAction(response);
        if (parsed != null) {
          return parsed;
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('Responder-Aktion lokal gespeichert', e);
      }
    }

    return KitchenSosResponse(
      sosId: sosId,
      responderUserId: responderUserId,
      status: status,
      etaMinutes: etaMinutes,
      updatedAt: DateTime.now(),
    );
  }

  CookingHub? _parseHub(dynamic payload) {
    final root = _asMap(payload);
    if (root == null) return null;

    final data = _unwrapDataObject(root);
    if (data['hub'] is Map) {
      return CookingHub.fromMap(Map<String, dynamic>.from(data['hub'] as Map));
    }

    return CookingHub.fromMap(data);
  }

  List<LocalHelpProfile> _parseProfiles(dynamic payload) {
    final list = _extractListFromPayload(payload, keys: const ['items', 'profiles']);

    return list
        .whereType<Map>()
        .map((item) => LocalHelpProfile.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.userId.trim().isNotEmpty)
        .toList();
  }

  KitchenSosResponse? _parseResponderAction(dynamic payload) {
    final root = _asMap(payload);
    if (root == null) return null;

    final data = _unwrapDataObject(root);
    if (data['item'] is Map) {
      return KitchenSosResponse.fromMap(Map<String, dynamic>.from(data['item'] as Map));
    }

    return KitchenSosResponse.fromMap(data);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic> _unwrapDataObject(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return root;
  }

  List<dynamic> _extractListFromPayload(dynamic payload, {required List<String> keys}) {
    if (payload is List) return payload;

    final root = _asMap(payload);
    if (root == null) return const [];

    for (final key in keys) {
      final direct = root[key];
      if (direct is List) return direct;
    }

    final dataMap = _asMap(root['data']);
    if (dataMap == null) return const [];

    for (final key in keys) {
      final nested = dataMap[key];
      if (nested is List) return nested;
    }

    return const [];
  }

  String _friendlySyncError(String context, Object error) {
    final raw = error.toString();
    if (raw.contains('409')) {
      return '$context: Konflikt erkannt (409). Bitte aktualisieren und erneut versuchen.';
    }
    if (raw.contains('404')) {
      return '$context: Ziel nicht gefunden (404).';
    }
    if (raw.contains('400')) {
      return '$context: Anfrage ungueltig (400).';
    }
    if (raw.contains('500')) {
      return '$context: Serverfehler (500).';
    }
    return '$context: $raw';
  }

  Future<void> _saveHubLocal(CookingHub hub) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hubStorageKey, jsonEncode(hub.toMap()));
  }

  Future<CookingHub?> _readHubLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hubStorageKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return CookingHub.fromMap(decoded);
    }
    if (decoded is Map) {
      return CookingHub.fromMap(Map<String, dynamic>.from(decoded));
    }
    return null;
  }

  Future<void> _saveProfilesLocal(List<LocalHelpProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _helpProfilesStorageKey,
      jsonEncode(profiles.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<LocalHelpProfile>> _readProfilesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_helpProfilesStorageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => LocalHelpProfile.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.userId.trim().isNotEmpty)
        .toList();
  }
}

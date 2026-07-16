import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/config/api_config.dart';

import 'backend_api_client.dart';

class ParentMatchActionResult {
  const ParentMatchActionResult({
    required this.connected,
    required this.matchState,
  });

  final bool connected;
  final String matchState;
}

class ParentMatchingBackendService {
  ParentMatchingBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _profilesStorageKey =
      'backend.parent_matching.profiles.v1';

  Future<List<Map<String, dynamic>>> fetchProfiles({String? userId}) async {
    lastSyncError = null;

    if (apiClient == null) {
      lastSyncError = 'Backend ist nicht konfiguriert.';
      return const [];
    }

    try {
      final profilePath = _buildPathWithQuery(
        APIConfig.getBackendParentMatchingProfilesPath(),
        {
          if (userId != null && userId.trim().isNotEmpty)
            'userId': userId.trim(),
        },
      );
      final payload = await apiClient!.getJson(profilePath);
      final profiles = _parseProfiles(payload);
      await _persistProfiles(profiles);
      return profiles;
    } catch (e) {
      lastSyncError = 'Server-Sync fehlgeschlagen: $e';
      return const [];
    }
  }

  Future<Map<String, dynamic>?> fetchMyProfile({required String userId}) async {
    if (apiClient == null || userId.trim().isEmpty) return null;

    try {
      final path = _buildPathWithQuery(
        APIConfig.getBackendParentMatchingMyProfilePath(),
        {'userId': userId.trim()},
      );
      final payload = await apiClient!.getJson(path);
      if (payload is Map<String, dynamic>) {
        final item = payload['item'];
        if (item is Map) {
          return _normalizeProfile(Map<String, dynamic>.from(item));
        }
      }
    } catch (e) {
      lastSyncError = 'Eigenes Matching-Profil konnte nicht geladen werden: $e';
    }
    return null;
  }

  Future<Map<String, dynamic>?> upsertMyProfile({
    required String userId,
    required Map<String, dynamic> profile,
  }) async {
    if (apiClient == null || userId.trim().isEmpty) return null;
    try {
      final payload = await apiClient!.postJsonAny(
        APIConfig.getBackendParentMatchingMyProfilePath(),
        {
          'userId': userId.trim(),
          ...profile,
        },
      );
      if (payload is Map<String, dynamic>) {
        final item = payload['item'];
        if (item is Map) {
          return _normalizeProfile(Map<String, dynamic>.from(item));
        }
      }
    } catch (e) {
      lastSyncError = 'Matching-Profil konnte nicht gespeichert werden: $e';
    }
    return null;
  }

  Future<ParentMatchActionResult> sendAction({
    required String profileId,
    required String action,
    String? userId,
  }) async {
    if (apiClient == null) {
      return const ParentMatchActionResult(
        connected: false,
        matchState: 'error',
      );
    }

    try {
      final payload = await apiClient!.postJsonAny(
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

      if (payload is Map<String, dynamic>) {
        final connected = payload['connected'] == true;
        final matchState = (payload['matchState'] ??
                (connected
                    ? 'matched'
                    : (action == 'like' ? 'pending' : 'none')))
            .toString();
        return ParentMatchActionResult(
          connected: connected,
          matchState: matchState,
        );
      }
      return const ParentMatchActionResult(connected: false, matchState: 'error');
    } catch (e) {
      lastSyncError = 'Matching-Aktion konnte nicht synchronisiert werden: $e';
      return const ParentMatchActionResult(connected: false, matchState: 'error');
    }
  }

  Future<Set<String>> fetchConnectedProfileIds({required String userId}) async {
    if (apiClient == null || userId.trim().isEmpty) {
      return <String>{};
    }

    try {
      final path = _buildPathWithQuery(
        APIConfig.getBackendParentMatchingConnectionsPath(),
        {
          'familyId': APIConfig.getBackendFamilyId(),
          'userId': userId.trim(),
        },
      );
      final payload = await apiClient!.getJson(path);
      if (payload is Map<String, dynamic>) {
        final ids = (payload['profileIds'] as List?)
                ?.map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toSet() ??
            <String>{};
        return ids;
      }
    } catch (e) {
      lastSyncError = 'Verbindungen konnten nicht geladen werden: $e';
    }

    return <String>{};
  }

  Future<List<Map<String, dynamic>>> fetchMessages({
    required String profileId,
    required String userId,
  }) async {
    if (apiClient == null ||
        userId.trim().isEmpty ||
        profileId.trim().isEmpty) {
      return const [];
    }

    try {
      final path = _buildPathWithQuery(
        APIConfig.getBackendParentMatchingMessagesPath(),
        {
          'familyId': APIConfig.getBackendFamilyId(),
          'userId': userId.trim(),
          'profileId': profileId.trim(),
        },
      );
      final payload = await apiClient!.getJson(path);
      if (payload is Map<String, dynamic>) {
        final list = payload['items'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    } catch (e) {
      lastSyncError = 'Nachrichten konnten nicht geladen werden: $e';
    }

    return const [];
  }

  Future<Map<String, dynamic>?> sendMessage({
    required String profileId,
    required String userId,
    required String userName,
    required String content,
  }) async {
    if (apiClient == null ||
        userId.trim().isEmpty ||
        profileId.trim().isEmpty ||
        content.trim().isEmpty) {
      return null;
    }

    try {
      final payload = await apiClient!.postJsonAny(
        APIConfig.getBackendParentMatchingMessagesPath(),
        {
          'familyId': APIConfig.getBackendFamilyId(),
          'profileId': profileId.trim(),
          'userId': userId.trim(),
          'userName': userName.trim().isEmpty ? 'Elternteil' : userName.trim(),
          'content': content.trim(),
        },
      );

      if (payload is Map<String, dynamic>) {
        final item = payload['item'];
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
      }
    } catch (e) {
      lastSyncError = 'Nachricht konnte nicht gesendet werden: $e';
    }

    return null;
  }

  Stream<Map<String, dynamic>> streamMessages({
    required String profileId,
    required String userId,
  }) async* {
    final baseUrl = APIConfig.getBackendBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return;
    if (profileId.trim().isEmpty || userId.trim().isEmpty) return;

    final path = _buildPathWithQuery(
      APIConfig.getBackendParentMatchingMessagesStreamPath(),
      {
        'familyId': APIConfig.getBackendFamilyId(),
        'profileId': profileId.trim(),
        'userId': userId.trim(),
      },
    );

    final uri = Uri.parse(
      '$baseUrl${path.startsWith('/') ? path : '/$path'}',
    );

    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      final token = APIConfig.getBackendApiToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('SSE failed: ${response.statusCode}');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        }
      }
    } catch (e) {
      lastSyncError = 'Live-Stream konnte nicht aufgebaut werden: $e';
    } finally {
      client.close();
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
        return value
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    return {
      'id': (raw['id'] ??
              raw['_id'] ??
              raw['uuid'] ??
              DateTime.now().microsecondsSinceEpoch.toString())
          .toString(),
      'name': (raw['name'] ?? 'Unbekannt').toString(),
      'age': (raw['age'] is num)
          ? (raw['age'] as num).toInt()
          : int.tryParse('${raw['age']}') ?? 30,
      'city': (raw['city'] ?? 'Unbekannt').toString(),
      'bio': (raw['bio'] ?? '').toString(),
      'interests': toStringList(raw['interests']),
      'languages': toStringList(raw['languages']),
      'valuesFocus': toStringList(raw['valuesFocus'] ?? raw['values']),
      'childAges': toStringList(raw['childAges']),
      'familyForm': (raw['familyForm'] ?? 'Kernfamilie').toString(),
      'verificationLevel': (raw['verificationLevel'] ?? 'basic').toString(),
      'latitude': (raw['latitude'] is num)
          ? (raw['latitude'] as num).toDouble()
          : double.tryParse('${raw['latitude']}'),
      'longitude': (raw['longitude'] is num)
          ? (raw['longitude'] as num).toDouble()
          : double.tryParse('${raw['longitude']}'),
    };
  }

  String _buildPathWithQuery(String basePath, Map<String, String> query) {
    if (query.isEmpty) return basePath;
    final separator = basePath.contains('?') ? '&' : '?';
    final queryString = query.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    return '$basePath$separator$queryString';
  }

  Future<void> _persistProfiles(List<Map<String, dynamic>> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesStorageKey, jsonEncode(profiles));
  }
}

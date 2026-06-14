import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/config/api_config.dart';

import 'backend_api_client.dart';

class PhotoBackendService {
  PhotoBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _storageKey = 'backend.photos.v1';

  Future<List<Map<String, dynamic>>> fetchAlbums() async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(APIConfig.getBackendPhotosPath());
        final albums = _parseAlbumList(payload);
        if (albums.isNotEmpty) {
          await _persist(albums);
          return albums;
        }
      } catch (e) {
        lastSyncError = 'Server-Sync fehlgeschlagen: $e';
      }
    }

    final local = await _readLocal();
    if (local.isNotEmpty) {
      return local;
    }

    final seeded = _seedAlbums();
    await _persist(seeded);
    return seeded;
  }

  Future<Map<String, dynamic>> addAlbum({required String title}) async {
    final item = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'date': DateTime.now().toIso8601String(),
      'count': 0,
    };

    final current = await _readLocal();
    current.insert(0, item);
    await _persist(current);

    if (apiClient != null) {
      try {
        final payload = await apiClient!.postJsonAny(
          APIConfig.getBackendPhotosPath(),
          {
            'familyId': APIConfig.getBackendFamilyId(),
            'title': title,
            'photoCount': 0,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );

        final normalized = _parseSingleAlbum(payload);
        if (normalized != null) {
          item['id'] = normalized['id'];
        }
      } catch (e) {
        lastSyncError = 'Foto-Album konnte nicht auf dem Server gespeichert werden: $e';
      }
    }

    return item;
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

  Future<void> _persist(List<Map<String, dynamic>> albums) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(albums));
  }

  List<Map<String, dynamic>> _parseAlbumList(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map>().map((e) => _normalizeAlbum(Map<String, dynamic>.from(e))).toList();
    }

    if (payload is Map) {
      final mapPayload = Map<String, dynamic>.from(payload);
      for (final key in const ['items', 'albums', 'photos', 'data', 'results']) {
        final value = mapPayload[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => _normalizeAlbum(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    }

    return [];
  }

  Map<String, dynamic>? _parseSingleAlbum(dynamic payload) {
    if (payload is Map) {
      final mapPayload = Map<String, dynamic>.from(payload);
      final direct = mapPayload['album'] ?? mapPayload['item'] ?? mapPayload['data'];
      if (direct is Map) {
        return _normalizeAlbum(Map<String, dynamic>.from(direct));
      }
      return _normalizeAlbum(mapPayload);
    }
    return null;
  }

  Map<String, dynamic> _normalizeAlbum(Map<String, dynamic> raw) {
    final id = (raw['id'] ?? raw['_id'] ?? raw['uuid'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString();
    final title = (raw['title'] ?? raw['name'] ?? 'Album').toString();
    final countRaw = raw['count'] ?? raw['photoCount'] ?? raw['items'] ?? 0;
    final count = countRaw is num ? countRaw.toInt() : int.tryParse(countRaw.toString()) ?? 0;
    final date = (raw['date'] ?? raw['createdAt'] ?? raw['updatedAt'] ?? DateTime.now().toIso8601String()).toString();

    return {
      'id': id,
      'title': title,
      'count': count,
      'date': date,
    };
  }

  List<Map<String, dynamic>> _seedAlbums() {
    return [
      {
        'id': 'album-1',
        'title': 'Familienausflug',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'count': 12,
      },
      {
        'id': 'album-2',
        'title': 'Geburtstag Leon',
        'date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'count': 24,
      },
      {
        'id': 'album-3',
        'title': 'Urlaub 2025',
        'date': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        'count': 87,
      },
      {
        'id': 'album-4',
        'title': 'Erster Schultag',
        'date': DateTime.now().subtract(const Duration(days: 120)).toIso8601String(),
        'count': 15,
      },
    ];
  }
}

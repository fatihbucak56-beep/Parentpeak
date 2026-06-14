import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/models/audio_hack.dart';
import 'package:trusted_circle_demo/models/community_snack.dart';
import 'package:trusted_circle_demo/models/ingredient_share.dart';

import 'backend_api_client.dart';

class CommunitySnackPageResult {
  const CommunitySnackPageResult({
    required this.items,
    required this.hasMore,
    required this.nextPage,
  });

  final List<CommunitySnack> items;
  final bool hasMore;
  final int nextPage;
}

class NextGenFoodFeedBackendService {
  NextGenFoodFeedBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _snacksStorageKey = 'next_gen_food_feed.snacks.v1';
  static const String _audioStorageKey = 'next_gen_food_feed.audio_hacks.v1';
  static const String _sharesStorageKey = 'next_gen_food_feed.ingredient_shares.v1';

  Future<CommunitySnackPageResult> loadCommunitySnacksPage({
    required int page,
    required int pageSize,
    required List<CommunitySnack> fallback,
  }) async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final path =
            '${APIConfig.getBackendCommunitySnacksPath()}?page=$page&pageSize=$pageSize';
        final payload = await apiClient!.getJson(path);
        final parsed = _parseSnacks(payload);
        if (parsed.isNotEmpty) {
          if (page == 1) {
            await _saveSnacksLocal(parsed);
          }

          final metaMap = _extractMeta(payload);
          final hasMore = _boolFromMeta(metaMap, 'hasMore') ?? (parsed.length >= pageSize);
          final nextPage = _intFromMeta(metaMap, 'nextPage') ?? (page + 1);

          return CommunitySnackPageResult(
            items: parsed,
            hasMore: hasMore,
            nextPage: nextPage,
          );
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('Snack-Feed lokal aktiv', e);
      }
    }

    final local = await _readSnacksLocal();
    final source = local.isNotEmpty ? local : fallback;
    final start = (page - 1) * pageSize;
    if (start >= source.length) {
      return CommunitySnackPageResult(
        items: const [],
        hasMore: false,
        nextPage: page,
      );
    }

    final end = (start + pageSize) > source.length ? source.length : (start + pageSize);
    final slice = source.sublist(start, end);

    return CommunitySnackPageResult(
      items: slice,
      hasMore: end < source.length,
      nextPage: page + 1,
    );
  }

  Future<List<CommunitySnack>> loadCommunitySnacks({
    required List<CommunitySnack> fallback,
  }) async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(APIConfig.getBackendCommunitySnacksPath());
        final parsed = _parseSnacks(payload);
        if (parsed.isNotEmpty) {
          await _saveSnacksLocal(parsed);
          return parsed;
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('Snack-Feed lokal aktiv', e);
      }
    }

    final local = await _readSnacksLocal();
    if (local.isNotEmpty) return local;

    await _saveSnacksLocal(fallback);
    return fallback;
  }

  Future<List<AudioHack>> loadAudioHacks({
    required List<AudioHack> fallback,
  }) async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(APIConfig.getBackendAudioHacksPath());
        final parsed = _parseAudioHacks(payload);
        if (parsed.isNotEmpty) {
          await _saveAudioHacksLocal(parsed);
          return parsed;
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('Audio-Hacks lokal aktiv', e);
      }
    }

    final local = await _readAudioHacksLocal();
    if (local.isNotEmpty) return local;

    await _saveAudioHacksLocal(fallback);
    return fallback;
  }

  Future<List<IngredientShare>> loadIngredientShares({
    required List<IngredientShare> fallback,
  }) async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(APIConfig.getBackendIngredientSharesPath());
        final parsed = _parseIngredientShares(payload);
        if (parsed.isNotEmpty) {
          await _saveSharesLocal(parsed);
          return parsed;
        }
      } catch (e) {
        lastSyncError = _friendlySyncError('Zutaten-Retter lokal aktiv', e);
      }
    }

    final local = await _readSharesLocal();
    if (local.isNotEmpty) return local;

    await _saveSharesLocal(fallback);
    return fallback;
  }

  Future<CommunitySnack> publishCommunitySnack(CommunitySnack snack) async {
    lastSyncError = null;

    final local = await _readSnacksLocal();
    final index = local.indexWhere((item) => item.id == snack.id);
    if (index >= 0) {
      local[index] = snack;
    } else {
      local.insert(0, snack);
    }
    await _saveSnacksLocal(local);

    if (apiClient != null) {
      try {
        final payload = await apiClient!.postJsonAny(
          APIConfig.getBackendCommunitySnacksPath(),
          {
            ...snack.toMap(),
            'familyId': APIConfig.getBackendFamilyId(),
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );
        final normalized = _parseSingleSnack(payload);
        if (normalized != null) return normalized;
      } catch (e) {
        lastSyncError = _friendlySyncError('Snack Upload lokal gespeichert', e);
      }
    }

    return snack;
  }

  Future<AudioHack> publishAudioHack(AudioHack hack) async {
    lastSyncError = null;

    final local = await _readAudioHacksLocal();
    final index = local.indexWhere((item) => item.id == hack.id);
    if (index >= 0) {
      local[index] = hack;
    } else {
      local.insert(0, hack);
    }
    await _saveAudioHacksLocal(local);

    if (apiClient != null) {
      try {
        final payload = await apiClient!.postJsonAny(
          APIConfig.getBackendAudioHacksPath(),
          {
            ...hack.toMap(),
            'familyId': APIConfig.getBackendFamilyId(),
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );
        final normalized = _parseSingleAudioHack(payload);
        if (normalized != null) return normalized;
      } catch (e) {
        lastSyncError = _friendlySyncError('Audio-Hack Upload lokal gespeichert', e);
      }
    }

    return hack;
  }

  Future<IngredientShare> publishIngredientShare(IngredientShare share) async {
    lastSyncError = null;

    final local = await _readSharesLocal();
    final index = local.indexWhere((item) => item.id == share.id);
    if (index >= 0) {
      local[index] = share;
    } else {
      local.insert(0, share);
    }
    await _saveSharesLocal(local);

    if (apiClient != null) {
      try {
        final payload = await apiClient!.postJsonAny(
          APIConfig.getBackendIngredientSharesPath(),
          {
            ...share.toMap(),
            'familyId': APIConfig.getBackendFamilyId(),
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );
        final normalized = _parseSingleIngredientShare(payload);
        if (normalized != null) return normalized;
      } catch (e) {
        lastSyncError = _friendlySyncError('Zutaten-Retter Upload lokal gespeichert', e);
      }
    }

    return share;
  }

  List<CommunitySnack> _parseSnacks(dynamic payload) {
    final list = _extractListFromPayload(payload, keys: const ['items', 'snacks']);
    return list
        .whereType<Map>()
        .map((item) => CommunitySnack.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.trim().isNotEmpty)
        .toList();
  }

  List<AudioHack> _parseAudioHacks(dynamic payload) {
    final list = _extractListFromPayload(payload, keys: const ['items', 'audioHacks']);
    return list
        .whereType<Map>()
        .map((item) => AudioHack.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.trim().isNotEmpty)
        .toList();
  }

  List<IngredientShare> _parseIngredientShares(dynamic payload) {
    final list = _extractListFromPayload(payload, keys: const ['items', 'shares']);
    return list
        .whereType<Map>()
        .map((item) => IngredientShare.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.trim().isNotEmpty)
        .toList();
  }

  CommunitySnack? _parseSingleSnack(dynamic payload) {
    final root = _asMap(payload);
    if (root == null) return null;
    final data = _unwrapDataObject(root);
    if (data['item'] is Map) {
      return CommunitySnack.fromMap(Map<String, dynamic>.from(data['item'] as Map));
    }
    return CommunitySnack.fromMap(data);
  }

  AudioHack? _parseSingleAudioHack(dynamic payload) {
    final root = _asMap(payload);
    if (root == null) return null;
    final data = _unwrapDataObject(root);
    if (data['item'] is Map) {
      return AudioHack.fromMap(Map<String, dynamic>.from(data['item'] as Map));
    }
    return AudioHack.fromMap(data);
  }

  IngredientShare? _parseSingleIngredientShare(dynamic payload) {
    final root = _asMap(payload);
    if (root == null) return null;
    final data = _unwrapDataObject(root);
    if (data['item'] is Map) {
      return IngredientShare.fromMap(Map<String, dynamic>.from(data['item'] as Map));
    }
    return IngredientShare.fromMap(data);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic>? _extractMeta(dynamic payload) {
    final root = _asMap(payload);
    if (root == null) return null;

    final meta = root['meta'];
    if (meta is Map<String, dynamic>) return meta;
    if (meta is Map) return Map<String, dynamic>.from(meta);
    return null;
  }

  bool? _boolFromMeta(Map<String, dynamic>? meta, String key) {
    if (meta == null) return null;
    final value = meta[key];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  int? _intFromMeta(Map<String, dynamic>? meta, String key) {
    if (meta == null) return null;
    final value = meta[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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

    final data = _asMap(root['data']);
    if (data == null) return const [];

    for (final key in keys) {
      final nested = data[key];
      if (nested is List) return nested;
    }

    return const [];
  }

  Future<void> _saveSnacksLocal(List<CommunitySnack> snacks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _snacksStorageKey,
      jsonEncode(snacks.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<CommunitySnack>> _readSnacksLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snacksStorageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => CommunitySnack.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _saveAudioHacksLocal(List<AudioHack> hacks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _audioStorageKey,
      jsonEncode(hacks.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<AudioHack>> _readAudioHacksLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_audioStorageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => AudioHack.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _saveSharesLocal(List<IngredientShare> shares) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sharesStorageKey,
      jsonEncode(shares.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<IngredientShare>> _readSharesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sharesStorageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => IngredientShare.fromMap(Map<String, dynamic>.from(item)))
        .toList();
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
}

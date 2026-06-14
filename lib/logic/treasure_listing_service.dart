import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:trusted_circle_demo/models/treasure_listing.dart';

class TreasureListingService {
  TreasureListingService._();

  static final TreasureListingService instance = TreasureListingService._();
  static const String _storageKey = 'treasure_listings.v1';
  static const String _draftStorageKey = 'treasure_upload_draft.v1';

  List<TreasureListing>? _cache;

  Future<List<TreasureListing>> loadListings() async {
    if (_cache != null) {
      return List<TreasureListing>.from(_cache!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _cache = decoded
              .map((item) => TreasureListing.fromMap(Map<String, dynamic>.from(item)))
              .toList();
          return List<TreasureListing>.from(_cache!);
        }
      }
    } catch (_) {}

    _cache = _fallbackListings();
    await _persist();
    return List<TreasureListing>.from(_cache!);
  }

  Future<List<TreasureListing>> createListing(TreasureListing listing) async {
    final listings = await loadListings();
    listings.insert(0, listing);
    _cache = listings;
    await _persist();
    return List<TreasureListing>.from(_cache!);
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftStorageKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveDraft(Map<String, dynamic> draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftStorageKey, jsonEncode(draft));
    } catch (_) {}
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftStorageKey);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_cache?.map((item) => item.toMap()).toList() ?? const []),
      );
    } catch (_) {}
  }

  List<TreasureListing> _fallbackListings() {
    return [
      TreasureListing(
        id: 'treasure-1',
        title: 'Rotes Laufrad',
        category: 'Fahrzeuge',
        sizeAge: '2-4 Jahre',
        conditionKey: 'round2',
        distanceMeters: 200,
        colorLabel: 'Rot',
        note: 'Faellt im Alltag sofort auf und rollt noch super.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      TreasureListing(
        id: 'treasure-2',
        title: 'Winterjacke',
        category: 'Kleidung',
        sizeAge: 'Größe 92',
        conditionKey: 'studio',
        distanceMeters: 420,
        colorLabel: 'Navy',
        note: 'Sehr gepflegt und sofort bereit fuer die naechste Runde.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TreasureListing(
        id: 'treasure-3',
        title: 'Sandkasten-Set',
        category: 'Spielzeug',
        sizeAge: '3-5 Jahre',
        conditionKey: 'wild',
        distanceMeters: 650,
        colorLabel: 'Bunt',
        note: 'Mit Gebrauchsspuren, aber perfekt fuer draussen.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
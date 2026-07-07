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
    } catch (e) {
      // Continue with empty state when persisted data cannot be read.
    }

    _cache = [];
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
    } catch (e) {
      // Ignore corrupted drafts and continue with empty state.
    }
    return null;
  }

  Future<void> saveDraft(Map<String, dynamic> draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftStorageKey, jsonEncode(draft));
    } catch (e) {
      // Ignore transient local persistence failures.
    }
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftStorageKey);
    } catch (e) {
      // Ignore transient local persistence failures.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_cache?.map((item) => item.toMap()).toList() ?? const []),
      );
    } catch (e) {
      // Ignore transient local persistence failures.
    }
  }
}
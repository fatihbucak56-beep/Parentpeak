import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_client.dart';

class ShoppingBackendService {
  ShoppingBackendService({this.apiClient});

  final BackendApiClient? apiClient;

  static const String _storageKey = 'backend.shopping.v1';

  Future<List<Map<String, dynamic>>> fetchItems() async {
    if (apiClient != null) {
      try {
        final remote = await apiClient!.getList('/shopping');
        final items = remote
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await _persist(items);
        return items;
      } catch (_) {}
    }

    return _readLocal();
  }

  Future<Map<String, dynamic>> addItem({
    required String name,
    required String category,
  }) async {
    final item = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name,
      'checked': false,
      'category': category,
    };

    final current = await _readLocal();
    current.insert(0, item);
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.postJson('/shopping', item);
      } catch (_) {}
    }

    return item;
  }

  Future<void> updateChecked(String id, bool checked) async {
    final current = await _readLocal();
    final idx = current.indexWhere((i) => i['id'] == id);
    if (idx == -1) return;

    final updated = Map<String, dynamic>.from(current[idx]);
    updated['checked'] = checked;
    current[idx] = updated;
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.putJson('/shopping/$id', updated);
      } catch (_) {}
    }
  }

  Future<void> deleteItem(String id) async {
    final current = await _readLocal();
    current.removeWhere((i) => i['id'] == id);
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.delete('/shopping/$id');
      } catch (_) {}
    }
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

  Future<void> _persist(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(items));
  }
}

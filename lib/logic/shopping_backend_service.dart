import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_client.dart';
import 'contracts/shopping_contract.dart';

class ShoppingBackendService {
  ShoppingBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _storageKey = 'backend.shopping.v1';

  Future<List<Map<String, dynamic>>> fetchItems() async {
    lastSyncError = null;
    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(ShoppingContract.shoppingPath);
        final items = ShoppingContract.parseList(payload);
        await _persist(items);
        return items;
      } catch (e) {
        lastSyncError = 'Server-Sync fehlgeschlagen: $e';
      }
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
        final payload =
            await apiClient!.postJsonAny(ShoppingContract.shoppingPath, item);
        if (payload is Map) {
          final normalized =
              ShoppingContract.normalize(Map<String, dynamic>.from(payload));
          item['id'] = normalized['id'];
        }
      } catch (e) {
        lastSyncError = 'Shopping-Item konnte nicht auf Server gespeichert werden: $e';
      }
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
        await apiClient!.putJson(ShoppingContract.itemByIdPath(id), updated);
      } catch (e) {
        lastSyncError = 'Shopping-Status konnte nicht synchronisiert werden: $e';
      }
    }
  }

  Future<void> deleteItem(String id) async {
    final current = await _readLocal();
    current.removeWhere((i) => i['id'] == id);
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.delete(ShoppingContract.itemByIdPath(id));
      } catch (e) {
        lastSyncError = 'Shopping-Item konnte nicht auf Server gelöscht werden: $e';
      }
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

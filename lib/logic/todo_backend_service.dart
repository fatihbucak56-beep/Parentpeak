import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_client.dart';
import 'contracts/todo_contract.dart';

class TodoBackendService {
  TodoBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _storageKey = 'backend.todos.v1';

  Future<List<Map<String, dynamic>>> fetchTodos() async {
    lastSyncError = null;
    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(TodoContract.todosPath);
        final todos = TodoContract.parseList(payload);
        await _persist(todos);
        return todos;
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Server-Sync fehlgeschlagen',
          error: e,
        );
      }
    }

    final local = await _readLocal();
    if (local.isNotEmpty) {
      return local;
    }

    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> addTodo({
    required String title,
    required String assignee,
    required String category,
  }) async {
    lastSyncError = null;
    final todo = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'done': false,
      'assignee': assignee,
      'category': category,
    };

    final current = await _readOrSeed();
    current.insert(0, todo);
    await _persist(current);

    if (apiClient != null) {
      try {
        final requestBody = TodoContract.buildCreatePayload(
          title: title,
          assignee: assignee,
          category: category,
        );
        final payload = await apiClient!.postJsonAny(
          TodoContract.todosPath,
          requestBody,
        );
        final normalized = TodoContract.parseSingleItem(payload);
        if (normalized != null) {
          todo['id'] = normalized['id'];
        }
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Todo konnte nicht auf Server gespeichert werden',
          error: e,
        );
      }
    }

    return todo;
  }

  Future<void> updateDone(String id, bool done) async {
    lastSyncError = null;
    final current = await _readOrSeed();
    final idx = current.indexWhere((t) => t['id'] == id);
    if (idx == -1) return;

    final updated = Map<String, dynamic>.from(current[idx]);
    updated['done'] = done;
    current[idx] = updated;
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.putJson(
          TodoContract.todoByIdPath(id),
          TodoContract.buildUpdatePayload(done: done),
        );
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Todo-Status konnte nicht synchronisiert werden',
          error: e,
        );
      }
    }
  }

  Future<void> deleteTodo(String id) async {
    lastSyncError = null;
    final current = await _readOrSeed();
    current.removeWhere((t) => t['id'] == id);
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.delete(TodoContract.todoByIdPath(id));
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Todo konnte nicht auf Server gelöscht werden',
          error: e,
        );
      }
    }
  }

  String _friendlySyncError({
    required String action,
    required Object error,
  }) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('handshakeexception') ||
        raw.contains('tls') ||
        raw.contains('ssl') ||
        raw.contains('certificate')) {
      return 'Server-Verbindung aktuell nicht sicher verfuegbar. Daten bleiben lokal gespeichert.';
    }

    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('timed out') ||
        raw.contains('timeout')) {
      return 'Keine Verbindung zum Server. Daten bleiben lokal gespeichert.';
    }

    return '$action: $error';
  }

  Future<List<Map<String, dynamic>>> _readOrSeed() async {
    final current = await _readLocal();
    if (current.isNotEmpty) return current;
    return <Map<String, dynamic>>[];
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

  Future<void> _persist(List<Map<String, dynamic>> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(todos));
  }
}

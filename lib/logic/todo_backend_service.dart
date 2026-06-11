import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_client.dart';

class TodoBackendService {
  TodoBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _storageKey = 'backend.todos.v1';

  Future<List<Map<String, dynamic>>> fetchTodos() async {
    lastSyncError = null;
    if (apiClient != null) {
      try {
        final remote = await apiClient!.getList('/todos');
        final todos = remote
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await _persist(todos);
        return todos;
      } catch (e) {
        lastSyncError = 'Server-Sync fehlgeschlagen: $e';
      }
    }

    final local = await _readLocal();
    if (local.isNotEmpty) {
      return local;
    }

    final seeded = _seedTodos();
    await _persist(seeded);
    return seeded;
  }

  Future<Map<String, dynamic>> addTodo({
    required String title,
    required String assignee,
    required String category,
  }) async {
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
        await apiClient!.postJson('/todos', todo);
      } catch (e) {
        lastSyncError = 'Todo konnte nicht auf Server gespeichert werden: $e';
      }
    }

    return todo;
  }

  Future<void> updateDone(String id, bool done) async {
    final current = await _readOrSeed();
    final idx = current.indexWhere((t) => t['id'] == id);
    if (idx == -1) return;

    final updated = Map<String, dynamic>.from(current[idx]);
    updated['done'] = done;
    current[idx] = updated;
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.putJson('/todos/$id', updated);
      } catch (e) {
        lastSyncError = 'Todo-Status konnte nicht synchronisiert werden: $e';
      }
    }
  }

  Future<void> deleteTodo(String id) async {
    final current = await _readOrSeed();
    current.removeWhere((t) => t['id'] == id);
    await _persist(current);

    if (apiClient != null) {
      try {
        await apiClient!.delete('/todos/$id');
      } catch (e) {
        lastSyncError = 'Todo konnte nicht auf Server gelöscht werden: $e';
      }
    }
  }

  Future<List<Map<String, dynamic>>> _readOrSeed() async {
    final current = await _readLocal();
    if (current.isNotEmpty) return current;
    final seeded = _seedTodos();
    await _persist(seeded);
    return seeded;
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

  List<Map<String, dynamic>> _seedTodos() {
    return [
      {
        'id': 'todo-1',
        'title': 'Hausaufgaben machen',
        'done': false,
        'assignee': 'Leon',
        'category': 'Schule',
      },
      {
        'id': 'todo-2',
        'title': 'Arzttermin buchen',
        'done': false,
        'assignee': 'Mama',
        'category': 'Gesundheit',
      },
      {
        'id': 'todo-3',
        'title': 'Fußballschuhe kaufen',
        'done': true,
        'assignee': 'Papa',
        'category': 'Sport',
      },
      {
        'id': 'todo-4',
        'title': 'Geburtstag vorbereiten',
        'done': false,
        'assignee': 'Familie',
        'category': 'Ereignis',
      },
    ];
  }
}

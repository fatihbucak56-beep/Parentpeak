import 'backend_api_client.dart';
import 'contracts/todo_contract.dart';

class TodoBackendService {
  TodoBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  Future<List<Map<String, dynamic>>> fetchTodos() async {
    lastSyncError = null;
    if (apiClient == null) {
      lastSyncError = 'Todo-Backend ist nicht konfiguriert.';
      return const <Map<String, dynamic>>[];
    }

    try {
      final payload = await apiClient!.getJson(TodoContract.todosPath);
      return TodoContract.parseList(payload);
    } catch (e) {
      lastSyncError = _friendlySyncError(
        action: 'Server-Sync fehlgeschlagen',
        error: e,
      );
      return const <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> addTodo({
    required String title,
    required String assignee,
    required String category,
  }) async {
    lastSyncError = null;
    if (apiClient == null) {
      throw StateError('Todo-Backend ist nicht konfiguriert.');
    }

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
      if (normalized == null) {
        throw StateError('Ungueltige Todo-Antwort vom Server.');
      }
      return normalized;
    } catch (e) {
      lastSyncError = _friendlySyncError(
        action: 'Todo konnte nicht auf Server gespeichert werden',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> updateDone(String id, bool done) async {
    lastSyncError = null;
    if (apiClient == null) {
      throw StateError('Todo-Backend ist nicht konfiguriert.');
    }

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
      rethrow;
    }
  }

  Future<void> deleteTodo(String id) async {
    lastSyncError = null;
    if (apiClient == null) {
      throw StateError('Todo-Backend ist nicht konfiguriert.');
    }

    try {
      await apiClient!.delete(TodoContract.todoByIdPath(id));
    } catch (e) {
      lastSyncError = _friendlySyncError(
        action: 'Todo konnte nicht auf Server gelöscht werden',
        error: e,
      );
      rethrow;
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
      return 'Server-Verbindung aktuell nicht sicher verfuegbar.';
    }

    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('timed out') ||
        raw.contains('timeout')) {
      return 'Keine Verbindung zum Server.';
    }

    return '$action: $error';
  }
}

import 'backend_api_client.dart';
import 'contracts/shopping_contract.dart';

class ShoppingBackendService {
  ShoppingBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  Future<List<Map<String, dynamic>>> fetchItems() async {
    lastSyncError = null;
    if (apiClient == null) {
      lastSyncError = 'Shopping-Backend ist nicht konfiguriert.';
      return const <Map<String, dynamic>>[];
    }

    try {
      final payload = await apiClient!.getJson(ShoppingContract.shoppingPath);
      return ShoppingContract.parseList(payload);
    } catch (e) {
      lastSyncError = _friendlySyncError(
        action: 'Server-Sync fehlgeschlagen',
        error: e,
      );
      return const <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> addItem({
    required String name,
    required String category,
  }) async {
    lastSyncError = null;
    if (apiClient == null) {
      throw StateError('Shopping-Backend ist nicht konfiguriert.');
    }

    try {
      final requestBody = ShoppingContract.buildCreatePayload(
        name: name,
        category: category,
      );
      final payload = await apiClient!
          .postJsonAny(ShoppingContract.shoppingPath, requestBody);
      final normalized = ShoppingContract.parseSingleItem(payload);
      if (normalized == null) {
        throw StateError('Ungueltige Shopping-Antwort vom Server.');
      }
      return normalized;
    } catch (e) {
      lastSyncError = _friendlySyncError(
        action: 'Shopping-Item konnte nicht auf Server gespeichert werden',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> updateChecked(String id, bool checked) async {
    lastSyncError = null;
    if (apiClient == null) {
      throw StateError('Shopping-Backend ist nicht konfiguriert.');
    }

    try {
      await apiClient!.putJson(
        ShoppingContract.itemByIdPath(id),
        ShoppingContract.buildUpdatePayload(checked: checked),
      );
    } catch (e) {
      lastSyncError = _friendlySyncError(
        action: 'Shopping-Status konnte nicht synchronisiert werden',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    lastSyncError = null;
    if (apiClient == null) {
      throw StateError('Shopping-Backend ist nicht konfiguriert.');
    }

    try {
      await apiClient!.delete(ShoppingContract.itemByIdPath(id));
    } catch (e) {
      lastSyncError = _friendlySyncError(
        action: 'Shopping-Item konnte nicht auf Server gelöscht werden',
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

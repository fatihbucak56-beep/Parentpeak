import 'backend_api_client.dart';
import 'contracts/calendar_contract.dart';

class CalendarBackendService {
  CalendarBackendService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    lastSyncError = null;
    if (apiClient == null) {
      lastSyncError = 'Kalender-Backend ist nicht konfiguriert.';
      return <Map<String, dynamic>>[];
    }

    try {
      final payload = await apiClient!.getJson(CalendarContract.eventsPath);
      return CalendarContract.parseList(payload);
    } catch (e) {
      lastSyncError = 'Server derzeit nicht erreichbar.';
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> addEvent(Map<String, dynamic> event) async {
    lastSyncError = null;
    if (apiClient == null) {
      throw StateError('Kalender-Backend ist nicht konfiguriert.');
    }

    try {
      await apiClient!.postJsonAny(
        CalendarContract.eventsPath,
        CalendarContract.buildCreatePayload(event),
      );
    } catch (e) {
      lastSyncError = 'Termin konnte nicht gespeichert werden.';
      rethrow;
    }
  }
}

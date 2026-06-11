import 'package:trusted_circle_demo/config/api_config.dart';

import 'backend_api_client.dart';
import 'calendar_backend_service.dart';
import 'shopping_backend_service.dart';
import 'todo_backend_service.dart';

class BackendServiceFactory {
  static BackendApiClient? createApiClient() {
    final baseUrl = APIConfig.getBackendBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }

    return BackendApiClient(
      baseUrl: baseUrl,
      authToken: APIConfig.getBackendApiToken(),
    );
  }

  static TodoBackendService createTodoService() {
    return TodoBackendService(apiClient: createApiClient());
  }

  static ShoppingBackendService createShoppingService() {
    return ShoppingBackendService(apiClient: createApiClient());
  }

  static CalendarBackendService createCalendarService() {
    return CalendarBackendService(apiClient: createApiClient());
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/backend_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AuthService.logout triggers FCM token unregister for current user',
      () async {
    SharedPreferences.setMockInitialValues({});

    final prevFactory = AuthService.backendApiClientFactory;
    final prevUnregister = AuthService.fcmUnregisterHandler;

    final fakeClient = BackendApiClient(baseUrl: 'http://localhost:3000');
    String? capturedUserId;
    var unregisterCalls = 0;

    AuthService.backendApiClientFactory = () => fakeClient;
    AuthService.fcmUnregisterHandler = ({
      required BackendApiClient apiClient,
      required String userId,
    }) async {
      unregisterCalls += 1;
      capturedUserId = userId;
    };

    try {
      await AuthService.instance.debugSeedSessionForTesting();
      final seededUser = AuthService.instance.currentUser;
      expect(seededUser, isNotNull);

      await AuthService.instance.logout();

      expect(unregisterCalls, 1);
      expect(capturedUserId, seededUser!.uid);
      expect(AuthService.instance.currentUser, isNull);
    } finally {
      AuthService.backendApiClientFactory = prevFactory;
      AuthService.fcmUnregisterHandler = prevUnregister;
    }
  });
}

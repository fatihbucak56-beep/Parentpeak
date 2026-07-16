import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parentpeak/logic/revocation_service.dart';
import 'package:parentpeak/logic/secure_storage.dart';

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

void main() {
  group('RevocationService', () {
    late RevocationService svc;
    late _FakeSecureStorage secureStorage;

    setUp(() {
      secureStorage = _FakeSecureStorage();
      secureStorage.write(key: 'ABACUS_API_TOKEN', value: 'token-123');
    });

    test('revokeDevice sends authenticated revoke request', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.example.com/devices/uuid-123/revoke');
        expect(request.headers['authorization'], 'Bearer token-123');
        return http.Response('', 200);
      });

      svc = RevocationService(
        baseUrl: 'https://api.example.com',
        client: client,
        secureStorage: secureStorage,
      );

      final ok = await svc.revokeDevice('uuid-123', 'Reason');
      expect(ok, isTrue);
    });

    test('revokeDevice throws when server rejects the request', () async {
      final client = MockClient((request) async {
        return http.Response('denied', 403);
      });

      svc = RevocationService(
        baseUrl: 'https://api.example.com',
        client: client,
        secureStorage: secureStorage,
      );

      expect(
        () => svc.revokeDevice('uuid-123', 'Reason'),
        throwsA(isA<Object>()),
      );
    });
  });
}

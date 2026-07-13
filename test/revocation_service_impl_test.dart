
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:trusted_circle_demo/logic/revocation_service_impl.dart';
import 'package:trusted_circle_demo/logic/secure_storage.dart';

class FakeStorage implements SecureStorage {
  final Map<String, String> _data = {};
  @override
  Future<String?> read({required String key}) async => _data[key];
  @override
  Future<void> write({required String key, required String value}) async => _data[key] = value;
  @override
  Future<void> delete({required String key}) async => _data.remove(key);
}

// We'll use MockClient from package:http/testing.dart in tests
void main() {
  group('RevocationServiceImpl', () {
    late FakeStorage storage;

    setUp(() {
      storage = FakeStorage();
    });

    test('throws when token missing', () async {
      final client = MockClient((req) async => http.Response('', 500));
      final svc = RevocationServiceImpl(baseUrl: 'https://api.example.com', client: client, secureStorage: storage);

      expect(() => svc.revokeDevice('uuid', 'reason'), throwsA(isA<RevocationException>()));
    });

    test('returns true on 200', () async {
      await storage.write(key: 'ABACUS_API_TOKEN', value: 'tok');
      final client = MockClient((req) async => http.Response('ok', 200));
      final svc = RevocationServiceImpl(baseUrl: 'https://api.example.com', client: client, secureStorage: storage);

      final ok = await svc.revokeDevice('uuid-1', 'reason');
      expect(ok, isTrue);
    });

    test('throws on non-200', () async {
      await storage.write(key: 'ABACUS_API_TOKEN', value: 'tok');
      final client = MockClient((req) async => http.Response('error', 500));
      final svc = RevocationServiceImpl(baseUrl: 'https://api.example.com', client: client, secureStorage: storage);

      expect(() => svc.revokeDevice('uuid-1', 'reason'), throwsA(isA<RevocationException>()));
    });

    test('throws on timeout', () async {
      await storage.write(key: 'ABACUS_API_TOKEN', value: 'tok');
      final client = MockClient((req) async {
        // simulate a long delay
        await Future.delayed(const Duration(seconds: 2));
        return http.Response('ok', 200);
      });
      final svc = RevocationServiceImpl(baseUrl: 'https://api.example.com', client: client, secureStorage: storage, timeout: const Duration(milliseconds: 10));

      expect(() => svc.revokeDevice('uuid-1', 'reason'), throwsA(isA<RevocationException>()));
    });
  });
}

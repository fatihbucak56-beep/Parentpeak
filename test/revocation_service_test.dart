import 'package:flutter_test/flutter_test.dart';
import 'package:trusted_circle_demo/logic/revocation_service.dart';

void main() {
  group('RevocationService (demo)', () {
    late RevocationService svc;

    setUp(() {
      svc = RevocationService(baseUrl: 'https://api.example.com', delay: const Duration(milliseconds: 10));
    });

    test('revokeDevice returns true for normal uuid', () async {
      final ok = await svc.revokeDevice('uuid-123', 'Reason');
      expect(ok, isTrue);
    });

    test('revokeDevice returns false for fail-uuid', () async {
      final ok = await svc.revokeDevice('fail-uuid', 'Reason');
      expect(ok, isFalse);
    });
  });
}

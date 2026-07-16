import 'dart:async';

import 'package:http/http.dart' as http;

import 'revocation_service_impl.dart';
import 'secure_storage.dart';

/// Thin compatibility wrapper around the production revocation client.
class RevocationService {
  final RevocationServiceImpl _impl;

  RevocationService({
    required String baseUrl,
    http.Client? client,
    SecureStorage? secureStorage,
  }) : _impl = RevocationServiceImpl(
          baseUrl: baseUrl,
          client: client,
          secureStorage: secureStorage,
        );

  Future<bool> revokeDevice(String deviceUuid, String reason) async {
    return _impl.revokeDevice(deviceUuid, reason);
  }

  Future<void> localWipe() => _impl.localWipe();

  void dispose() => _impl.dispose();
}

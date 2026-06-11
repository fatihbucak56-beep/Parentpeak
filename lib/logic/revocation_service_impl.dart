import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'secure_storage.dart';

class RevocationException implements Exception {
  final String message;
  RevocationException(this.message);
  @override
  String toString() => 'RevocationException: $message';
}

/// Production-ready implementation of the revocation API client.
class RevocationServiceImpl {
  final String baseUrl;
  final http.Client _client;
  final SecureStorage _secureStorage;
  final Duration timeout;

  RevocationServiceImpl({
    required this.baseUrl,
    http.Client? client,
    SecureStorage? secureStorage,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorageAdapter();

  Future<bool> revokeDevice(String deviceUuid, String reason) async {
    final authToken = await _secureStorage.read(key: 'ABACUS_API_TOKEN');
    if (authToken == null || authToken.isEmpty) {
      throw RevocationException('Missing auth token');
    }

    final url = Uri.parse('$baseUrl/devices/$deviceUuid/revoke');
    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'reason': reason}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return true;
      }

      // Non-200 responses are considered failures with message
      final body = response.body.isNotEmpty ? response.body : '<empty>';
      throw RevocationException('Server returned ${response.statusCode}: $body');
    } on TimeoutException {
      throw RevocationException('Request to $url timed out');
    } on http.ClientException catch (e) {
      throw RevocationException('HTTP client error: ${e.message}');
    }
  }

  /// Remove sensitive local data (example implementation)
  Future<void> localWipe() async {
    final keysToRemove = ['ABACUS_API_TOKEN', 'user_session', 'private_key'];
    for (final k in keysToRemove) {
      await _secureStorage.delete(key: k);
    }
  }

  void dispose() => _client.close();
}

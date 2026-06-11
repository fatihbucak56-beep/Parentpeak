import 'dart:async';

/// Simple demo stub used by the demo app. Production implementation is
/// provided by `RevocationServiceImpl` in `revocation_service_impl.dart`.
class RevocationService {
  final String baseUrl;
  final Duration delay;

  RevocationService({required this.baseUrl, this.delay = const Duration(seconds: 1)});

  /// Simulate revoke - succeeds for non-empty uuids except "fail-uuid"
  Future<bool> revokeDevice(String deviceUuid, String reason) async {
    await Future.delayed(delay);
    if (deviceUuid == 'fail-uuid') return false;
    return true;
  }
}

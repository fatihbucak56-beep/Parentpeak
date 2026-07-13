import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureStorageAdapter implements SecureStorage {
  static final Map<String, String> _fallbackStore = <String, String>{};

  final FlutterSecureStorage _inner;
  const FlutterSecureStorageAdapter([FlutterSecureStorage? inner]) : _inner = inner ?? const FlutterSecureStorage();

  bool get _useFallbackStorage => kIsWeb || defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Future<String?> read({required String key}) async {
    if (_useFallbackStorage) {
      return _fallbackStore[key];
    }

    try {
      return await _inner.read(key: key);
    } catch (_) {
      return _fallbackStore[key];
    }
  }

  @override
  Future<void> write({required String key, required String value}) async {
    if (_useFallbackStorage) {
      _fallbackStore[key] = value;
      return;
    }

    try {
      await _inner.write(key: key, value: value);
    } catch (_) {
      _fallbackStore[key] = value;
    }
  }

  @override
  Future<void> delete({required String key}) async {
    if (_useFallbackStorage) {
      _fallbackStore.remove(key);
      return;
    }

    try {
      await _inner.delete(key: key);
    } catch (_) {
      _fallbackStore.remove(key);
    }
  }
}

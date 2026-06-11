import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureStorageAdapter implements SecureStorage {
  final FlutterSecureStorage _inner;
  const FlutterSecureStorageAdapter([FlutterSecureStorage? inner]) : _inner = inner ?? const FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) => _inner.read(key: key);

  @override
  Future<void> write({required String key, required String value}) => _inner.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _inner.delete(key: key);
}

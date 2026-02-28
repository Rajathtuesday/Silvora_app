// lib/storage/jwt_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtStore {
  static final JwtStore instance = JwtStore._internal();
  JwtStore._internal();
  static const _kAccess = 'jwt_access';
  static const _kRefresh = 'jwt_refresh';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _kAccess);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _kRefresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}

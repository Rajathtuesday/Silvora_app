// lib/services/auth_service.dart
import 'package:silvora_app/api/auth_api.dart';
import 'package:silvora_app/storage/jwt_store.dart';

class AuthService {
  final AuthApi _api;
  final JwtStore _store;

  AuthService({
    AuthApi? api,
    JwtStore? store,
  })  : _api = api ?? AuthApi(),
        _store = store ?? JwtStore();

  Future<void> login(String username, String password) async {
    final tokens = await _api.login(username: username, password: password);
    await _store.saveTokens(tokens.access, tokens.refresh);
  }

  Future<String?> getAccessToken() => _store.getAccessToken();

  Future<void> logout() => _store.clear();
}

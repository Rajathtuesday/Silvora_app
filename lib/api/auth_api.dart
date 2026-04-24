// lib/api/auth_api.dart
import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthApi {
  final Dio _dio;

  AuthApi({String? accessToken})
      : _dio = ApiClient(accessToken: accessToken).dio;

  /// POST /api/auth/token/
  Future<({String access, String refresh})> login({
    required String username,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/api/auth/token/',
      data: {
        'username': username,
        'password': password,
      },
    );

    final data = resp.data as Map<String, dynamic>;
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;

    if (access == null || refresh == null) {
      throw Exception('Token response missing access/refresh');
    }

    return (access: access, refresh: refresh);
  }
}

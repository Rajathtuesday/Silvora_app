// lib/api/api_client.dart
import 'package:dio/dio.dart';
import '../state/secure_state.dart';


class ApiClient {
  // IMPORTANT: use your PC's LAN IP and Django port
  static final String baseUrl = SecureState.serverUrl;

  final Dio dio;

  ApiClient({String? accessToken})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    if (accessToken != null && accessToken.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }
    dio.options.headers['Content-Type'] = 'application/json';
  }
}

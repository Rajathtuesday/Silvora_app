import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/secure_state.dart';

class AuthClient {
  static Future<http.Response> _retryWithRefresh(
    Future<http.Response> Function(Map<String, String>) requestFunc,
  ) async {
    http.Response res = await requestFunc(SecureState.authHeader());

    if (res.statusCode == 401 && SecureState.refreshToken != null) {
      final refreshRes = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/token/refresh/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": SecureState.refreshToken}),
      );

      if (refreshRes.statusCode == 200) {
        final data = jsonDecode(refreshRes.body);
        SecureState.accessToken = data["access"];
        if (data.containsKey("refresh")) {
          SecureState.refreshToken = data["refresh"];
        }
        res = await requestFunc(SecureState.authHeader());
      } else {
        SecureState.logout();
      }
    }

    return res;
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _retryWithRefresh((authHeaders) {
      final merged = {...?headers, ...authHeaders};
      return http.get(url, headers: merged);
    });
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    return _retryWithRefresh((authHeaders) {
      final merged = {...?headers, ...authHeaders};
      return http.post(url, headers: merged, body: body);
    });
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    return _retryWithRefresh((authHeaders) {
      final merged = {...?headers, ...authHeaders};
      return http.delete(url, headers: merged);
    });
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload);
      final exp = map['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= (exp - 10); // 10s buffer
    } catch (_) {
      return true;
    }
  }

  static Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = SecureState.accessToken;
    if (token != null && _isTokenExpired(token) && SecureState.refreshToken != null) {
      final refreshRes = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/token/refresh/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": SecureState.refreshToken}),
      );
      if (refreshRes.statusCode == 200) {
        final data = jsonDecode(refreshRes.body);
        SecureState.accessToken = data["access"];
        if (data.containsKey("refresh")) {
          SecureState.refreshToken = data["refresh"];
        }
      } else {
        SecureState.logout();
      }
    }
    
    request.headers.addAll(SecureState.authHeader());
    return request.send();
  }
}

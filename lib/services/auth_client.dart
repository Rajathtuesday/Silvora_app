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

  static Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.addAll(SecureState.authHeader());
    
    // We can't easily retry a streamed request because the body stream might be consumed.
    // For MultipartRequest (upload chunk), we just send it. If 401, it fails.
    // To properly support multipart retry, we'd have to recreate the request.
    // Given the complexity, we'll assume short-lived multipart chunks, or we refresh beforehand.
    // A better way is to do a proactive refresh check, but for MVP we just send.
    
    return request.send();
  }
}

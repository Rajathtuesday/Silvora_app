import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/secure_state.dart';
import '../storage/jwt_store.dart';

class AuthClient {
  // Single-flight refresh: concurrent 401s share ONE refresh call. Without
  // this, several requests refreshing at once each rotate the refresh token;
  // the backend blacklists the old one, so all but the first fail and the user
  // is logged out at random. One in-flight refresh fixes that.
  static Future<bool>? _refreshInFlight;

  static Future<bool> _refreshTokens() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static Future<bool> _doRefresh() async {
    final refresh = SecureState.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/token/refresh/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": refresh}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        SecureState.accessToken = data["access"];
        if (data.containsKey("refresh")) {
          SecureState.refreshToken = data["refresh"];
        }
        // Persist rotated tokens so the session survives an app restart.
        await JwtStore().saveTokens(
          SecureState.accessToken!,
          SecureState.refreshToken ?? refresh,
        );
        return true;
      }
    } catch (_) {
      // fall through to logout
    }
    SecureState.logout();
    await JwtStore().clear();
    return false;
  }

  static Future<http.Response> _retryWithRefresh(
    Future<http.Response> Function(Map<String, String>) requestFunc,
  ) async {
    var res = await requestFunc(SecureState.authHeader());

    if (res.statusCode == 401 && SecureState.refreshToken != null) {
      final ok = await _refreshTokens();
      if (ok) res = await requestFunc(SecureState.authHeader());
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
      await _refreshTokens();
    }
    request.headers.addAll(SecureState.authHeader());
    return request.send();
  }
}

// // lib/services/auth_service.dart

// // import 'package:silvora_app/storage/jwt_store.dart';

// // class AuthService {
// //   final AuthApi _api;
// //   final JwtStore _store;

// //   AuthService({
// //     AuthApi? api,
// //     JwtStore? store,
// //   })  : _api = api ?? AuthApi(),
// //         _store = store ?? JwtStore();

// //   Future<void> login(String username, String password) async {
// //     final tokens = await _api.login(username: username, password: password);
// //     await _store.saveTokens(tokens.access, tokens.refresh);
// //   }

// //   Future<String?> getAccessToken() => _store.getAccessToken();

// //   Future<void> logout() => _store.clear();
// // }
// // ================================================================================
// // lib/services/auth_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../state/secure_state.dart';
// import '../../_archive/storage/jwt_store.dart';

// class AuthService {
//   Future<void> login(String email, String password) async {
//     final res = await http.post(
//       Uri.parse("${SecureState.serverBaseUrl}/api/auth/token/"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "username": email,
//         "password": password,
//       }),
//     );

//     if (res.statusCode != 200) {
//       throw Exception("Login failed");
//     }

//     final data = jsonDecode(res.body);
//     await JwtStore().saveTokens(data['access'], data['refresh']);
//     SecureState.setTokens(data['access'], data['refresh']);
//   }
// }


// // ===============================================================================
// // lib/state/secure_state.dart
// import 'dart:typed_data';
// import 'package:silvora_app/__archive_disabled/crypto/master_key.dart';

// import '../../_archive/storage/jwt_store.dart';

// class SecureState {
//   // =========================
//   // API CONFIG (ONE PLACE ONLY)
//   // =========================
//   static const String serverBaseUrl =
//       "https://silvora-demo.onrender.com";

//   // =========================
//   // AUTH (JWT)
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;

//   static final JwtStore _jwtStore = JwtStore();

//   // =========================
//   // VAULT (memory-only)
//   // =========================
//   static Uint8List? _masterKey;

//   static bool get isVaultUnlocked => _masterKey != null;

//   // =========================
//   // SESSION RESTORE
//   // =========================
//   static Future<void> restoreSession() async {
//     accessToken = await _jwtStore.getAccessToken();
//     refreshToken = await _jwtStore.getRefreshToken();
//   }

//   static void setTokens(String access, String refresh) {
//     accessToken = access;
//     refreshToken = refresh;
//   }

//   // =========================
//   // AUTH HEADERS
//   // =========================
//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw StateError("Not authenticated");
//     }
//     return {"Authorization": "Bearer $accessToken"};
//   }

//   // =========================
//   // VAULT CONTROL
//   // =========================
//   static void setMasterKey(Uint8List key) {
//     _masterKey = key;
//   }

//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("Vault not unlocked");
//     }
//     return _masterKey!;
//   }

//   // =========================
//   // LOGOUT
//   // =========================
//   static Future<void> logout() async {
//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }
//     _masterKey = null;

//     accessToken = null;
//     refreshToken = null;

//     await _jwtStore.clear();
//   }


// static Future<void> unlockVault(String password) async {
//   final key = await MasterKey.deriveFromPassword(password);
//   setMasterKey(key);
// }
// }

// // lib/state/secure_state.dart

// /// Simple singleton-style holder for the *current session*.
// /// In a real app you would replace this with something more robust
// /// (provider, riverpod, bloc, etc.), but this is perfect for now.
// class SecureState {
//   /// JWT access token for current session
//   static String? accessToken;

//   /// ----- Master key metadata from backend -----
//   /// This is the encrypted master key (hex) stored on server
//   static String? masterKeyEncryptedHex;
//   static String? masterKeyEncryptedB64;  

//   /// PBKDF2 salt (Base64) used to derive KEK from password
//   static String? masterKeySaltB64;

//   /// XChaCha20-Poly1305 nonce (Base64) used for master-key encryption
//   static String? masterKeyNonceB64;

//   /// Algorithm string (should be "XCHACHA20_POLY1305")
//   static String? masterKeyAlgo;

//   /// Place where we will later store the *decrypted* master key (bytes).
//   /// For now we won't fill this yet.
//   static List<int>? masterKeyBytes;
// }


// class SecureState {
//   // ===== Server =====
//   static String serverUrl = "http://192.168.0.139:8000";

//   // ===== Auth JWT =====
//   static String? accessToken;
//   static String? refreshToken;

//   // ===== Encrypted Master Key from server =====
//   static String? masterKeyEncryptedHex;
//   static String? masterKeyEncryptedB64;
//   static String? masterKeySaltB64;
//   static String? masterKeyNonceB64;
//   static String? masterKeyAlgo;

//   // ===== Decrypted Master Key stored only in RAM =====
//   static Uint8List? masterKeyBytes;
// }

// -------------------------------------------second here ----------------------
// import 'dart:typed_data';

// /// Global in-memory state used during development.
// /// NO SECRETS should live here in production.
// class SecureState {
//   // 🔌 Your Django server base URL
//   //
//   // If your laptop's IP is different, update this:
//   // e.g. "http://192.168.1.7:8000" or "http://192.168.0.139:8000"
//   static String serverUrl = "http://192.168.0.139:8000";

//   // 🔑 Auth tokens (set in LoginScreen after /api/auth/token/)
//   static String? accessToken;
//   static String? refreshToken;

//   // =====================================================================
//   // DEV MASTER KEY (HARD-CODED) – FOR TESTING ONLY
//   // =====================================================================
//   //
//   // This is the SAME master key you are using in Python:
//   // 45fbd77e7848fe882b5d43f5c6ce88b66b9b7ae5799b235c7d5d66294b08505d
//   //
//   // In production this MUST NOT be hard-coded.
//   // We'll later replace this with real master-key decryption.
//   static const String devMasterKeyHex =
//       "45fbd77e7848fe882b5d43f5c6ce88b66b9b7ae5799b235c7d5d66294b08505d";

//   static const String hardcodedMasterKeyHex =
//       '45fbd77e7848fe882b5d43f5c6ce88b66b9b7ae5799b235c7d5d66294b08505d';

//   /// Master key as raw bytes, derived from [devMasterKeyHex].
//   static Uint8List get devMasterKeyBytes => _hexToBytes(devMasterKeyHex);


//   // =====================================================================
//   // INTERNAL HELPERS
//   // =====================================================================

//   /// Convert hex string → bytes.
//   static Uint8List _hexToBytes(String hex) {
//     final cleaned = hex.trim();
//     if (cleaned.length % 2 != 0) {
//       throw ArgumentError("Hex string must have even length");
//     }

//     final result = Uint8List(cleaned.length ~/ 2);
//     for (var i = 0; i < cleaned.length; i += 2) {
//       final byteStr = cleaned.substring(i, i + 2);
//       result[i ~/ 2] = int.parse(byteStr, radix: 16);
//     }
//     return result;
//   }
// }
// ----------------------------------------third here------------------------------------------

// // lib/state/secure_state.dart

// /// Centralized secure session + server configuration.
// /// MVP: Tokens stored in memory (clears on app restart)
// /// Phase B: Persist tokens using flutter_secure_storage or keystore
// class SecureState {
//   /// ------------ SERVER CONFIG ------------
//   /// ONLY one should be active at a time.

//   // 🏠 For local development (same WiFi)
//   // static String serverUrl = 'http://192.168.0.139:8000';

//   // 🌍 For remote access using ngrok — MUST be HTTPS
//   static String serverUrl = 'https://leakily-potted-babette.ngrok-free.dev';

//   /// Validate config at runtime
//   static void validateServerUrl() {
//     if (!serverUrl.startsWith("http")) {
//       throw Exception("❌ Invalid serverUrl: $serverUrl");
//     }
//   }

//   /// ------------ TOKENS ------------
//   static String? accessToken;
//   static String? refreshToken;

//   /// Auth header builder — avoids null mistakes
//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw Exception("❌ Access token missing — login required!");
//     }
//     return {"Authorization": "Bearer $accessToken"};
//   }

//   /// ------------ E2EE Future Fields ------------
//   /// Phase C: These will manage encrypted master keys & salts
//   static String? encryptedMasterKeyHex;
//   static String? encryptedMasterKeyB64;
//   static String? masterKeySaltB64;
//   static String? masterKeyNonceB64;
//   static String? masterKeyAlgo;

//   /// Clear everything on logout
//   static void reset() {
//     accessToken = null;
//     refreshToken = null;
//     encryptedMasterKeyHex = null;
//     encryptedMasterKeyB64 = null;
//     masterKeySaltB64 = null;
//     masterKeyNonceB64 = null;
//     masterKeyAlgo = null;
//   }
// }



// ===-------------------------------------------------------------===


// import 'dart:typed_data';

// class SecureState {
//   /// ========= 🌍 SERVER ENDPOINT =========
//   /// Change only this (local vs production)
//   static String serverUrl = "https://alpha.silvora.cloud";

//   static void validateServerUrl() {
//     if (!serverUrl.startsWith("http")) {
//       throw Exception("Invalid serverUrl: $serverUrl");
//     }
//   }

//   /// ========= 🔐 AUTH TOKENS =========
//   static String? accessToken;
//   static String? refreshToken;

//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw Exception("Missing access token — login required!");
//     }
//     return {
//       "Authorization": "Bearer $accessToken",
//       "Accept": "application/json",
//     };
//   }

//   /// ========= 🧠 E2EE — IN-MEMORY KEYS =========
//   ///
//   /// ⚠️ NEVER persist these beyond session!
//   /// Derived after login, cleared on logout or app close.
//   static Uint8List? masterKey; // 32-bytes — core E2E crypto material

//   /// Optional: in future we may store device key / KEK in SecureStorage.
//   /// For v1: ALWAYS derive KEK from password only.

//   /// ========= 📂 FILE CRYPTO CONTEXT =========
//   /// Used during a single upload/download session.
//   static Uint8List? currentFileKey;  // ephemeral 32bytes
//   static Uint8List? currentFileNonce; // ephemeral 12/24 bytes

//   /// ========= 🧹 MEMORY PURGE =========
//   static void purgeCryptoMemory() {
//     if (masterKey != null) {
//       masterKey!.fillRange(0, masterKey!.length, 0);
//       masterKey = null;
//     }
//     if (currentFileKey != null) {
//       currentFileKey!.fillRange(0, currentFileKey!.length, 0);
//       currentFileKey = null;
//     }
//     if (currentFileNonce != null) {
//       currentFileNonce!.fillRange(0, currentFileNonce!.length, 0);
//       currentFileNonce = null;
//     }
//   }

//   /// ========= 🚪 FULL LOGOUT =========
//   static void reset() {
//     accessToken = null;
//     refreshToken = null;
//     purgeCryptoMemory();
//   }
// }


// -------------------------------------------------------------------------------------------------------------------------------//

// lib/state/secure_state.dart

// Global runtime state for authenticated + encrypted session.
// Nothing stored here should ever be persisted unencrypted.
//
// On logout: ALWAYS call SecureState.reset()
// class SecureState {
  // ============================================================
  // 🔗 SERVER CONFIG
  // ============================================================

  /// Remote Django server URL (must be HTTPS in production!)
  /// Example:
  /// static String serverUrl = 'https://alpha.silvora.cloud';
  ///
  /// For now using ngrok until Cloudflare Pages → Django backend infrastructure is ready
// 
// static String serverUrl = "https://silvora-demo.onrender.com";


// static String serverUrl = "http://10.0.2.2:8000";


//   /// Quick sanity check to prevent accidental empty / invalid URLs
//   static void validateServerUrl() {
//     if (!serverUrl.startsWith("http")) {
//       throw Exception("❌ Invalid serverUrl: $serverUrl");
//     }
//   }

//   // ============================================================
//   // 🔑 AUTH TOKENS
//   // ============================================================

//   /// JWT access token — can expire
//   static String? accessToken;

//   /// Refresh token — can be used to renew access token
//   static String? refreshToken;

//   /// Build Authorization header when authenticated
//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw StateError("Auth error: Access token is missing!");
//     }
//     return {"Authorization": "Bearer $accessToken","Content-Type": "application/json",};
//   }

//   // ============================================================
//   // 🧠 ENCRYPTION STATE (E2EE)
//   // ============================================================

//   /// Raw 32-byte plaintext master key — kept only in memory
//   ///
//   /// ⚠️ DO NOT persist this locally without a secure vault solution
//   static List<int>? masterKeyBytes;

//   /// Hex-encoded encrypted master key stored on server
//   static String? encryptedMasterKeyHex;

//   /// PBKDF2 / Argon2 salt (Base64)
//   static String? masterKeySaltB64;

//   /// AEAD nonce used to encrypt master key (Base64)
//   static String? masterKeyNonceB64;

//   /// AEAD algorithm used for master key encryption
//   static String? masterKeyAlgo;

//   /// Version flag for future migrations and backwards support
//   static int? masterKeyVersion;

//   /// Convenience — returns true if user login session has E2EE ready
//   static bool get hasMasterKey => masterKeyBytes != null;

//   // ============================================================
//   // 🚪 SESSION RESET
//   // ============================================================

//   /// Wipe EVERYTHING from memory when logging out
//   static void reset() {
//     accessToken = null;
//     refreshToken = null;

//     masterKeyBytes = null;
//     encryptedMasterKeyHex = null;
//     masterKeySaltB64 = null;
//     masterKeyNonceB64 = null;
//     masterKeyAlgo = null;
//     masterKeyVersion = null;
//   }
// }




// ======================================================================================================
// lib/state/secure_state.dart
// import 'dart:typed_data';

/// Global runtime state for authenticated + encrypted session.
/// Nothing stored here should ever be persisted unencrypted.
///
/// On logout: ALWAYS call SecureState.reset()
// class SecureState {
//   // ============================================================
//   // 🔗 SERVER CONFIG
//   // ============================================================

//   static String serverUrl = "http://10.0.2.2:8000";

//   static void validateServerUrl() {
//     if (!serverUrl.startsWith("http")) {
//       throw Exception("❌ Invalid serverUrl: $serverUrl");
//     }
//   }

//   // ============================================================
//   // 🔑 AUTH TOKENS
//   // ============================================================

//   static String? accessToken;
//   static String? refreshToken;

//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw StateError("Auth error: Access token is missing!");
//     }
//     return {
//       "Authorization": "Bearer $accessToken",
//       "Content-Type": "application/json",
//     };
//   }

//   // ============================================================
//   // 🧠 ENCRYPTION STATE (E2EE)
//   // ============================================================

//   /// Raw 32-byte master key (PLAINTEXT, MEMORY ONLY)
//   static List<int>? masterKeyBytes;

//   static String? encryptedMasterKeyHex;
//   static String? masterKeySaltB64;
//   static String? masterKeyNonceB64;
//   static String? masterKeyAlgo;
//   static int? masterKeyVersion;

//   /// Vault readiness check
//   static bool get hasMasterKey => masterKeyBytes != null;

//   /// Safe master key getter
//   static Uint8List get masterKey {
//     if (masterKeyBytes == null) {
//       throw StateError(
//         "❌ Master key not loaded. User must unlock vault first.",
//       );
//     }
//     return Uint8List.fromList(masterKeyBytes!);
//   }

//   // ============================================================
//   // 🚪 SESSION RESET
//   // ============================================================

//   static void reset() {
//     accessToken = null;
//     refreshToken = null;

//     masterKeyBytes = null;
//     encryptedMasterKeyHex = null;
//     masterKeySaltB64 = null;
//     masterKeyNonceB64 = null;
//     masterKeyAlgo = null;
//     masterKeyVersion = null;
//   }
// }
// =========================================================================needs edit from top ================

// // lib/state/secure_state.dart
// import 'dart:typed_data';

// class SecureState {
//   // =========================================================
//   // API CONFIG
//   // =========================================================
//   static String serverUrl = "http://10.0.2.2:8000";

//   // =========================================================
//   // AUTH TOKENS (MEMORY ONLY)
//   // =========================================================
//   static String? accessToken;
//   static String? refreshToken;

//   static Map<String, String> authHeader() {
//     if (accessToken == null) return {};
//     return {
//       "Authorization": "Bearer $accessToken",
//     };
//   }

//   // =========================================================
//   // VAULT (MASTER KEY — MEMORY ONLY)
//   // =========================================================
//   static Uint8List? _masterKey;
//   static DateTime? _unlockedAt;

//   /// Unlock vault with decrypted master key
//   static void setMasterKey(Uint8List key) {
//     _masterKey = key;
//     _unlockedAt = DateTime.now();
//   }

//   /// Scoped access — master key NEVER escapes
//   static T withMasterKey<T>(
//     T Function(Uint8List key) fn,
//   ) {
//     if (_masterKey == null) {
//       throw StateError("Vault locked");
//     }
//     return fn(_masterKey!);
//   }

//   /// Whether password re-auth is mandatory (TTL expired)
//   static bool requiresPasswordReauth(Duration ttl) {
//     if (_unlockedAt == null) return true;
//     return DateTime.now().difference(_unlockedAt!) > ttl;
//   }

//   /// Explicit vault lock (zeroize memory)
//   static void lock() {
//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }
//     _masterKey = null;
//     _unlockedAt = null;
//   }

//   /// Full logout hard reset
//   static void logout() {
//     lock();
//     accessToken = null;
//     refreshToken = null;
//   }


// static void unlock(Uint8List key) {
//   setMasterKey(key);
// }

// static Uint8List get masterKey {
//   return requireMasterKey();
// }
// static Uint8List requireMasterKey() {
//   if (_masterKey == null) {
//     throw StateError("Vault locked");
//   }
//   return _masterKey!;
// }
// }
// ====================================================

// lib/state/secure_state.dart
// import 'dart:typed_data';

// class SecureState {
//   // =========================
//   // API CONFIG
//   // =========================
//   static String serverUrl = "http://10.0.2.2:8000";

//   // =========================
//   // AUTH
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;

//   static Map<String, String> authHeader() {
//     if (accessToken == null) return {};
//     return {"Authorization": "Bearer $accessToken"};
//   }

//   // =========================
//   // VAULT (MEMORY ONLY)
//   // =========================
//   static Uint8List? _masterKey;
//   static DateTime? _unlockedAt;

//   static bool get isUnlocked => _masterKey != null;

//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("🔒 Vault is locked");
//     }
//     return _masterKey!;
//   }

//   static void setMasterKey(Uint8List key) {
//     if (key.length != 32) {
//       throw StateError("Invalid master key length");
//     }
//     _masterKey = Uint8List.fromList(key);
//     _unlockedAt = DateTime.now();
//   }

//   static void lock() {**

//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }
//     _masterKey = null;
//     _unlockedAt = null;
//   }
// }
// =======================================================================
// lib/state/secure_state.dart
// import 'dart:typed_data';
// import '../storage/jwt_store.dart';

// class SecureState {
//   // =========================
//   // API CONFIG
//   // =========================
//   // static String serverUrl = "http://10.0.2.2:8000";
//   static String serverUrl = "https://silvora-demo.onrender.com";


//   // =========================
//   // AUTH
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;

//   static final JwtStore _jwtStore = JwtStore();

//   static Future<void> restoreSession() async {
//     accessToken = await _jwtStore.getAccessToken();
//     refreshToken = await _jwtStore.getRefreshToken();
//   }


//   static Map<String, String> authHeader() {
//     if (accessToken == null) return {};
//     return {
//       "Authorization": "Bearer $accessToken",
//     };
//   }

//   // =========================
//   // VAULT (memory-only)
//   // =========================
//   static Uint8List? _masterKey;
//   static DateTime? _unlockedAt;

//   static bool get isLocked =>_masterKey == null;

//   static void setMasterKey(Uint8List key) {
//     _masterKey = key;
//     _unlockedAt = DateTime.now();
//   }

//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("Vault locked");
//     }
//     return _masterKey!;
//   }

//   static bool requiresPasswordReauth(Duration ttl) {
//     if (_unlockedAt == null) return true;
//     return DateTime.now().difference(_unlockedAt!) > ttl;
//   }

//   static void lock() {
//     _masterKey?.fillRange(0, _masterKey!.length, 0);
//     _masterKey = null;
//     _unlockedAt = null;
//   }

//   static Future<void> fullLogout() async {
//   lock(); // wipe master key
//   accessToken = null;
//   refreshToken = null;
//   await _jwtStore.clear();
// }


// }
// ===============================================================================
// // lib/state/secure_state.dart
// import 'dart:typed_data';

// class SecureState {
//   // =========================
//   // API CONFIG
//   // =========================
//   static String serverUrl = "https://silvora-demo.onrender.com";

//   // =========================
//   // AUTH (memory-only)
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;

//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw StateError("Not authenticated");
//     }
//     return {
//       "Authorization": "Bearer $accessToken",
//     };
//   }

//   // =========================
//   // VAULT (memory-only)
//   // =========================
//   static Uint8List? _masterKey;
//   static DateTime? _unlockedAt;

//   static bool get isLocked => _masterKey == null;

//   static void setMasterKey(Uint8List key) {
//     _masterKey = key;
//     _unlockedAt = DateTime.now();
//   }

//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("Vault locked");
//     }
//     return _masterKey!;
//   }

//   static bool requiresPasswordReauth(Duration ttl) {
//     if (_unlockedAt == null) return true;
//     return DateTime.now().difference(_unlockedAt!) > ttl;
//   }

//   static void lock() {
//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }
//     _masterKey = null;
//     _unlockedAt = null;
//     accessToken = null;
//     refreshToken = null;
//   }
// }


// ===================================================================================================
// //lib/secure_state.dart
// import 'dart:typed_data';
// import '../storage/jwt_store.dart';

// class SecureState {
//   // =========================
//   // API CONFIG
//   // =========================
//   static String serverUrl = "https://silvora-demo.onrender.com";

//   // =========================
//   // AUTH (memory)
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;

//   static final JwtStore _jwtStore = JwtStore();

//   // =========================
//   // VAULT (memory-only)
//   // =========================
//   static Uint8List? _masterKey;
//   static DateTime? _unlockedAt;

//   static bool get isLocked => _masterKey == null;

//   // =========================
//   // SESSION RESTORE
//   // =========================
//   static Future<void> restoreSession() async {
//     accessToken = await _jwtStore.getAccessToken();
//     refreshToken = await _jwtStore.getRefreshToken();
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
//     _unlockedAt = DateTime.now();
//   }

//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("Vault locked");
//     }
//     return _masterKey!;
//   }

//   static bool requiresPasswordReauth(Duration ttl) {
//     if (_unlockedAt == null) return true;
//     return DateTime.now().difference(_unlockedAt!) > ttl;
//   }

//   // =========================
//   // VAULT LOCK
//   // =========================
//   static DateTime? _lastActiveAt;
//   static const Duration idleTimeout = Duration(minutes: 5);

//     static void markUserActive() {
//     _lastActiveAt = DateTime.now();
//   }

//   static bool shouldAutoLock() {
//     if (_lastActiveAt == null) return false;
//     return DateTime.now().difference(_lastActiveAt!) > idleTimeout;
//   }



//   // =========================
//   // FULL LOGOUT (ONE PLACE)
//   // =========================
//   // static Future<void> fullLogout() async {
//   //   // wipe vault
//   //   if (_masterKey != null) {
//   //     _masterKey!.fillRange(0, _masterKey!.length, 0);
//   //   }
//   //   _masterKey = null;
//   //   _unlockedAt = null;

//   //   // wipe tokens
//   //   accessToken = null;
//   //   refreshToken = null;
//   //   await _jwtStore.clear();
//   // }

//   // lib/state/secure_state.dart

// static void lock() {
//   if (_masterKey != null) {
//     _masterKey!.fillRange(0, _masterKey!.length, 0);
//   }
//   _masterKey = null;
//   _unlockedAt = null;
// }

// static Future<void> fullLogout() async {
//   lock();
//   accessToken = null;
//   refreshToken = null;
// }

// }
// ===================================================================
// // lib/state/secure_state.dart
// import 'dart:typed_data';
// import '../storage/jwt_store.dart';

// class SecureState {
//   // =====================================================
//   // API CONFIG
//   // =====================================================
//   static String serverUrl = "https://silvora-demo.onrender.com";

//   // =====================================================
//   // AUTH (JWT – memory + secure storage)
//   // =====================================================
//   static String? accessToken;
//   static String? refreshToken;

//   static final JwtStore _jwtStore = JwtStore();

//   // =====================================================
//   // VAULT (MASTER KEY – MEMORY ONLY)
//   // =====================================================
//   static Uint8List? _masterKey;
//   static DateTime? _vaultUnlockedAt;

//   static bool get isLocked => _masterKey == null;

//   // =====================================================
//   // IDLE / ACTIVITY TRACKING
//   // =====================================================
//   static DateTime? _lastActiveAt;
//   static const Duration idleTimeout = Duration(minutes: 5);

//   /// Call this on *any* user interaction
//   static void markUserActive() {
//     _lastActiveAt = DateTime.now();
//   }

//   /// Whether vault should auto-lock
//   static bool _shouldAutoLock() {
//     if (_lastActiveAt == null) return false;
//     return DateTime.now().difference(_lastActiveAt!) > idleTimeout;
//   }

//   /// Locks vault only (NO logout)
//   static void autoLockIfNeeded() {
//     if (_shouldAutoLock()) {
//       lockVault();
//     }
//   }

//   // =====================================================
//   // SESSION RESTORE (APP START)
//   // =====================================================
//   static Future<void> restoreSession() async {
//     accessToken = await _jwtStore.getAccessToken();
//     refreshToken = await _jwtStore.getRefreshToken();
//     markUserActive();
//   }

//   // =====================================================
//   // AUTH HEADERS
//   // =====================================================
//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw StateError("Not authenticated");
//     }
//     return {
//       "Authorization": "Bearer $accessToken",
//     };
//   }

//   // =====================================================
//   // VAULT CONTROL
//   // =====================================================
//   static void setMasterKey(Uint8List key) {
//     _masterKey = key;
//     _vaultUnlockedAt = DateTime.now();
//     markUserActive();
//   }

//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("Vault locked");
//     }
//     return _masterKey!;
//   }

//   /// Optional TTL check (if you want password re-auth later)
//   static bool requiresPasswordReauth(Duration ttl) {
//     if (_vaultUnlockedAt == null) return true;
//     return DateTime.now().difference(_vaultUnlockedAt!) > ttl;
//   }

//   // =====================================================
//   // VAULT LOCK (NO LOGOUT)
//   // =====================================================
//   static void lockVault() {
//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }
//     _masterKey = null;
//     _vaultUnlockedAt = null;
//   }

//   // =====================================================
//   // FULL LOGOUT (ONE PLACE ONLY)
//   // =====================================================
//   static Future<void> fullLogout() async {
//     lockVault();
//     accessToken = null;
//     refreshToken = null;
//     _lastActiveAt = null;
//     await _jwtStore.clear();
//   }
// }
// =======================================================================================
// lib/state/secure_state.dart// lib/state/secure_state.dart
// import 'dart:async';
// import 'dart:typed_data';
// import '../storage/jwt_store.dart';
//
// class SecureState {
//   // =========================
//   // API CONFIG
//   // =========================
//   static String serverUrl = "https://silvora-demo.onrender.com";
//
//   // =========================
//   // AUTH
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;
//
//   static final JwtStore _jwtStore = JwtStore();
//
//   // =========================
//   // VAULT (memory-only)
//   // =========================
//   static Uint8List? _masterKey;
//   static DateTime? _unlockedAt;
//
//   static bool get isLocked => _masterKey == null;
//
//   // =========================
//   // TIMEOUTS
//   // =========================
//   static const Duration idleTimeout = Duration(minutes: 3);
//   static const Duration backgroundTimeout = Duration(minutes: 3);
//
//   static Timer? _idleTimer;
//   static Timer? _backgroundTimer;
//
//   // =========================
//   // SESSION RESTORE
//   // =========================
//   static Future<void> restoreSession() async {
//     accessToken = await _jwtStore.getAccessToken();
//     refreshToken = await _jwtStore.getRefreshToken();
//   }
//
//   // =========================
//   // AUTH HEADER
//   // =========================
//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw StateError("Not authenticated");
//     }
//     return {"Authorization": "Bearer $accessToken"};
//   }
//
//   // =========================
//   // VAULT API (RESTORED)
//   // =========================
//   static void setMasterKey(Uint8List key) {
//     _masterKey = key;
//     _unlockedAt = DateTime.now();
//   }
//
//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("Vault locked");
//     }
//     return _masterKey!;
//   }
//
//   static bool requiresPasswordReauth(Duration ttl) {
//     if (_unlockedAt == null) return true;
//     return DateTime.now().difference(_unlockedAt!) > ttl;
//   }
//
//   static void lockVault() {
//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }
//     _masterKey = null;
//     _unlockedAt = null;
//   }
//
//   // =========================
//   // USER ACTIVITY
//   // =========================
//   static void markUserActive() {
//     _idleTimer?.cancel();
//     _idleTimer = Timer(idleTimeout, () async {
//       await fullLogout(reason: "idle-timeout");
//     });
//
//     _backgroundTimer?.cancel();
//     _backgroundTimer = null;
//   }
//
//   // =========================
//   // APP LIFECYCLE
//   // =========================
//   static void onAppPaused() {
//     _backgroundTimer?.cancel();
//     _backgroundTimer = Timer(backgroundTimeout, () async {
//       await fullLogout(reason: "background-timeout");
//     });
//   }
//
//   static void onAppResumed() {
//     _backgroundTimer?.cancel();
//     _backgroundTimer = null;
//     markUserActive();
//   }
//
//   // =========================
//   // LOGOUT
//   // =========================
//   static Future<void> fullLogout({String? reason}) async {
//     _idleTimer?.cancel();
//     _backgroundTimer?.cancel();
//
//     lockVault();
//
//     accessToken = null;
//     refreshToken = null;
//
//     await _jwtStore.clear();
//   }
//
//   // =========================
//   // HELPERS
//   // =========================
//   static bool get isAuthenticated => accessToken != null;
// }



// // lib/state/secure_state.dart
// import 'dart:typed_data';

// class SecureState {
//   // =========================
//   // API CONFIG
//   // =========================
//   static const String serverUrl = "https://silvora-demo.onrender.com";

//   // =========================
//   // AUTH (memory-only)
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;

//   static bool get isAuthenticated => accessToken != null;

//   // =========================
//   // VAULT (memory-only)
//   // =========================
//   static Uint8List? _masterKey;

//   static bool get hasVault => _masterKey != null;

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
//   // AUTH HEADERS
//   // =========================
//   static Map<String, String> authHeader() {
//     if (accessToken == null) {
//       throw StateError("Not authenticated");
//     }
//     return {
//       "Authorization": "Bearer $accessToken",
//     };
//   }

//   // =========================
//   // LOGOUT (explicit only)
//   // =========================
//   static void logout() {
//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }

//     _masterKey = null;
//     accessToken = null;
//     refreshToken = null;
//   }
// }
// ============================================================
// // lib/state/secure_state.dart
// import 'dart:typed_data';
// import '../storage/jwt_store.dart';

// class SecureState {
//   // =========================
//   // API CONFIG
//   // =========================
//   static String serverUrl = "https://silvora-demo.onrender.com";

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
//   // LOGOUT (ONLY PLACE)
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
// }
// lib/state/secure_state.dart
// lib/state/secure_state.dart
import 'dart:typed_data';
import '../storage/jwt_store.dart';

class SecureState {
  // =========================
  // API CONFIG
  // =========================
  static String serverUrl = "http://10.0.2.2:8000";
  // static String serverUrl = "https://silvora-demo.onrender.com";

  // =========================
  // AUTH (JWT)
  // =========================
  static String? accessToken;
  static String? refreshToken;

  static final JwtStore _jwtStore = JwtStore();

  // =========================
  // VAULT (memory-only)
  // =========================
  static Uint8List? _masterKey;

  static bool get isVaultUnlocked => _masterKey != null;

  // =========================
  // SESSION RESTORE
  // =========================
  static Future<void> restoreSession() async {
    accessToken = await _jwtStore.getAccessToken();
    refreshToken = await _jwtStore.getRefreshToken();
  }

  // =========================
  // AUTH HEADERS
  // =========================
  static Map<String, String> authHeader() {
    if (accessToken == null) {
      throw StateError("Not authenticated");
    }
    return {"Authorization": "Bearer $accessToken"};
  }

  // =========================
  // VAULT CONTROL
  // =========================
  static void setMasterKey(Uint8List key) {
    _masterKey = key;
  }

  static Uint8List requireMasterKey() {
    if (_masterKey == null) {
      throw StateError("Vault not unlocked");
    }
    return _masterKey!;
  }

  // =========================
  // LOGOUT (ONLY PLACE)
  // =========================
  static Future<void> logout() async {
    if (_masterKey != null) {
      _masterKey!.fillRange(0, _masterKey!.length, 0);
    }
    _masterKey = null;

    accessToken = null;
    refreshToken = null;

    await _jwtStore.clear();
  }
}

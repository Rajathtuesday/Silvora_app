
// // ===============================================================================
// //
// import 'dart:typed_data';
// import 'package:silvora_app/crypto/master_key_provider.dart';

// import '../storage/jwt_store.dart';

// class SecureState {
//   // =========================
//   // API CONFIG (ONE PLACE ONLY)
//   // =========================
//   // static const String serverBaseUrl =
//   //     "https://silvora-demo.onrender.com";
//     static String serverBaseUrl = "http://10.0.2.2:8000";


//   // =========================
  
//   // AUTH (JWT)
//   // =========================
//   static String? accessToken;
//   static String? refreshToken;

//   static final JwtStore _jwtStore = JwtStore.instance;

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



//   /// ONLY way to unlock vault
//   static Future<void> unlockVault({
//     required String password,
//     required Uint8List salt,
//   }) async {
//     _masterKey = await MasterKeyProvider.derive(
//       password: password,
//       salt: salt,
//     );
//   }

//   static Uint8List requireMasterKey() {
//     if (_masterKey == null) {
//       throw StateError("Vault not unlocked");
//     }
//     return _masterKey!;
//   }

//   static void lockVault() {
//     if (_masterKey != null) {
//       _masterKey!.fillRange(0, _masterKey!.length, 0);
//     }
//     _masterKey = null;
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
// }
// ====================================================v2=============
// ============================================================================
// SecureState
// Single source of truth for:
// - Authentication tokens (JWT)
// - Vault (master key) in-memory state
//
// Invariants:
// - JWTs may persist across restarts
// - Master key NEVER persists
// - App is usable ONLY when session is READY
// ============================================================================
//lib/state/secure_state.dart
import 'dart:typed_data';



import '../infrastructure/storage/jwt_store.dart';
import '../crypto/master_key_provider.dart';

class SecureState {
  // ===========================================================================
  // API CONFIG (immutable)
  // ===========================================================================
  static const String serverBaseUrl = "http://10.0.2.2:8000";

  // ===========================================================================
  // AUTH (JWT)
  // ===========================================================================
  static String? accessToken;
  static String? refreshToken;

  static final JwtStore _jwtStore = JwtStore.instance;

  // ===========================================================================
  // VAULT (memory-only)
  // ===========================================================================
  static Uint8List? _masterKey;

  // ===========================================================================
  // DERIVED STATE
  // ===========================================================================
  static bool get isAuthenticated =>
      accessToken != null && refreshToken != null;

  static bool get isVaultUnlocked => _masterKey != null;

  /// The ONLY state in which the app is allowed to function
  static bool get isSessionReady =>
      isAuthenticated && isVaultUnlocked;

  // ===========================================================================
  // SESSION RESTORE (JWT ONLY)
  // ===========================================================================
  /// Restores JWTs from storage.
  /// NOTE:
  /// - Vault remains LOCKED
  /// - UI MUST force password re-entry
  static Future<void> restoreSession() async {
    accessToken = await _jwtStore.getAccessToken();
    refreshToken = await _jwtStore.getRefreshToken();
  }

  // ===========================================================================
  // AUTH HEADERS
  // ===========================================================================
  static Map<String, String> authHeader() {
    if (!isAuthenticated) {
      throw StateError("Not authenticated");
    }
    return {
      "Authorization": "Bearer $accessToken",
    };
  }

  // ===========================================================================
  // VAULT CONTROL
  // ===========================================================================
  /// The ONLY way to unlock the vault.
  /// Must be called exactly once per session.
  static Future<void> unlockVault({
    required String password,
    required Uint8List salt,
  }) async {
    if (_masterKey != null) {
      throw StateError("Vault already unlocked");
    }

    final Uint8List derivedKey =
        await MasterKeyProvider.derive(
      password: password,
      salt: salt,
    );

    if (derivedKey.isEmpty) {
      throw StateError("Master key derivation failed");
    }

    _masterKey = derivedKey;
  }

  /// Enforces vault invariant everywhere
  static Uint8List requireMasterKey() {
    if (_masterKey == null) {
      throw StateError("Vault not unlocked");
    }
    return _masterKey!;
  }

  /// Explicit vault lock (e.g. app background, manual lock)
  static void lockVault() {
    if (_masterKey != null) {
      _masterKey!.fillRange(0, _masterKey!.length, 0);
    }
    _masterKey = null;
  }

  // ===========================================================================
  // LOGOUT (FULL TEARDOWN)
  // ===========================================================================
  static Future<void> logout() async {
    // Zeroize vault key
    if (_masterKey != null) {
      _masterKey!.fillRange(0, _masterKey!.length, 0);
    }
    _masterKey = null;

    // Clear tokens
    accessToken = null;
    refreshToken = null;

    await _jwtStore.clear();
  }

// ===========================================================================

// Alternative vault unlock using encrypted master key (for demo/testing only)
static Future<void> unlockWithMasterKey(Uint8List masterKey) async {
  if (_masterKey != null) {
    throw StateError("Vault already unlocked");
  }

  if (masterKey.length != 32) {
    throw StateError("Invalid master key length");
  }

  _masterKey = masterKey;
}
}
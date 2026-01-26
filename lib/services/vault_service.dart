  // // import 'dart:typed_data';
  // // import 'package:flutter/services.dart';
  // // import '../state/secure_state.dart';
  // // import '../crypto/argon2.dart';
  // // import '../crypto/master_key.dart';
  // // import '../storage/key_cache.dart';

  // // class VaultService {
  // //   static const passwordTTL = Duration(days: 2);

  // //   /// Login flow (password required)
  // //   static Future<void> unlockWithPassword({
  // //     required String password,
  // //     required Uint8List encryptedMasterKey,
  // //     required Uint8List salt,
  // //   }) async {
  // //     final pwdKey = await argon2DeriveKey(password, salt);
  // //     final masterKey = decryptMasterKey(
  // //       encrypted: encryptedMasterKey,
  // //       key: pwdKey,
  // //     );

  // //     SecureState.setMasterKey(masterKey);
  // //     await KeyCache.store(masterKey); // biometric-sealed
  // //   }

  // //   /// Auto-unlock using biometrics
  // //   static Future<bool> tryBiometricUnlock() async {
  // //     try {
  // //       final cached = await KeyCache.retrieve();
  // //       if (cached == null) return false;

  // //       SecureState.setMasterKey(cached);
  // //       return true;
  // //     } catch (_) {
  // //       return false;
  // //     }
  // //   }

  // //   static bool needsPassword() {
  // //     return SecureState.requiresPasswordReauth(passwordTTL);
  // //   }

  // //   static void lock() {
  // //     SecureState.lock();
  // //   }
  // // }




  // // =========================================================
  // // lib/services/vault_service.dart
  // // import 'dart:typed_data';
  // // import '../crypto/master_key.dart';
  // // import '../state/secure_state.dart';

  // // class VaultService {
  // //   /// Unlock vault using password
  // //   static Future<void> unlockWithPassword({
  // //     required Uint8List encryptedMasterKey,
  // //     required String password,
  // //     required Uint8List salt,
  // //   }) async {
  // //     final masterKey = await MasterKeyCrypto.decrypt(
  // //       encrypted: encryptedMasterKey,
  // //       password: password,
  // //       salt: salt,
  // //     );

  // //     SecureState.setMasterKey(masterKey);
  // //   }

  // //   /// Lock vault explicitly
  // //   static void lock() {
  // //     SecureState.lock();
  // //   }
  // // }
  // // =========================================================
  //   // import 'dart:typed_data';

  //   // import '../crypto/master_key.dart';
  //   // import '../state/secure_state.dart';

  //   // /// VaultService is responsible for:
  //   // /// - Generating the master key (first login)
  //   // /// - Unlocking the in-memory vault after login
  //   // /// - Enforcing password / biometric policy (later)
  //   // class VaultService {
  //   //   /// Call this AFTER successful login + password verification
  //   //   static Future<void> unlockWithPassword({
  //   //     required String password,
  //   //     required Uint8List salt,
  //   //   }) async {
  //   //     // 🚧 For now (MVP):
  //   //     // We do NOT derive keys yet.
  //   //     // We ONLY generate or restore a master key.

  //   //     // In production:
  //   //     // password + salt → Argon2 → decrypt master key envelope

  //   //     final masterKey = MasterKey.generate();

  //   //     SecureState.unlock(masterKey);
  //   //   }

  //   //   /// Lock vault (logout / timeout)
  //   //   static void lock() {
  //   //     SecureState.lock();
  //   //   }

  //   //   /// Whether vault is unlocked
  //   //   static bool get isUnlocked {
  //   //     try {
  //   //       SecureState.requireMasterKey();
  //   //       return true;
  //   //     } catch (_) {
  //   //       return false;
  //   //     }
  //   //   }
  //   // }
  // // =========================================================
  // // lib/state/secure_state.dart
  // // import 'dart:typed_data';

  // // class SecureState {
  // //   // =========================
  // //   // API CONFIG
  // //   // =========================
  // //   static String serverUrl = "http://10.0.2.2:8000";

  // //   // =========================
  // //   // AUTH
  // //   // =========================
  // //   static String? accessToken;
  // //   static String? refreshToken;

  // //   static Map<String, String> authHeader() {
  // //     if (accessToken == null) return {};
  // //     return {"Authorization": "Bearer $accessToken"};
  // //   }

  // //   // =========================
  // //   // VAULT (MEMORY ONLY)
  // //   // =========================
  // //   static Uint8List? _masterKey;
  // //   static DateTime? _unlockedAt;

  // //   static bool get isUnlocked => _masterKey != null;

  // //   static Uint8List requireMasterKey() {
  // //     if (_masterKey == null) {
  // //       throw StateError("🔒 Vault is locked");
  // //     }
  // //     return _masterKey!;
  // //   }

  // //   static void setMasterKey(Uint8List key) {
  // //     if (key.length != 32) {
  // //       throw StateError("Invalid master key length");
  // //     }
  // //     _masterKey = Uint8List.fromList(key);
  // //     _unlockedAt = DateTime.now();
  // //   }

  // //   static void lock() {
  // //     if (_masterKey != null) {
  // //       _masterKey!.fillRange(0, _masterKey!.length, 0);
  // //     }
  // //     _masterKey = null;
  // //     _unlockedAt = null;
  // //   }
  // // }
  // // =========================================================
  // // lib/services/vault_service.dart
  // import 'dart:typed_data';

  // import '../state/secure_state.dart';
  // import '../crypto/master_key.dart';

  // /// VaultService
  // /// --------------
  // /// - Unlocks master key after login
  // /// - Enforces password re-auth TTL
  // /// - NEVER stores keys on disk
  // class VaultService {
  //   static const Duration passwordTTL = Duration(days: 2);

  //   /// 🔐 Unlock vault using user password
  //   static Future<void> unlockWithPassword(String password) async {
  //     // If still valid, skip re-derivation
  //     if (!SecureState.(passwordTTL)) {
  //       return;
  //     }

  //     // Derive master key (PBKDF2 / Argon2 / HKDF handled here)
  //     final Uint8List masterKey =
  //         await MasterKey.deriveFromPassword(password);

  //     // Store ONLY in memory
  //     SecureState.setMasterKey(masterKey);
  //   }

  //   /// 🔒 Force lock vault (logout / app background)
  //   static void lock() {
  //     // SecureState.lockVault();
  //   }

  //   /// 🧠 Convenience getter (throws if locked)
  //   static Uint8List get masterKey {
  //     return SecureState.requireMasterKey();
  //   }
  // }
// ===========================================

//   import 'dart:typed_data';

//   import '../state/secure_state.dart';
//   import '../crypto/master_key.dart';
// class VaultService {
//   static void setMasterKey(Uint8List key) {
//     SecureState.setMasterKey(key);
//   }

//   static Uint8List get masterKey {
//     return SecureState.requireMasterKey();
//   }
// }
// ================================================
// lib/services/vault_service.dart
import 'dart:typed_data';
import '../crypto/master_key.dart';
import '../state/secure_state.dart';

class VaultService {
  /// Called ONLY after successful login
  static Future<void> unlockWithPassword(String password) async {
    final Uint8List masterKey =
        await MasterKey.deriveFromPassword(password);

    SecureState.setMasterKey(masterKey);
  }

  static Uint8List get masterKey {
    return SecureState.requireMasterKey();
  }
}

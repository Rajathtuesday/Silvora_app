import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

import '../crypto/hkdf.dart';

class SecureState {
  // =========================================================
  // API CONFIG
  // =========================================================
  
  /// The base URL for the Silvora API.
  /// Defaults to the production backend (api.silvora.cloud). For the Android
  /// emulator against a local server, override with
  /// --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static String serverUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.silvora.cloud',
  );

  // =========================================================
  // AUTH TOKENS (MEMORY ONLY)
  // =========================================================
  static String? accessToken;
  static String? refreshToken;

  // =========================================================
  // USER PROFILE (fetched from /api/auth/me/ after login/unlock)
  // =========================================================
  static String? userEmail;
  static bool emailVerified = false;

  static Map<String, String> authHeader() {
    if (accessToken == null) return {};
    return {
      "Authorization": "Bearer $accessToken",
      "Content-Type": "application/json",
    };
  }

  // =========================================================
  // VAULT (MASTER KEY — MEMORY ONLY)
  // =========================================================
  static Uint8List? _masterKey;

  /// Returns true if the vault is currently unlocked in memory.
  static bool get isUnlocked => _masterKey != null;

  /// Unlock vault with decrypted master key.
  static void setMasterKey(Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError("Master key must be exactly 32 bytes.");
    }
    _masterKey = Uint8List.fromList(key);
  }

  static Uint8List get masterKey {
    if (_masterKey == null) {
      throw StateError("Vault locked. Master key unavailable.");
    }
    return _masterKey!;
  }

  // Cached HKDF Extract result for the master key. Extract only depends
  // on the master key itself, never on what a given derivation is for, so
  // it's safe to compute once per unlocked session and reuse for every
  // per-file/per-purpose Expand call afterward (see lib/crypto/hkdf.dart
  // for why this matters). As sensitive as the master key — anyone with
  // this PRK can derive every file/filename key without it, since the
  // "info" labels are predictable strings, not secrets — so it gets the
  // exact same zeroize-on-lock treatment.
  static SecretKey? _masterKeyPrk;

  /// Lazily computed on first use after unlock, then reused until lock().
  static Future<SecretKey> getMasterKeyPrk() async {
    _masterKeyPrk ??= await hkdfExtract(masterKey);
    return _masterKeyPrk!;
  }

  /// Explicit vault lock (zeroize memory for security).
  static void lock() {
    if (_masterKey != null) {
      _masterKey!.fillRange(0, _masterKey!.length, 0);
      _masterKey = null;
    }
    _masterKeyPrk = null;
  }

  /// Full logout hard reset.
  static void logout() {
    lock();
    accessToken = null;
    refreshToken = null;
    userEmail = null;
    emailVerified = false;
  }
}
import 'dart:typed_data';

class SecureState {
  // =========================================================
  // API CONFIG
  // =========================================================
  
  /// The base URL for the Silvora API.
  /// ⚠️ CHANGE THIS FOR PRODUCTION DEPLOYMENT. 
  /// For Android emulator, use http://10.0.2.2:8000
  static String serverUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // =========================================================
  // AUTH TOKENS (MEMORY ONLY)
  // =========================================================
  static String? accessToken;
  static String? refreshToken;

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

  /// Explicit vault lock (zeroize memory for security).
  static void lock() {
    if (_masterKey != null) {
      _masterKey!.fillRange(0, _masterKey!.length, 0);
      _masterKey = null;
    }
  }

  /// Full logout hard reset.
  static void logout() {
    lock();
    accessToken = null;
    refreshToken = null;
  }
}
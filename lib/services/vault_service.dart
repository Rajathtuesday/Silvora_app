import 'dart:convert';
import 'dart:typed_data';

import '../state/secure_state.dart';
import '../crypto/argon2.dart';
import '../crypto/xchacha.dart';
import 'auth_client.dart';

/// Thrown when the vault can't be reached because the session is no longer
/// valid (token expired/blacklisted). Callers should route back to login.
class VaultAuthException implements Exception {
  final String message;
  VaultAuthException(this.message);
  @override
  String toString() => message;
}

class VaultService {
  static Uint8List _hexToBytes(String hex) {
    hex = hex.trim();
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      out[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return out;
  }

  /// Pure, offline unlock: derive the KEK from the password + KDF params,
  /// decrypt the master-key envelope, and hold the master key in memory.
  /// No network — used by [unlock] and by tests.
  static Future<void> unlockWithPassword({
    required String password,
    required Uint8List salt,
    required Uint8List encryptedMasterKey,
    required Uint8List nonce,
    int iterations = 3,
    int memoryKb = 65536,
    int parallelism = 2,
  }) async {
    final kek = await Argon2Kdf.deriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
      memoryKb: memoryKb,
      parallelism: parallelism,
    );

    final mac = encryptedMasterKey.sublist(encryptedMasterKey.length - 16);
    final ciphertext = encryptedMasterKey.sublist(0, encryptedMasterKey.length - 16);

    final masterKey = await XChaCha.decrypt(
      ciphertext: ciphertext,
      key: kek,
      nonce: nonce,
      mac: mac,
    );

    SecureState.setMasterKey(masterKey);
  }

  /// Fetches the user's master-key envelope and unlocks the vault in memory.
  /// Requires a valid access token in [SecureState] (auto-refreshed). The KDF
  /// parameters are read from the envelope so the KEK is reproduced exactly the
  /// way it was created.
  static Future<void> unlock(String password) async {
    final res = await AuthClient.get(
      Uri.parse("${SecureState.serverUrl}/api/auth/master-key/"),
    );

    if (res.statusCode == 401) {
      throw VaultAuthException("Session expired. Please sign in again.");
    }
    if (res.statusCode != 200) {
      throw Exception("Vault security record not found.");
    }

    final meta = jsonDecode(res.body) as Map<String, dynamic>;

    await unlockWithPassword(
      password: password,
      salt: _hexToBytes(meta["kdf_salt_hex"] as String),
      encryptedMasterKey: _hexToBytes(meta["encrypted_master_key_hex"] as String),
      nonce: _hexToBytes(meta["nonce_hex"] as String),
      iterations: (meta["kdf_iterations"] ?? 3) as int,
      memoryKb: (meta["kdf_memory_kb"] ?? 65536) as int,
      parallelism: (meta["kdf_parallelism"] ?? 1) as int,
    );
  }

  static void lock() => SecureState.lock();
  static bool get isUnlocked => SecureState.isUnlocked;
}

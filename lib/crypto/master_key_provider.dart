  // ============================================================================
  // MasterKeyProvider
  // Responsible ONLY for deriving a master key from (password + salt)
  //
  // Invariants:
  // - Stateless
  // - No persistence
  // - No caching
  // - No logging
  // - Output is ALWAYS 32 bytes
  // ============================================================================
  //lib/crypto/master_key_provider.dart
  import 'dart:typed_data';

  import 'argon2.dart';

  class MasterKeyProvider {
    static const int _expectedKeyLength = 32;

    /// Derives a master key using Argon2id.
    ///
    /// SECURITY CONTRACT:
    /// - password MUST come directly from user input
    /// - salt MUST be server-provided, per-user, versioned
    /// - derived key NEVER leaves memory
    static Future<Uint8List> derive({
      required String password,
      required Uint8List salt,
    }) async {
      if (password.isEmpty) {
        throw ArgumentError("Password must not be empty");
      }

      if (salt.isEmpty) {
        throw ArgumentError("Vault salt must not be empty");
      }

      final Uint8List key = await Argon2Kdf.deriveKey(
        password: password,
        salt: salt,
      );

      if (key.length != _expectedKeyLength) {
        throw StateError(
          "Invalid master key length: ${key.length}",
        );
      }

      return key;
    }
  }

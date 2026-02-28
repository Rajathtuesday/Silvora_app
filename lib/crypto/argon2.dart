// ============================================================================
// Argon2 KDF Policy
//
// This file defines the PASSWORD → MASTER KEY derivation contract.
//
// SECURITY GOALS:
// - Memory-hard (GPU resistant)
// - Deterministic across platforms
// - Versionable for future rotation
// - No persistence, no caching
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class Argon2Kdf {
  // --------------------------------------------------------------------------
  // KDF POLICY (v1)
  // --------------------------------------------------------------------------
  static const int _memoryKb = 131072; // 128 MB
  static const int _iterations = 4;
  static const int _parallelism = 2;
  static const int _keyLength = 32;

  /// Derives a 256-bit master key using Argon2id.
  ///
  /// Contract:
  /// - password: raw user password (String)
  /// - salt: per-user vault salt (bytes, server-provided)
  ///
  /// Returns:
  /// - 32-byte master key
  static Future<Uint8List> deriveKey({
    required String password,
    required Uint8List salt,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError("Password must not be empty");
    }

    if (salt.isEmpty) {
      throw ArgumentError("Salt must not be empty");
    }

    // Canonical password encoding (UTF-8)
    final Uint8List passwordBytes =
        Uint8List.fromList(utf8.encode(password));

    final algo = Argon2id(
      memory: _memoryKb,
      iterations: _iterations,
      parallelism: _parallelism,
      hashLength: _keyLength,
    );

    final SecretKey secretKey = await algo.deriveKey(
      secretKey: SecretKey(passwordBytes),
      nonce: salt,
    );

    final Uint8List derived =
        Uint8List.fromList(await secretKey.extractBytes());

    if (derived.length != _keyLength) {
      throw StateError("Invalid Argon2 output length");
    }

    return derived;
  }
}


// lib/crypto/crypto_self_test.dart
//
// Runs a deterministic client-side crypto self-test at app startup.
// This validates:
//  - XChaCha20-Poly1305 encryption/decryption
//  - Nonce correctness
//  - MAC verification
//
// If this test fails, DO NOT TRUST uploads, previews, or downloads.

// 
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'xchacha.dart';

class CryptoSelfTest {
  static bool _ran = false;

  static Future<void> run() async {
    if (_ran) return;
    _ran = true;

    final crypto = XChaCha();

    // ----------------------------
    // 1️⃣ Test vectors
    // ----------------------------

    final plaintext = Uint8List.fromList(
      List.generate(1024, (i) => i % 256),
    );

    final key = Uint8List.fromList(
      List.generate(32, (i) => i),
    );

    final nonce = await crypto.randomNonce();

    // ----------------------------
    // 2️⃣ Encrypt
    // ----------------------------

    final encrypted = await crypto.encrypt(
      plaintext: plaintext,
      key: key,
      nonce: nonce,
    );

    // encrypted = ciphertext || mac (16 bytes)
    if (encrypted.length <= 16) {
      throw StateError("Encrypted output too small");
    }

    final ciphertext =
        encrypted.sublist(0, encrypted.length - 16);
    final mac =
        encrypted.sublist(encrypted.length - 16);

    // ----------------------------
    // 3️⃣ Decrypt
    // ----------------------------

    final decrypted = await crypto.decrypt(
      ciphertext: ciphertext,
      key: key,
      nonce: nonce,
      mac: mac,
    );

    // ----------------------------
    // 4️⃣ Verify
    // ----------------------------

    if (!listEquals(plaintext, decrypted)) {
      throw StateError("❌ Crypto self-test FAILED");
    }

    debugPrint("✅ Crypto self-test PASSED");
  }
}

// =========================================================================
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;

import 'argon2.dart';
import 'hkdf.dart';

/// Recovery phrase crypto: a second, independent way to unlock the vault.
///
/// phrase -> Argon2(phrase, salt) = Recovery-KEK   (wraps the master key)
///        -> HKDF(KEK, "auth")     = Recovery-auth-key (server stores only its hash)
class RecoveryCrypto {
  /// A 24-word (256-bit) recovery phrase.
  static String generatePhrase() => bip39.generateMnemonic(strength: 256);

  static bool isValidPhrase(String phrase) =>
      bip39.validateMnemonic(normalize(phrase));

  static String normalize(String phrase) =>
      phrase.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

  static Uint8List newSalt() {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => r.nextInt(256)));
  }

  /// Recovery-KEK — wraps the master key. Derived from the phrase + salt.
  static Future<Uint8List> deriveKek(
    String phrase,
    Uint8List salt, {
    int iterations = 3,
    int memoryKb = 65536,
    int parallelism = 1,
  }) {
    return Argon2Kdf.deriveKey(
      password: normalize(phrase),
      salt: salt,
      iterations: iterations,
      memoryKb: memoryKb,
      parallelism: parallelism,
    );
  }

  /// Recovery-auth-key — the server stores only its hash so it can verify the
  /// phrase during a logged-out reset without ever learning it. One-way from
  /// the KEK (HKDF), so the stored hash never reveals the wrapping key.
  static Future<Uint8List> deriveAuthKey(Uint8List kek) =>
      hkdfSha256(ikm: kek, info: utf8.encode("silvora-recovery-auth"));

  static String toHex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List fromHex(String hex) {
    hex = hex.trim();
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      out[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return out;
  }
}

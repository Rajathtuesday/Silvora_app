import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class Argon2Kdf {
  /// Derives a key from a password using Argon2id.
  /// Parallelism and memory parameters should match the backend security policy.
  static Future<Uint8List> deriveKey({
    required String password,
    required Uint8List salt,
    int memoryKb = 65536,
    int iterations = 3,
    int parallelism = 2,
    int length = 32,
  }) async {
    final algo = Argon2id(
      memory: memoryKb,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: length,
    );

    final secretKey = await algo.deriveKey(
      // utf8.encode, not .codeUnits: codeUnits is raw UTF-16 code units,
      // identical to UTF-8 only for ASCII. Any non-ASCII password (accented
      // letters, non-Latin scripts, emoji) would derive a different key
      // than what was used to encrypt the vault, locking the user out
      // permanently with no error to explain why.
      secretKey: SecretKey(
        Uint8List.fromList(utf8.encode(password)),
      ),
      nonce: salt,
    );

    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }
}

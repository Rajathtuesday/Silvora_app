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
      secretKey: SecretKey(
        Uint8List.fromList(password.codeUnits),
      ),
      nonce: salt,
    );

    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }
}

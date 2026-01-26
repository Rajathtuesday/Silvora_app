// // lib/crypto/argon2.dart
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// class Argon2KeyDerivation {
//   final Argon2id algorithm;

//   Argon2KeyDerivation()
//       : algorithm = Argon2id(
//           parallelism: 1,
//           memory: 65536,        // KiB
//           iterations: 2,
//           hashLength: 32,
//         );

//   Future<Uint8List> deriveKey({
//     required String password,
//     required List<int> salt,
//     int outLen = 32,    // outLen MUST match hashLength
//   }) async {
//     final secretKey = SecretKey(password.codeUnits);

//     final derived = await algorithm.deriveKey(
//       secretKey: secretKey,
//       nonce: salt,
//     );

//     return Uint8List.fromList(await derived.extractBytes());
//   }
// }

// ==============================================================';
//lib/crypto/argon2.dart
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// Future<Uint8List> argon2DeriveKey({
//   required String password,
//   required Uint8List salt,
//   int memoryKb = 65536,
//   int iterations = 3,
//   int parallelism = 1,
// }) async {
//   final kdf = Argon2id(
//     memory: memoryKb,
//     iterations: iterations,
//     parallelism: parallelism,
//     hashLength: 32,
//   );

//   final key = await kdf.deriveKey(
//     secretKey: SecretKey(password.codeUnits),
//     nonce: salt,
//   );

//   return Uint8List.fromList(await key.extractBytes());
// }
// ================================================
// lib/crypto/argon2.dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class Argon2Kdf {
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

    return Uint8List.fromList(await secretKey.extractBytes());
  }
}

// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// class XChaCha{
//   final Xchacha20 _algo = Xchacha20.poly1305Aead();

//   /// Decrypt a single AEAD chunk
//   Future<Uint8List> decrypt({
//     required Uint8List ciphertext,
//     required Uint8List nonce,
//     required Uint8List mac,
//     required Uint8List key,
//   }) async {
//     final box = SecretBox(
//       ciphertext,
//       nonce: nonce,
//       mac: Mac(mac),
//     );

//     final plain = await _algo.decrypt(
//       box,
//       secretKey: SecretKey(key),
//     );

//     return Uint8List.fromList(plain);
//   }
// }
// =========================================================================

// lib/crypto/xchacha.dart
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// class XChaCha {
//   static final Xchacha20 _algo = Xchacha20.poly1305Aead();

//   /// Encrypt → returns SecretBox (ciphertext + mac + nonce)
//   Future<SecretBox> encrypt({
//     required Uint8List plaintext,
//     required Uint8List key,
//     required Uint8List nonce,
//   }) async {
//     return _algo.encrypt(
//       plaintext,
//       secretKey: SecretKey(key),
//       nonce: nonce,
//     );
//   }

//   /// Decrypt → plaintext
//   Future<Uint8List> decrypt({
//     required Uint8List ciphertext,
//     required Uint8List key,
//     required Uint8List nonce,
//     required Uint8List mac,
//   }) async {
//     final box = SecretBox(
//       ciphertext,
//       nonce: nonce,
//       mac: Mac(mac),
//     );

//     final plain = await _algo.decrypt(
//       box,
//       secretKey: SecretKey(key),
//     );

//     return Uint8List.fromList(plain);
//   }

//   /// Generate secure random nonce
//   Future<Uint8List> randomNonce() async {
//     final nonce = await _algo.newNonce();
//     return Uint8List.fromList(nonce);
//   }
// }

// =========================================================================
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// class XChaCha {
//   static final _algo = Xchacha20.poly1305Aead();

//   Future<SecretBox> encrypt({
//     required Uint8List plaintext,
//     required Uint8List key,
//     required Uint8List nonce,
//   }) async {
//     return _algo.encrypt(
//       plaintext,
//       secretKey: SecretKey(key),
//       nonce: nonce,
//     );
//   }

//   Future<Uint8List> decrypt({
//     required SecretBox box,
//     required Uint8List key,
//   }) async {
//     final plain = await _algo.decrypt(
//       box,
//       secretKey: SecretKey(key),
//     );
//     return Uint8List.fromList(plain);
//   }

//   Uint8List randomNonce() {
//     return Uint8List.fromList(_algo.newNonce());
//   }
// }
// =========================================================================
//   /// Decrypt multiple AEAD chunks and concatenate
// lib/crypto/xchacha.dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class XChaCha {
  static final Xchacha20 _algo =
      Xchacha20.poly1305Aead();

  Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
  }) async {
    final secretBox = await _algo.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );

    return Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List mac,
  }) async {
    final box = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(mac),
    );

    final plain = await _algo.decrypt(
      box,
      secretKey: SecretKey(key),
    );

    return Uint8List.fromList(plain);
  }

  Uint8List randomNonce() {
    return Uint8List.fromList(_algo.newNonce());
  }
}

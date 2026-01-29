
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

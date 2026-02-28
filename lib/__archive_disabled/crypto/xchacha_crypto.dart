// lib/crypto/xchacha_crypto.dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class XChaChaCrypto {
  static final _algo = Xchacha20.poly1305Aead();

  static Future<Map<String, Uint8List>> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  }) async {
    final nonce = await _algo.newNonce();

    final box = await _algo.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );

    return {
      "ciphertext": Uint8List.fromList(box.cipherText),
      "nonce": Uint8List.fromList(nonce),
      "mac": Uint8List.fromList(box.mac.bytes),
    };
  }

  static Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List nonce,
    required Uint8List mac,
    required Uint8List key,
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
}

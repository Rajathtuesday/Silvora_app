import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class XChaCha {
  static final Xchacha20 _algo = Xchacha20.poly1305Aead();

  /// Encrypts plaintext using XChaCha20-Poly1305.
  static Future<SecretBox> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
  }) async {
    return _algo.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );
  }

  /// Decrypts ciphertext using XChaCha20-Poly1305.
  static Future<Uint8List> decrypt({
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

  /// Generates a secure random 24-byte nonce for XChaCha20.
  static Future<Uint8List> randomNonce() async {
    final nonce = await _algo.newNonce();
    return Uint8List.fromList(nonce);
  }
}

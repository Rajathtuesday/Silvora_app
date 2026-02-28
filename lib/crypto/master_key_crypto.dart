// lib/crypto/master_key_crypto.dart
import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

class EncryptResult {
  final String cipherHex;
  final Uint8List nonce;

  EncryptResult({
    required this.cipherHex,
    required this.nonce,
  });
}

class MasterKeyCrypto {
  static final _algorithm = Xchacha20.poly1305Aead();

  /// Secure random bytes (cryptographically secure)
  static Uint8List randomBytes(int length) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  /// Encrypt master key using KEK
  static Future<EncryptResult> encrypt({
    required Uint8List masterKey,
    required Uint8List kek,
  }) async {
    final nonce = _algorithm.newNonce();
    final secretKey = SecretKey(kek);

    final box = await _algorithm.encrypt(
      masterKey,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine ciphertext + MAC
    final combined = Uint8List.fromList([
      ...box.cipherText,
      ...box.mac.bytes,
    ]);

    return EncryptResult(
      cipherHex: hex.encode(combined),
      nonce: Uint8List.fromList(nonce),
    );
  }

  /// Decrypt master key using KEK
  static Future<Uint8List> decrypt({
    required Uint8List cipherText,
    required Uint8List kek,
    required Uint8List nonce,
  }) async {
    final secretKey = SecretKey(kek);

    // Split MAC (last 16 bytes for Poly1305)
    final macBytes = cipherText.sublist(cipherText.length - 16);
    final actualCipher = cipherText.sublist(0, cipherText.length - 16);

    final box = SecretBox(
      actualCipher,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clear = await _algorithm.decrypt(
      box,
      secretKey: secretKey,
    );

    return Uint8List.fromList(clear);
  }
}

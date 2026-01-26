import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class ThumbnailCrypto {
  static final _algo = Xchacha20.poly1305Aead();

  /// MVP placeholder key (same as upload)
  static SecretKey _key() => SecretKey(Uint8List(32));

  static Future<Uint8List> decrypt(Uint8List encrypted) async {
    final nonce = encrypted.sublist(0, 24);
    final mac = encrypted.sublist(encrypted.length - 16);
    final cipherText = encrypted.sublist(24, encrypted.length - 16);

    final box = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );

    final plain = await _algo.decrypt(
      box,
      secretKey: _key(),
    );

    return Uint8List.fromList(plain);
  }
}

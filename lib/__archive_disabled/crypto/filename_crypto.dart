import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class FilenameCrypto {
  static final _aead = Xchacha20.poly1305Aead();

  /// Decrypt encrypted filename using file key
  static Future<String> decrypt({
    required String encHex,
    required String nonceHex,
    required Uint8List fileKey,
  }) async {
    final cipherText = _hexToBytes(encHex);
    final nonce = _hexToBytes(nonceHex);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac.empty, // server stores MAC separately
    );

    final clear = await _aead.decrypt(
      secretBox,
      secretKey: SecretKey(fileKey),
    );

    return utf8.decode(clear);
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}

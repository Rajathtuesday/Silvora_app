// ================================================================================
// lib/crypto/filename_crypto.dart
// - Encrypts and decrypts filenames using XChaCha20-Poly1305
// - Derives a filename-specific key from the file key using HKDF
// - Stores nonce and hash for integrity verification
// - Stateless and deterministic (safe for listing and resumable uploads)
// - No key reuse, no random nonces, no persistence
//=================================================================================
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'hkdf.dart';
import 'xchacha.dart';

class EncryptedFilename {
  final String ciphertextHex;
  final String nonceHex;
  final String macHex;

  EncryptedFilename({
    required this.ciphertextHex,
    required this.nonceHex,
    required this.macHex,
  });
}

class FilenameCrypto {
  static final _aead = Xchacha20.poly1305Aead();

  static Future<EncryptedFilename> encrypt({
    required String filename,
    required Uint8List fileKey,
  }) async {
    final Uint8List nameKey = await hkdfSha256(
      ikm: fileKey,
      info: Uint8List.fromList("silvora-filename".codeUnits),
      length: 32,
    );

    final Uint8List nonce = randomXChaChaNonce();

    final SecretBox box = await _aead.encrypt(
      utf8.encode(filename),
      secretKey: SecretKey(nameKey),
      nonce: nonce,
    );

    return EncryptedFilename(
      ciphertextHex: _bytesToHex(
        Uint8List.fromList(box.cipherText),
      ),
      nonceHex: _bytesToHex(nonce),
      macHex: _bytesToHex(
        Uint8List.fromList(box.mac.bytes),
      ),
    );
  }

  static Future<String> decrypt({
    required String ciphertextHex,
    required String nonceHex,
    required String macHex,
    required Uint8List fileKey,
  }) async {
    final Uint8List cipherText = _hexToBytes(ciphertextHex);
    final Uint8List nonce = _hexToBytes(nonceHex);
    final Uint8List mac = _hexToBytes(macHex);

    final Uint8List nameKey = await hkdfSha256(
      ikm: fileKey,
      info: Uint8List.fromList("silvora-filename".codeUnits),
      length: 32,
    );

    final box = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );

    final clear = await _aead.decrypt(
      box,
      secretKey: SecretKey(nameKey),
    );

    return utf8.decode(clear);
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] =
          int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static String _bytesToHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
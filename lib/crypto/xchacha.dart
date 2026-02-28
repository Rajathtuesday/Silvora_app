// ============================================================================
// XChaCha20-Poly1305 AEAD
// - Supports AAD
// - Returns ciphertext || mac
// ============================================================================

import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

final Xchacha20 _algo = Xchacha20.poly1305Aead();

const int _macLength = 16;

/// Encrypts plaintext.
/// Returns ciphertext || mac
Future<Uint8List> xchachaEncrypt({
  required Uint8List key,
  required Uint8List plaintext,
  required Uint8List nonce,
  Uint8List? aad,
}) async {
  if (nonce.length != _algo.nonceLength) {
    throw ArgumentError("Invalid nonce length");
  }

  final SecretBox box = await _algo.encrypt(
    plaintext,
    secretKey: SecretKey(key),
    nonce: nonce,
    aad: aad ?? const <int>[],
  );

  return Uint8List.fromList(
    box.cipherText + box.mac.bytes,
  );
}

/// Decrypts ciphertext || mac
Future<Uint8List> xchachaDecrypt({
  required Uint8List ciphertext,
  required Uint8List key,
  required Uint8List nonce,
  Uint8List? aad,
}) async {
  if (nonce.length != _algo.nonceLength) {
    throw ArgumentError("Invalid nonce length");
  }

  if (ciphertext.length < _macLength) {
    throw ArgumentError("Ciphertext too short");
  }

  final int ctLen = ciphertext.length - _macLength;

  final SecretBox box = SecretBox(
    ciphertext.sublist(0, ctLen),
    nonce: nonce,
    mac: Mac(ciphertext.sublist(ctLen)),
  );

  final plain = await _algo.decrypt(
    box,
    secretKey: SecretKey(key),
    aad: aad ?? const <int>[],
  );

  return Uint8List.fromList(plain);
}

/// If needed elsewhere (filename crypto)
Uint8List randomXChaChaNonce() {
  return Uint8List.fromList(_algo.newNonce());
}
// ============================================================================
// Chunk Crypto
// - HKDF derived key
// - HKDF derived nonce
// - AAD binds fileId + chunkIndex
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'hkdf.dart';
import 'xchacha.dart';

const int _chunkKeyLength = 32;
const int _nonceLength = 24;

const String _chunkKeyContext = "silvora:chunk-key:v1";
const String _chunkNonceContext = "silvora:chunk-nonce:v1";

class EncryptedChunk {
  final Uint8List ciphertext;
  final Uint8List mac;
  final Uint8List nonce;

  EncryptedChunk({
    required this.ciphertext,
    required this.mac,
    required this.nonce,
  });
}

// ─────────────────────────────────────────────
// Derive chunk key
// ─────────────────────────────────────────────

Future<Uint8List> _deriveChunkKey({
  required Uint8List fileKey,
  required int chunkIndex,
}) async {
  final info = Uint8List.fromList(
    utf8.encode("$_chunkKeyContext:$chunkIndex"),
  );

  return hkdfSha256(
    ikm: fileKey,
    info: info,
    length: _chunkKeyLength,
  );
}

// ─────────────────────────────────────────────
// Derive nonce via HKDF (correct approach)
// ─────────────────────────────────────────────

Future<Uint8List> _deriveChunkNonce({
  required Uint8List fileKey,
  required int chunkIndex,
}) async {
  final info = Uint8List.fromList(
    utf8.encode("$_chunkNonceContext:$chunkIndex"),
  );

  return hkdfSha256(
    ikm: fileKey,
    info: info,
    length: _nonceLength,
  );
}

// ─────────────────────────────────────────────
// Encrypt chunk
// ─────────────────────────────────────────────

Future<EncryptedChunk> encryptChunk({
  required Uint8List plaintext,
  required Uint8List fileKey,
  required int chunkIndex,
  required String fileId,
}) async {
  final chunkKey = await _deriveChunkKey(
    fileKey: fileKey,
    chunkIndex: chunkIndex,
  );

  final nonce = await _deriveChunkNonce(
    fileKey: fileKey,
    chunkIndex: chunkIndex,
  );

  final aad = Uint8List.fromList(
    utf8.encode("silvora:file:$fileId:chunk:$chunkIndex"),
  );

  final fullCipher = await xchachaEncrypt(
    key: chunkKey,
    nonce: nonce,
    plaintext: plaintext,
    aad: aad,
  );

  const int macLength = 16;
  final int cipherLength = fullCipher.length - macLength;

  return EncryptedChunk(
    ciphertext: fullCipher.sublist(0, cipherLength),
    mac: fullCipher.sublist(cipherLength),
    nonce: nonce,
  );
}

// ─────────────────────────────────────────────
// Decrypt chunk
// ─────────────────────────────────────────────

Future<Uint8List> decryptChunk({
  required Uint8List ciphertextWithMac,
  required Uint8List fileKey,
  required int chunkIndex,
  required String fileId,
}) async {
  final chunkKey = await _deriveChunkKey(
    fileKey: fileKey,
    chunkIndex: chunkIndex,
  );

  final nonce = await _deriveChunkNonce(
    fileKey: fileKey,
    chunkIndex: chunkIndex,
  );

  final aad = Uint8List.fromList(
    utf8.encode("silvora:file:$fileId:chunk:$chunkIndex"),
  );

  return xchachaDecrypt(
    key: chunkKey,
    nonce: nonce,
    ciphertext: ciphertextWithMac,
    aad: aad,
  );
}
// ============================================================================
// File Decryptor
//
// Reassembles and decrypts a file from encrypted chunks.
// - Mirrors upload chunk encryption exactly
// - No manifest crypto
// - No master key usage
// ============================================================================

import 'dart:typed_data';

import 'chunk_crypto.dart';

class FileDecryptor {
  final Uint8List fileKey;

  FileDecryptor({
    required this.fileKey,
  });

  /// Decrypt chunks in order and return full plaintext
  Future<Uint8List> decryptChunks({
    required List<Uint8List> encryptedChunks,
    required String fileId,
  }) async {
    final BytesBuilder out = BytesBuilder();

    for (int index = 0; index < encryptedChunks.length; index++) {
      final Uint8List encrypted = encryptedChunks[index];

      final Uint8List plain = await decryptChunk(
        ciphertextWithMac: encrypted,
        fileKey: fileKey,
        chunkIndex: index,
        fileId: fileId, // File ID is not used in key derivation for decryption, but is required for AAD. In a real implementation, this should be the actual file ID.
      );

      out.add(plain);
    }

    return out.toBytes();
  }
}

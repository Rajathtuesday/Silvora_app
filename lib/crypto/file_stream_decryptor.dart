// ============================================================================
// File Stream Decryptor
//
// - Uses backend manifest as authority
// - Decrypts encrypted blob using offsets
// - Safe for large files (streaming)
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/models/file_manifest.dart';
import 'chunk_crypto.dart';
import 'file_key.dart';

class FileStreamDecryptor {
  final Uint8List masterKey;
  final String fileId;
  final FileManifest manifest;

  FileStreamDecryptor({
    required this.masterKey,
    required this.fileId,
    required this.manifest,
  });

  Future<File> decryptToTempFile(Uint8List encryptedBlob) async {
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: fileId,
    );

    final temp = await File(
      '${Directory.systemTemp.path}/silvora_$fileId.tmp',
    ).create();

    final sink = temp.openWrite();

    for (final chunk in manifest.chunks) {
      final start = chunk.offset;
      final end = start + chunk.size;

      if (end > encryptedBlob.length) {
        throw StateError("Encrypted blob truncated");
      }

      final cipherSlice = encryptedBlob.sublist(start, end);

      final plaintext = await decryptChunk(
          ciphertextWithMac: cipherSlice,
          fileKey: fileKey,
          chunkIndex: chunk.index,
          fileId: fileId,
        );

      sink.add(plaintext);
    }

    await sink.close();
    return temp;
  }
}

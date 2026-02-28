// lib/infrastructure/services/download_and_decrypt_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../crypto/chunk_crypto.dart';
import '../../crypto/file_key.dart';
import '../../domain/models/file_manifest.dart';
import '../../state/secure_state.dart';
import '../storage/temp_file_manager.dart';
import '../api/download_api.dart';

class DownloadAndDecryptService {
  static Future<File> downloadAndDecryptToTempFile({
    required String fileId,
  }) async {
    final masterKey = SecureState.requireMasterKey();

    final api = DownloadApi(
      accessToken: SecureState.accessToken!,
    );

    // 1️⃣ Fetch manifest
    final manifestJson = await api.fetchManifest(fileId);
    final manifest = FileManifest.fromJson(manifestJson);

    // 2️⃣ Derive file key
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: fileId,
    );

    // 3️⃣ Create temp file
    final tempFile =
        await TempFileManager.createTempFile(fileId);

    final sink = tempFile.openWrite();

    // 4️⃣ Process chunks sequentially
    for (final chunk in manifest.chunks) {
      final encryptedChunk =
          await api.downloadChunk(
        fileId: fileId,
        index: chunk.index,
      );

      // 🔐 Integrity check
      final computedSha =
          sha256.convert(encryptedChunk).toString();

      if (computedSha != chunk.sha256) {
        await sink.close();
        throw StateError(
            "Integrity check failed for chunk ${chunk.index}");
      }

      // 🔓 Decrypt
      final plaintext = await decryptChunk(
        ciphertextWithMac: encryptedChunk,
        fileKey: fileKey,
        chunkIndex: chunk.index,
        fileId: fileId,
      );

      sink.add(plaintext);
    }

    await sink.close();

    return tempFile;
  }
}
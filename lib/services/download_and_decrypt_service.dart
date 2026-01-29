
// ===========================================
// lib/services/download_and_decrypt_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../crypto/file_stream_decryptor.dart';
import '../services/download_service.dart';
import '../state/secure_state.dart';

class DownloadAndDecryptService {
  // ============================================================
  // PUBLIC ENTRY POINT
  // ============================================================
  static Future<File> downloadAndDecrypt({
    required String fileId,
    required String filename,
  }) async {
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("⬇️ DOWNLOAD + DECRYPT INIT");
    debugPrint("📄 fileId   = $fileId");
    debugPrint("📄 filename = $filename");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    // ─────────────────────────────
    // Phase 1: Master key
    // ─────────────────────────────
    final masterKey = SecureState.requireMasterKey();
    debugPrint("🔑 Master key OK (len=${masterKey.length})");

    // ─────────────────────────────
    // Phase 2: Manifest
    // ─────────────────────────────
    debugPrint("🟢 Fetching manifest");
    final manifest = await DownloadService.fetchManifest(fileId);

    debugPrint("📄 Manifest loaded");
    debugPrint("📄 chunks    = ${manifest['chunks']?.length}");
    debugPrint("📄 file_size = ${manifest['file_size']}");

    // ─────────────────────────────
    // Phase 3: Encrypted payload
    // ─────────────────────────────
    debugPrint("🟢 Fetching encrypted data");
    final encrypted = await DownloadService.fetchEncryptedData(fileId);

    debugPrint("📦 Encrypted bytes = ${encrypted.length}");
    if (encrypted.isEmpty) {
      throw StateError("Encrypted payload is empty");
    }

    // ─────────────────────────────
    // Phase 4: Decrypt → temp file
    // ─────────────────────────────
    debugPrint("🟢 Starting decryption");

    final decryptor = FileStreamDecryptor(
      masterKey: masterKey,
      manifest: manifest,
    );

    final tempFile = await decryptor.decryptToTempFile(encrypted);

    debugPrint("🔓 Decryption complete");
    debugPrint("📁 Temp path = ${tempFile.path}");
    debugPrint("📁 Temp size = ${tempFile.lengthSync()} bytes");

    // ─────────────────────────────
    // Phase 5: Save to app downloads
    // ─────────────────────────────
    final outFile = await _saveToAppDownloads(tempFile, filename);

    debugPrint("✅ File saved successfully");
    debugPrint("📁 Final path = ${outFile.path}");

    // ─────────────────────────────
    // Cleanup temp file
    // ─────────────────────────────
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
      debugPrint("🧹 Temp file deleted");
    }

    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("✅ DOWNLOAD COMPLETE");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    return outFile;
  }

  // ============================================================
  // SAFE ANDROID / IOS SAVE LOCATION (NO PERMISSIONS NEEDED)
  // ============================================================
  static Future<File> _saveToAppDownloads(
    File source,
    String filename,
  ) async {
    debugPrint("📂 Resolving app download directory");

    final Directory baseDir;

    if (Platform.isAndroid) {
      // Android scoped storage safe location
      baseDir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final downloadsDir = Directory("${baseDir.path}/Downloads");

    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
      debugPrint("📂 Created Downloads directory");
    }

    final outFile = File("${downloadsDir.path}/$filename");

    debugPrint("📄 Writing file to ${outFile.path}");
    await source.copy(outFile.path);

    return outFile;
  }

  // ============================================================
  // OPTIONAL CLEANUP (call once per app launch)
  // ============================================================
  static Future<void> cleanupOldDownloads({
    Duration maxAge = const Duration(days: 7),
  }) async {
    debugPrint("🧹 Cleanup old downloads");

    final Directory baseDir =
        await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();

    final downloadsDir = Directory("${baseDir.path}/Downloads");
    if (!downloadsDir.existsSync()) return;

    final now = DateTime.now();

    for (final entity in downloadsDir.listSync()) {
      if (entity is File) {
        final stat = entity.statSync();
        if (now.difference(stat.modified) > maxAge) {
          try {
            entity.deleteSync();
            debugPrint("🧹 Deleted old file: ${entity.path}");
          } catch (_) {}
        }
      }
    }
  }
}

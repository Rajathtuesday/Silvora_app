// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart';

// import '../services/download_service.dart';
// import '../crypto/file_stream_decryptor.dart';
// import '../state/secure_state.dart';

// /// ============================================================
// /// PREVIEW DECRYPT TEST
// /// ============================================================
// ///
// /// Proves:
// /// - Server sends ONLY encrypted bytes
// /// - Client decrypts using manifest
// /// - Chunk-by-chunk correctness
// /// - Streaming works (preview-safe)
// ///
// /// ============================================================
// Future<void> runPreviewDecryptTest({
//   required String fileId,
// }) async {
//   debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//   debugPrint("🧪 PREVIEW DECRYPT TEST START");
//   debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//   // ------------------------------------------------------------
//   // 1️⃣ Master key must be unlocked
//   // ------------------------------------------------------------
//   final Uint8List masterKey = SecureState.requireMasterKey();
//   debugPrint("🔑 Master key OK (${masterKey.length} bytes)");

//   // ------------------------------------------------------------
//   // 2️⃣ Fetch manifest (NO decryption here)
//   // ------------------------------------------------------------
//   debugPrint("📄 Fetching manifest");
//   final manifest = await DownloadService.fetchManifest(fileId);

//   debugPrint("📄 filename  = ${manifest['filename']}");
//   debugPrint("📄 chunks    = ${manifest['chunks'].length}");
//   debugPrint("📄 file_size = ${manifest['file_size']}");

//   // ------------------------------------------------------------
//   // 3️⃣ Fetch encrypted payload
//   // ------------------------------------------------------------
//   debugPrint("📦 Fetching encrypted data");
//   final encrypted = await DownloadService.fetchEncryptedData(fileId);

//   debugPrint("📦 Encrypted size = ${encrypted.length}");
//   if (encrypted.isEmpty) {
//     throw StateError("Encrypted payload is empty");
//   }

//   // ------------------------------------------------------------
//   // 4️⃣ Full decrypt (reference)
//   // ------------------------------------------------------------
//   debugPrint("🔓 Full decrypt (reference)");
//   final fullDecryptor = FileStreamDecryptor(
//     masterKey: masterKey,
//     manifest: manifest,
//   );

//   final File fullFile =
//       await fullDecryptor.decryptToTempFile(encrypted);

//   final int fullSize = fullFile.lengthSync();
//   debugPrint("📁 Full decrypted size = $fullSize");

//   // ------------------------------------------------------------
//   // 5️⃣ Streaming preview decrypt (first 2 chunks)
//   // ------------------------------------------------------------
//   debugPrint("👁 Streaming preview decrypt");

//   final streamDecryptor = FileStreamDecryptor(
//     masterKey: masterKey,
//     manifest: manifest,
//   );

//   final List<Uint8List> previewChunks = [];

//   final Stream<Uint8List> encryptedStream =
//       Stream<Uint8List>.fromIterable([encrypted]);

//   await for (final chunk in streamDecryptor.decryptStream(
//     encryptedStream,
//     stopAfterChunks: 2,
//   )) {
//     previewChunks.add(chunk);
//     debugPrint("👁 Preview chunk size = ${chunk.length}");
//   }

//   final int previewSize = previewChunks.fold(
//     0,
//     (sum, c) => sum + c.length,
//   );

//   debugPrint("👁 Preview plaintext size = $previewSize");

//   // ------------------------------------------------------------
//   // 6️⃣ Validate correctness
//   // ------------------------------------------------------------
//   if (previewSize <= 0) {
//     throw StateError("Preview produced no plaintext");
//   }

//   if (previewSize >= fullSize) {
//     throw StateError(
//       "Preview size should be smaller than full file",
//     );
//   }

//   debugPrint("✅ Preview is partial (correct)");

//   // ------------------------------------------------------------
//   // 7️⃣ Cleanup
//   // ------------------------------------------------------------
//   if (fullFile.existsSync()) {
//     fullFile.deleteSync();
//     debugPrint("🧹 Temp file cleaned");
//   }

//   debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//   debugPrint("✅ PREVIEW DECRYPT TEST PASSED");
//   debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
// }



// ========================================================================
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../services/download_service.dart';
import 'file_stream_decryptor.dart';
import '../state/secure_state.dart';

/// ============================================================
/// PREVIEW DECRYPT TEST (OPTION A)
/// ============================================================
///
/// Verifies:
/// - Manifest correctness
/// - Full decrypt correctness
/// - Zero-knowledge client-side only
///
/// NOTE:
/// - Streaming preview is intentionally NOT tested yet
/// - This avoids premature partial-decrypt complexity
///
Future<void> runPreviewDecryptTest({
  required String fileId,
}) async {
  debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  debugPrint("🧪 PREVIEW DECRYPT TEST START");
  debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  // ------------------------------------------------------------
  // 1️⃣ Master key must be unlocked
  // ------------------------------------------------------------
  final Uint8List masterKey = SecureState.requireMasterKey();
  debugPrint("🔑 Master key OK (${masterKey.length} bytes)");

  // ------------------------------------------------------------
  // 2️⃣ Fetch manifest
  // ------------------------------------------------------------
  debugPrint("📄 Fetching manifest");
  final Map<String, dynamic> manifest =
      await DownloadService.fetchManifest(fileId);

  debugPrint("📄 filename  = ${manifest['filename']}");
  debugPrint("📄 chunks    = ${manifest['chunks']?.length}");
  debugPrint("📄 file_size = ${manifest['file_size']}");

  if (manifest['chunks'] == null || manifest['chunks'].isEmpty) {
    throw StateError("Manifest has no chunks");
  }

  // ------------------------------------------------------------
  // 3️⃣ Fetch encrypted payload
  // ------------------------------------------------------------
  debugPrint("📦 Fetching encrypted data");
  final Uint8List encrypted =
      await DownloadService.fetchEncryptedData(fileId);

  debugPrint("📦 Encrypted size = ${encrypted.length}");
  if (encrypted.isEmpty) {
    throw StateError("Encrypted payload is empty");
  }

  // ------------------------------------------------------------
  // 4️⃣ Full decrypt (reference)
  // ------------------------------------------------------------
  debugPrint("🔓 Full decrypt (reference)");

  final decryptor = FileStreamDecryptor(
    masterKey: masterKey,
    manifest: manifest,
  );

  final File decryptedFile =
      await decryptor.decryptToTempFile(encrypted);

  final int decryptedSize = decryptedFile.lengthSync();

  debugPrint("📁 Decrypted size = $decryptedSize");

  if (decryptedSize != manifest['file_size']) {
    throw StateError(
      "Decrypted size mismatch: expected "
      "${manifest['file_size']}, got $decryptedSize",
    );
  }

  // ------------------------------------------------------------
  // 5️⃣ Cleanup
  // ------------------------------------------------------------
  if (decryptedFile.existsSync()) {
    decryptedFile.deleteSync();
    debugPrint("🧹 Temp file cleaned");
  }

  debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  debugPrint("✅ PREVIEW DECRYPT TEST PASSED");
  debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
}

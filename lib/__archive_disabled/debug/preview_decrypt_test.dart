

// // ========================================================================
// // lib/crypto/preview_decrypt_test.dart
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart';

// import '../../services/download_service.dart';
// import '../crypto/file_stream_decryptor.dart';
// import '../../state/secure_state.dart';

// /// ============================================================
// /// PREVIEW DECRYPT TEST (OPTION A)
// /// ============================================================
// ///
// /// Verifies:
// /// - Manifest correctness
// /// - Full decrypt correctness
// /// - Zero-knowledge client-side only
// ///
// /// NOTE:
// /// - Streaming preview is intentionally NOT tested yet
// /// - This avoids premature partial-decrypt complexity
// ///
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
//   // 2️⃣ Fetch manifest
//   // ------------------------------------------------------------
//   debugPrint("📄 Fetching manifest");
//   final Map<String, dynamic> manifest =
//       await DownloadService.fetchManifest(fileId);

//   debugPrint("📄 filename  = ${manifest['filename']}");
//   debugPrint("📄 chunks    = ${manifest['chunks']?.length}");
//   debugPrint("📄 file_size = ${manifest['file_size']}");

//   if (manifest['chunks'] == null || manifest['chunks'].isEmpty) {
//     throw StateError("Manifest has no chunks");
//   }

//   // ------------------------------------------------------------
//   // 3️⃣ Fetch encrypted payload
//   // ------------------------------------------------------------
//   debugPrint("📦 Fetching encrypted data");
//   final Uint8List encrypted =
//       await DownloadService.fetchEncryptedData(fileId);

//   debugPrint("📦 Encrypted size = ${encrypted.length}");
//   if (encrypted.isEmpty) {
//     throw StateError("Encrypted payload is empty");
//   }

//   // ------------------------------------------------------------
//   // 4️⃣ Full decrypt (reference)
//   // ------------------------------------------------------------
//   debugPrint("🔓 Full decrypt (reference)");

//   final decryptor = FileStreamDecryptor(
//     masterKey: masterKey,
//     manifest: manifest,
//   );

//   final File decryptedFile =
//       await decryptor.decryptToTempFile(encrypted);

//   final int decryptedSize = decryptedFile.lengthSync();

//   debugPrint("📁 Decrypted size = $decryptedSize");

//   if (decryptedSize != manifest['file_size']) {
//     throw StateError(
//       "Decrypted size mismatch: expected "
//       "${manifest['file_size']}, got $decryptedSize",
//     );
//   }

//   // ------------------------------------------------------------
//   // 5️⃣ Cleanup
//   // ------------------------------------------------------------
//   if (decryptedFile.existsSync()) {
//     decryptedFile.deleteSync();
//     debugPrint("🧹 Temp file cleaned");
//   }

//   debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//   debugPrint("✅ PREVIEW DECRYPT TEST PASSED");
//   debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
// }

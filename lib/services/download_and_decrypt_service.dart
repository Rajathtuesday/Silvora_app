// import 'dart:io';
// import 'dart:typed_data';


// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';

// import '../crypto/file_stream_decryptor.dart';
// import '../services/download_service.dart';
// import '../state/secure_state.dart';

// /// Handles secure E2EE downloads across platforms
// class DownloadAndDecryptService {
//   /// Entry point
//   static Future<void> downloadFile({
//     required String fileId,
//     required String filename,
//   }) async {
//     debugPrint("⬇️ DOWNLOAD INIT → $filename");

//     // 🔐 Vault must be unlocked
//     final masterKey = SecureState.requireMasterKey();

//     // 📄 Fetch manifest
//     final manifest =
//         await DownloadService.fetchManifest(fileId);

//     // 📦 Fetch encrypted payload
//     final encrypted =
//         await DownloadService.fetchEncryptedData(fileId);

//     debugPrint("📦 Encrypted bytes = ${encrypted.length}");

//     if (encrypted.isEmpty) {
//       throw StateError("Encrypted payload empty");
//     }

//     // 🔓 Decrypt
//     final decryptor = FileStreamDecryptor(
//       masterKey: masterKey,
//       manifest: manifest,
//     );

//     if (kIsWeb) {
//       await _downloadWeb(
//         decryptor,
//         encrypted,
//         filename,
//       );
//     } else {
//       await _downloadMobile(
//         decryptor,
//         encrypted,
//         filename,
//       );
//     }

//     debugPrint("✅ DOWNLOAD COMPLETE → $filename");
//   }

//   // ─────────────────────────────
//   // ANDROID / IOS
//   // ─────────────────────────────
//   static Future<void> _downloadMobile(
//     FileStreamDecryptor decryptor,
//     Uint8List encrypted,
//     String filename,
//   ) async {
//     debugPrint("📱 Mobile download path");

//     final tempFile =
//         await decryptor.decryptToTempFile(encrypted);

//     final downloadsDir =
//         await getDownloadsDirectory() ??
//             await getApplicationDocumentsDirectory();

//     final outFile =
//         File("${downloadsDir.path}/$filename");

//     await tempFile.copy(outFile.path);

//     debugPrint("📁 Saved to ${outFile.path}");
//   }

//   // ─────────────────────────────
//   // WEB
//   // ─────────────────────────────
//   static Future<void> _downloadWeb(
//     FileStreamDecryptor decryptor,
//     Uint8List encrypted,
//     String filename,
//   ) async {
//     debugPrint("🌐 Web download path");

//     // Web cannot use File → decrypt into memory
//     final plain = await _decryptToMemory(
//       decryptor,
//       encrypted,
//     );

//     // ignore: avoid_web_libraries_in_flutter
    

//     final blob = html.Blob([plain]);
//     final url = html.Url.createObjectUrlFromBlob(blob);

//     final anchor = html.AnchorElement(href: url)
//       ..setAttribute("download", filename)
//       ..click();

//     html.Url.revokeObjectUrl(url);

//     debugPrint("🌐 Browser download triggered");
//   }

//   // ─────────────────────────────
//   // MEMORY DECRYPT (WEB ONLY)
//   // ─────────────────────────────
//   static Future<Uint8List> _decryptToMemory(
//     FileStreamDecryptor decryptor,
//     Uint8List encrypted,
//   ) async {
//     final tmpFile =
//         await decryptor.decryptToTempFile(encrypted);

//     final bytes = await tmpFile.readAsBytes();

//     // Cleanup
//     tmpFile.deleteSync();

//     return bytes;
//   }
// }
// ========================================================================
// lib/services/download_and_decrypt_service.dart

// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/src/widgets/framework.dart';

// import '../crypto/file_stream_decryptor.dart';
// import '../services/download_service.dart';
// import '../state/secure_state.dart';

// class DownloadAndDecryptService {
//   /// Entry point used by UI
//   static Future<void> downloadFile({
//     required String fileId,
//     required String filename, required BuildContext context,
//   }) async {
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("⬇️ DOWNLOAD INIT");
//     debugPrint("📄 fileId   = $fileId");
//     debugPrint("📄 filename = $filename");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     // ─────────────────────────────
//     // Phase 1: Master key
//     // ─────────────────────────────
//     final masterKey = SecureState.requireMasterKey();
//     debugPrint("🔑 Master key OK (len=${masterKey.length})");

//     // ─────────────────────────────
//     // Phase 2: Manifest
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching manifest");
//     final manifest =
//         await DownloadService.fetchManifest(fileId);

//     debugPrint("📄 Manifest loaded");
//     debugPrint("📄 chunks    = ${manifest['chunks']?.length}");
//     debugPrint("📄 file_size = ${manifest['file_size']}");

//     // ─────────────────────────────
//     // Phase 3: Encrypted payload
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching encrypted data");
//     final encrypted =
//         await DownloadService.fetchEncryptedData(fileId);

//     debugPrint("📦 Encrypted bytes = ${encrypted.length}");

//     if (encrypted.isEmpty) {
//       throw StateError("Encrypted payload is empty");
//     }

//     // ─────────────────────────────
//     // Phase 4: Decrypt → temp file
//     // ─────────────────────────────
//     debugPrint("🟢 Starting decryption");

//     final decryptor = FileStreamDecryptor(
//       masterKey: masterKey,
//       manifest: manifest,
//     );

//     final tempFile =
//         await decryptor.decryptToTempFile(encrypted);

//     debugPrint("🔓 Decryption complete");
//     debugPrint("📁 Temp path = ${tempFile.path}");
//     debugPrint("📁 Temp size = ${tempFile.lengthSync()} bytes");

//     // ─────────────────────────────
//     // Phase 5: Copy to Downloads
//     // ─────────────────────────────
//     final outFile =
//         await _saveToDownloads(tempFile, filename);

//     debugPrint("✅ File saved");
//     debugPrint("📁 Download path = ${outFile.path}");

//     // ─────────────────────────────
//     // Cleanup
//     // ─────────────────────────────
//     if (tempFile.existsSync()) {
//       tempFile.deleteSync();
//       debugPrint("🧹 Temp file deleted");
//     }

//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("✅ DOWNLOAD COMPLETE");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//   }

//   // ============================================================
//   // MOBILE-ONLY SAVE LOGIC (ANDROID)
//   // ============================================================

//   static Future<File> _saveToDownloads(
//     File source,
//     String filename,
//   ) async {
//     // ⚠️ Android-specific path (OK for now)
//     final downloadsDir =
//         Directory("/storage/emulated/0/Download");

//     if (!downloadsDir.existsSync()) {
//       downloadsDir.createSync(recursive: true);
//     }

//     final outPath = "${downloadsDir.path}/$filename";
//     final outFile = File(outPath);

//     await source.copy(outFile.path);

//     return outFile;
//   }
// }
// ============================================================
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';

// import '../crypto/file_stream_decryptor.dart';
// import '../services/download_service.dart';
// import '../state/secure_state.dart';

// typedef DownloadProgressCallback = void Function(double progress);
// typedef DownloadStatusCallback = void Function(String message);

// class DownloadAndDecryptService {
//   /// MAIN ENTRY POINT
//   static Future<void> downloadFile({
//     required String fileId,
//     required String filename,
//     DownloadProgressCallback? onProgress,
//     DownloadStatusCallback? onStatus,
//   }) async {
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("⬇️ DOWNLOAD INIT");
//     debugPrint("📄 fileId   = $fileId");
//     debugPrint("📄 filename = $filename");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     File? tempFile;

//     try {
//       // ─────────────────────────────
//       // Phase 1: Master key
//       // ─────────────────────────────
//       onStatus?.call("Unlocking vault…");
//       final masterKey = SecureState.requireMasterKey();
//       debugPrint("🔑 Master key OK (len=${masterKey.length})");

//       // ─────────────────────────────
//       // Phase 2: Manifest
//       // ─────────────────────────────
//       onStatus?.call("Fetching file metadata…");
//       debugPrint("🟢 Fetching manifest");
//       final manifest = await DownloadService.fetchManifest(fileId);

//       final totalChunks = (manifest['chunks'] as List).length;
//       debugPrint("📄 Manifest loaded (chunks=$totalChunks)");

//       // ─────────────────────────────
//       // Phase 3: Encrypted data
//       // ─────────────────────────────
//       onStatus?.call("Downloading encrypted file…");
//       debugPrint("🟢 Fetching encrypted data");
//       final encrypted =
//           await DownloadService.fetchEncryptedData(fileId);

//       if (encrypted.isEmpty) {
//         throw StateError("Encrypted payload is empty");
//       }

//       debugPrint("📦 Encrypted bytes = ${encrypted.length}");

//       // ─────────────────────────────
//       // Phase 4: Decryption
//       // ─────────────────────────────
//       onStatus?.call("Decrypting file…");
//       debugPrint("🟢 Starting decryption");

//       final decryptor = FileStreamDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//         onChunkDecrypted: (index) {
//           final progress =
//               (index + 1) / totalChunks * 0.85; // 85% reserved for decrypt
//           onProgress?.call(progress);
//         },
//       );

//       tempFile = await decryptor.decryptToTempFile(encrypted);

//       debugPrint("🔓 Decryption complete");
//       debugPrint("📁 Temp path = ${tempFile.path}");

//       // ─────────────────────────────
//       // Phase 5: Save via system picker
//       // ─────────────────────────────
//       onStatus?.call("Choose where to save…");
//       final savedFile =
//           await _saveViaSystemPicker(tempFile, filename);

//       onProgress?.call(1.0);

//       debugPrint("✅ File saved at ${savedFile.path}");
//       onStatus?.call("Download completed");

//       debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//       debugPrint("✅ DOWNLOAD COMPLETE");
//       debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     } catch (e, st) {
//       debugPrint("❌ DOWNLOAD FAILED");
//       debugPrint("❌ Error: $e");
//       debugPrint(st.toString());
//       rethrow;
//     } finally {
//       // ─────────────────────────────
//       // Cleanup
//       // ─────────────────────────────
//       if (tempFile != null && tempFile.existsSync()) {
//         tempFile.deleteSync();
//         debugPrint("🧹 Temp file cleaned");
//       }
//     }
//   }

//   // ============================================================
//   // SYSTEM SAVE (ANDROID SAFE)
//   // ============================================================

//   static Future<File> _saveViaSystemPicker(
//     File source,
//     String filename,
//   ) async {
//     debugPrint("📂 Opening system save dialog");

//     final targetPath = await FilePicker.platform.saveFile(
//       dialogTitle: "Save decrypted file",
//       fileName: filename,
//     );

//     if (targetPath == null) {
//       throw Exception("User cancelled save dialog");
//     }

//     final outFile = File(targetPath);
//     await source.copy(outFile.path);

//     return outFile;
//   }
// }
// ============================================================
// import 'dart:io';

// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';

// import '../crypto/file_stream_decryptor.dart';
// import '../services/download_service.dart';
// import '../state/secure_state.dart';

// class DownloadAndDecryptService {
//   /// ============================================================
//   /// PUBLIC ENTRY POINT
//   /// ============================================================
//   static Future<File> downloadAndDecrypt({
//     required String fileId,
//     required String filename,
//   }) async {
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("⬇️ DOWNLOAD + DECRYPT INIT");
//     debugPrint("📄 fileId   = $fileId");
//     debugPrint("📄 filename = $filename");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     // ─────────────────────────────
//     // Phase 1: Master key
//     // ─────────────────────────────
//     final masterKey = SecureState.requireMasterKey();
//     debugPrint("🔑 Master key OK (len=${masterKey.length})");

//     // ─────────────────────────────
//     // Phase 2: Fetch manifest
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching manifest");
//     final manifest = await DownloadService.fetchManifest(fileId);

//     debugPrint("📄 Manifest loaded");
//     debugPrint("📄 chunks    = ${manifest['chunks']?.length}");
//     debugPrint("📄 file_size = ${manifest['file_size']}");

//     // ─────────────────────────────
//     // Phase 3: Fetch encrypted payload
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching encrypted data");
//     final encrypted =
//         await DownloadService.fetchEncryptedData(fileId);

//     debugPrint("📦 Encrypted bytes = ${encrypted.length}");

//     if (encrypted.isEmpty) {
//       throw StateError("Encrypted payload is empty");
//     }

//     // ─────────────────────────────
//     // Phase 4: Decrypt → temp file
//     // ─────────────────────────────
//     debugPrint("🟢 Starting decryption");

//     final decryptor = FileStreamDecryptor(
//       masterKey: masterKey,
//       manifest: manifest,
//     );

//     final tempFile =
//         await decryptor.decryptToTempFile(encrypted);

//     debugPrint("🔓 Decryption complete");
//     debugPrint("📁 Temp path = ${tempFile.path}");
//     debugPrint("📁 Temp size = ${tempFile.lengthSync()} bytes");

//     // ─────────────────────────────
//     // Phase 5: Save to app Downloads
//     // ─────────────────────────────
//     final outFile =
//         await _saveToAppDownloads(tempFile, filename);

//     debugPrint("✅ File saved");
//     debugPrint("📁 Download path = ${outFile.path}");

//     // ─────────────────────────────
//     // Cleanup
//     // ─────────────────────────────
//     if (tempFile.existsSync()) {
//       tempFile.deleteSync();
//       debugPrint("🧹 Temp file deleted");
//     }

//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("✅ DOWNLOAD COMPLETE");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     return outFile;
//   }

//   /// ============================================================
//   /// ANDROID / IOS SAFE SAVE LOCATION
//   /// ============================================================
//   static Future<File> _saveToAppDownloads(
//     File source,
//     String filename,
//   ) async {
//     final Directory baseDir;

//     if (Platform.isAndroid) {
//       // ✅ Scoped storage safe (no permission needed)
//       baseDir = await getExternalStorageDirectory()
//           ?? await getApplicationDocumentsDirectory();
//     } else if (Platform.isIOS) {
//       baseDir = await getApplicationDocumentsDirectory();
//     } else {
//       baseDir = await getApplicationDocumentsDirectory();
//     }

//     final downloadsDir =
//         Directory("${baseDir.path}/downloads");

//     if (!downloadsDir.existsSync()) {
//       downloadsDir.createSync(recursive: true);
//     }

//     final outPath = "${downloadsDir.path}/$filename";
//     final outFile = File(outPath);

//     await source.copy(outFile.path);

//     return outFile;
//   }
// }
// ============================================================
// lib/services/download_and_decrypt_service.dart

// import 'dart:io';

// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// // import 'package:image_gallery_saver/image_gallery_saver.dart';

// import '../crypto/file_stream_decryptor.dart';
// import '../services/download_service.dart';
// import '../state/secure_state.dart';

// class DownloadAndDecryptService {
//   // ============================================================
//   // PUBLIC ENTRY POINT
//   // ============================================================
//   static Future<File> downloadAndDecrypt({
//     required String fileId,
//     required String filename,
//     bool saveToGallery = false,
//   }) async {
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("⬇️ DOWNLOAD + DECRYPT INIT");
//     debugPrint("📄 fileId   = $fileId");
//     debugPrint("📄 filename = $filename");
//     debugPrint("🖼 saveToGallery = $saveToGallery");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     // ─────────────────────────────
//     // Phase 1: Master key
//     // ─────────────────────────────
//     final masterKey = SecureState.requireMasterKey();
//     debugPrint("🔑 Master key OK (len=${masterKey.length})");

//     // ─────────────────────────────
//     // Phase 2: Fetch manifest
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching manifest");
//     final manifest = await DownloadService.fetchManifest(fileId);

//     debugPrint("📄 Manifest loaded");
//     debugPrint("📄 chunks    = ${manifest['chunks']?.length}");
//     debugPrint("📄 file_size = ${manifest['file_size']}");

//     // ─────────────────────────────
//     // Phase 3: Fetch encrypted data
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching encrypted data");
//     final encrypted = await DownloadService.fetchEncryptedData(fileId);

//     debugPrint("📦 Encrypted bytes = ${encrypted.length}");
//     if (encrypted.isEmpty) {
//       throw StateError("Encrypted payload is empty");
//     }

//     // ─────────────────────────────
//     // Phase 4: Decrypt to temp file
//     // ─────────────────────────────
//     debugPrint("🟢 Starting decryption");

//     final decryptor = FileStreamDecryptor(
//       masterKey: masterKey,
//       manifest: manifest,
//     );

//     final tempFile = await decryptor.decryptToTempFile(encrypted);

//     debugPrint("🔓 Decryption complete");
//     debugPrint("📁 Temp path = ${tempFile.path}");
//     debugPrint("📁 Temp size = ${tempFile.lengthSync()} bytes");

//     // ─────────────────────────────
//     // Phase 5: Save to app downloads
//     // ─────────────────────────────
//     final outFile = await _saveToAppDownloads(tempFile, filename);

//     debugPrint("✅ File saved to app downloads");
//     debugPrint("📁 Download path = ${outFile.path}");

//     // ─────────────────────────────
//     // Phase 6: Optional gallery save
//     // ─────────────────────────────
//     // if (saveToGallery && _isMediaFile(filename)) {
//     //   try {
//     //     final result = await ImageGallerySaver.saveFile(
//     //       outFile.path,
//     //       isReturnPathOfIOS: true,
//     //     );

//     //     if (result['isSuccess'] == true) {
//     //       debugPrint("🖼 Saved copy to gallery");
//     //     } else {
//     //       debugPrint("⚠️ Gallery save failed");
//     //     }
//     //   } catch (e) {
//     //     debugPrint("⚠️ Gallery error: $e");
//     //   }
//     // }

//     // ─────────────────────────────
//     // Cleanup temp file
//     // ─────────────────────────────
//     if (tempFile.existsSync()) {
//       tempFile.deleteSync();
//       debugPrint("🧹 Temp file deleted");
//     }

//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("✅ DOWNLOAD COMPLETE");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     return outFile;
//   }

//   // ============================================================
//   // SAFE APP DOWNLOAD LOCATION (ANDROID / IOS)
//   // ============================================================
//   static Future<File> _saveToAppDownloads(
//     File source,
//     String filename,
//   ) async {
//     final Directory baseDir;

//     if (Platform.isAndroid) {
//       // Scoped storage safe (no permission needed)
//       baseDir = await getExternalStorageDirectory() ??
//           await getApplicationDocumentsDirectory();
//     } else {
//       baseDir = await getApplicationDocumentsDirectory();
//     }

//     final downloadsDir = Directory("${baseDir.path}/downloads");

//     if (!downloadsDir.existsSync()) {
//       downloadsDir.createSync(recursive: true);
//     }

//     final outPath = "${downloadsDir.path}/$filename";
//     final outFile = File(outPath);

//     await source.copy(outFile.path);
//     return outFile;
//   }

//   // ============================================================
//   // MEDIA FILE CHECK (for gallery)
//   // ============================================================
//   static bool _isMediaFile(String filename) {
//     final f = filename.toLowerCase();
//     return f.endsWith('.jpg') ||
//         f.endsWith('.jpeg') ||
//         f.endsWith('.png') ||
//         f.endsWith('.mp4') ||
//         f.endsWith('.mov');
//   }

//   // ============================================================
//   // OPTIONAL CLEANUP (call once per app launch)
//   // ============================================================
//   static Future<void> cleanupOldDownloads({
//     Duration maxAge = const Duration(days: 7),
//   }) async {
//     final Directory baseDir =
//         await getExternalStorageDirectory() ??
//             await getApplicationDocumentsDirectory();

//     final downloadsDir = Directory("${baseDir.path}/downloads");

//     if (!downloadsDir.existsSync()) return;

//     final now = DateTime.now();

//     for (final entity in downloadsDir.listSync()) {
//       if (entity is File) {
//         final stat = entity.statSync();
//         if (now.difference(stat.modified) > maxAge) {
//           try {
//             entity.deleteSync();
//             debugPrint("🧹 Deleted old file: ${entity.path}");
//           } catch (_) {}
//         }
//       }
//     }
//   }
// }
// ============================================================

// lib/services/download_and_decrypt_service.dart
// lib/services/download_and_decrypt_service.dart

// import 'dart:io';

// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';

// import '../crypto/file_stream_decryptor.dart';
// import '../services/download_service.dart';
// import '../state/secure_state.dart';

// class DownloadAndDecryptService {
//   // ============================================================
//   // PUBLIC ENTRY POINT
//   // ============================================================
//   static Future<File> downloadAndDecrypt({
//     required String fileId,
//     required String filename,
//   }) async {
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("⬇️ DOWNLOAD + DECRYPT INIT");
//     debugPrint("📄 fileId   = $fileId");
//     debugPrint("📄 filename = $filename");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     // ─────────────────────────────
//     // Phase 1: Master key
//     // ─────────────────────────────
//     final masterKey = SecureState.requireMasterKey();
//     debugPrint("🔑 Master key OK (len=${masterKey.length})");

//     // ─────────────────────────────
//     // Phase 2: Fetch manifest
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching manifest");
//     final manifest = await DownloadService.fetchManifest(fileId);

//     debugPrint("📄 Manifest loaded");
//     debugPrint("📄 chunks    = ${manifest['chunks']?.length}");
//     debugPrint("📄 file_size = ${manifest['file_size']}");

//     // ─────────────────────────────
//     // Phase 3: Fetch encrypted payload
//     // ─────────────────────────────
//     debugPrint("🟢 Fetching encrypted data");
//     final encrypted = await DownloadService.fetchEncryptedData(fileId);

//     if (encrypted.isEmpty) {
//       throw StateError("❌ Encrypted payload is empty");
//     }

//     debugPrint("📦 Encrypted bytes = ${encrypted.length}");

//     // ─────────────────────────────
//     // Phase 4: Decrypt → temp file
//     // ─────────────────────────────
//     debugPrint("🟢 Starting decryption");

//     final decryptor = FileStreamDecryptor(
//       masterKey: masterKey,
//       manifest: manifest,
//     );

//     final tempFile = await decryptor.decryptToTempFile(encrypted);

//     debugPrint("🔓 Decryption complete");
//     debugPrint("📁 Temp path = ${tempFile.path}");
//     debugPrint("📁 Temp size = ${tempFile.lengthSync()} bytes");

//     // ─────────────────────────────
//     // Phase 5: Save to PUBLIC Downloads
//     // ─────────────────────────────
//     final outFile =
//         await _saveToPublicDownloads(tempFile, filename);

//     debugPrint("✅ File saved to PUBLIC Downloads");
//     debugPrint("📥 Download path = ${outFile.path}");

//     // ─────────────────────────────
//     // Phase 6: Cleanup temp file
//     // ─────────────────────────────
//     try {
//       if (tempFile.existsSync()) {
//         tempFile.deleteSync();
//         debugPrint("🧹 Temp file deleted");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Temp cleanup failed: $e");
//     }

//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("✅ DOWNLOAD COMPLETE");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     return outFile;
//   }

//   // ============================================================
//   // SAVE TO PUBLIC DOWNLOADS (VISIBLE TO USER)
//   // ============================================================
//   static Future<File> _saveToPublicDownloads(
//     File source,
//     String filename,
//   ) async {
//     if (Platform.isAndroid) {
//       // Android public Downloads directory
//       final downloadsDir =
//           Directory('/storage/emulated/0/Download');

//       if (!downloadsDir.existsSync()) {
//         downloadsDir.createSync(recursive: true);
//       }

//       final outFile =
//           File('${downloadsDir.path}/$filename');

//       await source.copy(outFile.path);

//       return outFile;
//     }

//     // iOS / desktop fallback
//     final dir = await getApplicationDocumentsDirectory();
//     final outFile = File('${dir.path}/$filename');
//     await source.copy(outFile.path);
//     return outFile;
//   }

//   // ============================================================
//   // OPTIONAL UTILITY: MEDIA FILE CHECK
//   // (future gallery / preview use)
//   // ============================================================
//   static bool isMediaFile(String filename) {
//     final f = filename.toLowerCase();
//     return f.endsWith('.jpg') ||
//         f.endsWith('.jpeg') ||
//         f.endsWith('.png') ||
//         f.endsWith('.mp4') ||
//         f.endsWith('.mov') ||
//         f.endsWith('.webp');
//   }

//   // ============================================================
//   // OPTIONAL MAINTENANCE (CALL ON APP START)
//   // ============================================================
//   static Future<void> cleanupOldPublicDownloads({
//     Duration maxAge = const Duration(days: 14),
//   }) async {
//     if (!Platform.isAndroid) return;

//     final downloadsDir =
//         Directory('/storage/emulated/0/Download');

//     if (!downloadsDir.existsSync()) return;

//     final now = DateTime.now();

//     for (final entity in downloadsDir.listSync()) {
//       if (entity is File) {
//         try {
//           final stat = entity.statSync();
//           if (now.difference(stat.modified) > maxAge) {
//             entity.deleteSync();
//             debugPrint("🧹 Deleted old download: ${entity.path}");
//           }
//         } catch (_) {}
//       }
//     }
//   }
// }
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

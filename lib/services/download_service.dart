// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

// import '../state/secure_state.dart';

// class DownloadService {
//   static final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

//   /// TEMP: same dummy key as upload.
//   /// TODO: replace with real file key derived from master key.
//   static Uint8List _deriveFileKey() {
//     return Uint8List(32); // 256-bit all-zero key
//   }

//   /// Fetch manifest.json for a given upload_id.
//   static Future<Map<String, dynamic>?> fetchManifest(String uploadId) async {
//     final url = Uri.parse(
//       "${SecureState.serverUrl}/media/uploads/$uploadId/manifest.json",
//     );

//     try {
//       final resp = await http.get(url, headers: {
//         "Authorization": "Bearer ${SecureState.accessToken}",
//       });

//       if (resp.statusCode == 200) {
//         return jsonDecode(utf8.decode(resp.bodyBytes))
//             as Map<String, dynamic>;
//       } else {
//         print("fetchManifest failed: ${resp.statusCode} ${resp.body}");
//         return null;
//       }
//     } catch (e) {
//       print("fetchManifest exception: $e");
//       return null;
//     }
//   }

//   /// Download the encrypted final.bin via your /upload/download/<file_id>/ endpoint.
//   static Future<Uint8List?> downloadEncryptedFile(String fileId) async {
//     final url = Uri.parse(
//       "${SecureState.serverUrl}/upload/download/$fileId/",
//     );

//     try {
//       final resp = await http.get(url, headers: {
//         "Authorization": "Bearer ${SecureState.accessToken}",
//       });

//       if (resp.statusCode == 200) {
//         return Uint8List.fromList(resp.bodyBytes);
//       } else {
//         print(
//             "downloadEncryptedFile failed: ${resp.statusCode} ${resp.body}");
//         return null;
//       }
//     } catch (e) {
//       print("downloadEncryptedFile exception: $e");
//       return null;
//     }
//   }

//   /// High-level helper:
//   /// 1) fetch manifest
//   /// 2) download encrypted final.bin
//   /// 3) decrypt chunk-by-chunk using nonce_b64 + mac_b64
//   /// 4) save plaintext to app docs dir and return File
//   static Future<File?> downloadAndDecryptFile({
//     required String fileId,
//     required String uploadId,
//     required String filename,
//   }) async {
//     final manifest = await fetchManifest(uploadId);
//     if (manifest == null) {
//       print("Manifest not found for uploadId=$uploadId");
//       return null;
//     }

//     final chunks = manifest["chunks"];
//     if (chunks is! List || chunks.isEmpty) {
//       print("Manifest has no chunks");
//       return null;
//     }

//     final encryptedBytes = await downloadEncryptedFile(fileId);
//     if (encryptedBytes == null) {
//       print("Failed to download encrypted final.bin for fileId=$fileId");
//       return null;
//     }

//     final secretKey = SecretKey(_deriveFileKey());

//     // Decrypt each chunk in order, using ciphertext_size, nonce_b64, mac_b64.
//     int offset = 0;
//     final builder = BytesBuilder();

//     // Sort chunks by index just in case
//     final sortedChunks = List<Map<String, dynamic>>.from(
//       chunks.cast<Map<String, dynamic>>(),
//     )..sort((a, b) => (a["index"] as int).compareTo(b["index"] as int));

//     for (final meta in sortedChunks) {
//       final int size = meta["ciphertext_size"] as int;
//       final String nonceB64 = meta["nonce_b64"] as String;
//       final String macB64 = meta["mac_b64"] as String;

//       if (offset + size > encryptedBytes.length) {
//         print("Ciphertext size mismatch for chunk index ${meta["index"]}");
//         return null;
//       }

//       final chunkCiphertext =
//           encryptedBytes.sublist(offset, offset + size);
//       offset += size;

//       final nonce = base64Decode(nonceB64);
//       final macBytes = base64Decode(macB64);

//       final secretBox = SecretBox(
//         chunkCiphertext,
//         nonce: nonce,
//         mac: Mac(macBytes),
//       );

//       final plainChunk = await _algorithm.decrypt(
//         secretBox,
//         secretKey: secretKey,
//       );

//       builder.add(plainChunk);
//     }

//     final plaintext = builder.toBytes();

//     // Save to app's documents directory as the original filename.
//     final docsDir = await getApplicationDocumentsDirectory();
//     final outPath = "${docsDir.path}/$filename";
//     final outFile = File(outPath);
//     await outFile.writeAsBytes(plaintext, flush: true);

//     print("Decrypted file saved to: $outPath");
//     return outFile;
//   }
// }
// ------------------------------------------------------------------------------




// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

// import '../state/secure_state.dart';

// class DownloadService {
//   static final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

//   // TEMP: same static key as upload. Replace with real key later.
//   static Uint8List _fakeKey() => Uint8List(32);

//   /// Fetch manifest.json for an upload_id.
//   static Future<Map<String, dynamic>?> fetchManifest(String uploadId) async {
//     final url = Uri.parse(
//       "${SecureState.serverUrl}/media/uploads/$uploadId/manifest.json",
//     );

//     try {
//       final resp = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer ${SecureState.accessToken}",
//         },
//       );

//       if (resp.statusCode == 200) {
//         return jsonDecode(utf8.decode(resp.bodyBytes))
//             as Map<String, dynamic>;
//       } else {
//         print("fetchManifest failed: ${resp.statusCode} ${resp.body}");
//         return null;
//       }
//     } catch (e) {
//       print("fetchManifest exception: $e");
//       return null;
//     }
//   }

//   /// Download encrypted final.bin via /upload/download/<file_id>/
//   static Future<Uint8List?> downloadEncryptedFile(String fileId) async {
//     final url =
//         Uri.parse("${SecureState.serverUrl}/upload/download/$fileId/");

//     try {
//       final resp = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer ${SecureState.accessToken}",
//         },
//       );

//       if (resp.statusCode == 200) {
//         return Uint8List.fromList(resp.bodyBytes);
//       } else {
//         print("downloadEncryptedFile failed: ${resp.statusCode} ${resp.body}");
//         return null;
//       }
//     } catch (e) {
//       print("downloadEncryptedFile exception: $e");
//       return null;
//     }
//   }

//   /// 1) fetch manifest
//   /// 2) download final.bin (ciphertext)
//   /// 3) decrypt all chunks in memory
//   /// 4) save plaintext as a temp file
//   static Future<File?> downloadAndDecryptFile({
//     required String fileId,
//     required String uploadId,
//     required String filename,
//   }) async {
//     final manifest = await fetchManifest(uploadId);
//     if (manifest == null) {
//       print("Manifest not found for uploadId=$uploadId");
//       return null;
//     }

//     final chunks = manifest["chunks"];
//     if (chunks is! List || chunks.isEmpty) {
//       print("Manifest has no chunks");
//       return null;
//     }

//     final encryptedBytes = await downloadEncryptedFile(fileId);
//     if (encryptedBytes == null) {
//       print("Failed to download encrypted file for fileId=$fileId");
//       return null;
//     }

//     final secretKey = SecretKey(_fakeKey());
//     final builder = BytesBuilder();

//     // sort chunks by index just in case
//     final sorted = List<Map<String, dynamic>>.from(
//       chunks.cast<Map<String, dynamic>>(),
//     )..sort((a, b) => (a["index"] as int).compareTo(b["index"] as int));

//     int offset = 0;

//     for (final meta in sorted) {
//       final int size = meta["ciphertext_size"] as int;
//       final String nonceB64 = meta["nonce_b64"] as String;
//       final String macB64 = meta["mac_b64"] as String;

//       if (offset + size > encryptedBytes.length) {
//         print("Ciphertext out-of-range for chunk index ${meta["index"]}");
//         return null;
//       }

//       final cipherChunk = encryptedBytes.sublist(offset, offset + size);
//       offset += size;

//       final nonce = base64Decode(nonceB64);
//       final macBytes = base64Decode(macB64);

//       final secretBox = SecretBox(
//         cipherChunk,
//         nonce: nonce,
//         mac: Mac(macBytes),
//       );

//       final plainChunk = await _algorithm.decrypt(
//         secretBox,
//         secretKey: secretKey,
//       );

//       builder.add(plainChunk);
//     }

//     final plaintext = builder.toBytes();

//     final dir = await getApplicationDocumentsDirectory();
//     final outPath = "${dir.path}/$filename";
//     final outFile = File(outPath);
//     await outFile.writeAsBytes(plaintext, flush: true);

//     print("Decrypted file saved to: $outPath");
//     return outFile;
//   }
// }
// -----------------------------------------------------------------------------------------



// // lib/services/download_service.dart
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:http/http.dart' as http;

// import '../state/secure_state.dart';

// class DecryptedFileResult {
//   final Uint8List bytes;
//   final String filename;
//   final String mimeType;

//   DecryptedFileResult({
//     required this.bytes,
//     required this.filename,
//     required this.mimeType,
//   });
// }

// class DownloadService {
//   static String get _baseUrl => SecureState.serverUrl;
//   static Map<String, String> _authHeaders() => SecureState.authHeader();

//   static Uri _url(String path) => Uri.parse("$_baseUrl$path");

//   // TEMP: same fake key as upload side (MVP only)
//   static Uint8List _fakeKey() => Uint8List(32);

//   static final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

//   /// Download + decrypt a file by uploadId + filename.
//   ///
//   /// We assume:
//   /// - manifest at /media/uploads/<uploadId>/manifest.json
//   /// - final.bin at /media/uploads/<uploadId>/final.bin
//   static Future<DecryptedFileResult?> downloadAndDecrypt({
//     required String uploadId,
//     required String filename,
//   }) async {
//     // 1) Fetch manifest
//     final manifestRes = await http.get(
//       _url("/media/uploads/$uploadId/manifest.json"),
//       headers: _authHeaders(),
//     );
//     if (manifestRes.statusCode != 200) {
//       print("❌ Failed to fetch manifest: ${manifestRes.statusCode}");
//       return null;
//     }
//     final manifest = jsonDecode(manifestRes.body) as Map<String, dynamic>;
//     final chunksMeta = (manifest["chunks"] as List<dynamic>)
//         .cast<Map<String, dynamic>>();

//     // 2) Fetch final.bin
//     final finalRes = await http.get(
//       _url("/media/uploads/$uploadId/final.bin"),
//       headers: _authHeaders(),
//     );
//     if (finalRes.statusCode != 200) {
//       print("❌ Failed to fetch final.bin: ${finalRes.statusCode}");
//       return null;
//     }
//     final encryptedBytes = finalRes.bodyBytes;

//     // 3) Decrypt per-chunk using manifest metadata
//     final secretKey = SecretKey(_fakeKey());
//     final plainOut = BytesBuilder();
//     int offset = 0;

//     for (final meta in chunksMeta) {
//       final int size = meta["ciphertext_size"] as int;
//       final String nonceB64 = meta["nonce_b64"] as String;
//       final String macB64 = meta["mac_b64"] as String;

//       final chunkCipher = encryptedBytes.sublist(offset, offset + size);
//       offset += size;

//       final nonce = base64Decode(nonceB64);
//       final macBytes = base64Decode(macB64);

//       final secretBox = SecretBox(
//         chunkCipher,
//         nonce: nonce,
//         mac: Mac(macBytes),
//       );

//       final chunkPlain = await _algorithm.decrypt(
//         secretBox,
//         secretKey: secretKey,
//       );

//       plainOut.add(chunkPlain);
//     }

//     final decrypted = plainOut.toBytes();
//     final mimeType = _guessMimeType(filename);

//     return DecryptedFileResult(
//       bytes: decrypted,
//       filename: filename,
//       mimeType: mimeType,
//     );
//   }

//   static String _guessMimeType(String filename) {
//     final lower = filename.toLowerCase();
//     if (lower.endsWith(".png")) return "image/png";
//     if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
//       return "image/jpeg";
//     }
//     if (lower.endsWith(".webp")) return "image/webp";
//     if (lower.endsWith(".pdf")) return "application/pdf";
//     return "application/octet-stream";
//   }
// }




// lib/services/download_service.dart
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:crypto/crypto.dart' as crypto;
// import 'package:http/http.dart' as http;

// import '../state/secure_state.dart';

// class DecryptedFileResult {
//   final Uint8List bytes;
//   final String filename;
//   final String mimeType;

//   DecryptedFileResult({
//     required this.bytes,
//     required this.filename,
//     required this.mimeType,
//   });
// }

// class DownloadService {
//   static String get _baseUrl => SecureState.serverUrl;
//   static Map<String, String> _authHeaders() => SecureState.authHeader();
//   static Uri _url(String path) => Uri.parse("$_baseUrl$path");

//   // TEMP – same fake key as upload (MVP)
//   static Uint8List _fakeKey() => Uint8List(32);
//   static final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

//   static String _sha256Hex(Uint8List data) {
//     final digest = crypto.sha256.convert(data);
//     return digest.toString();
//   }

//   static Future<DecryptedFileResult?> downloadAndDecrypt({
//     required String uploadId,
//     required String filename,
//   }) async {
//     // 1) Fetch manifest
//     final manifestRes = await http.get(
//       _url("/media/uploads/$uploadId/manifest.json"),
//       headers: _authHeaders(),
//     );
//     if (manifestRes.statusCode != 200) {
//       print("❌ manifest fetch failed: ${manifestRes.statusCode}");
//       return null;
//     }

//     final manifest = jsonDecode(utf8.decode(manifestRes.bodyBytes))
//         as Map<String, dynamic>;

//     final chunksRaw = manifest["chunks"] as List<dynamic>?;

//     if (chunksRaw == null || chunksRaw.isEmpty) {
//       print("❌ manifest has no chunks");
//       return null;
//     }

//     final chunksMeta = chunksRaw
//         .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
//         .toList();

//     // normalize & sort by index
//     chunksMeta.forEach((m) => m["index"] = (m["index"] as num).toInt());
//     chunksMeta.sort((a, b) => (a["index"] as int).compareTo(b["index"] as int));

//     // 2) Fetch final.bin (concatenated ciphertext)
//     final finalRes = await http.get(
//       _url("/media/uploads/$uploadId/final.bin"),
//       headers: _authHeaders(),
//     );
//     if (finalRes.statusCode != 200) {
//       print("❌ final.bin fetch failed: ${finalRes.statusCode}");
//       return null;
//     }
//     final encryptedBytes = finalRes.bodyBytes;

//     // 3) Verify sizes + per-chunk SHA before decrypting
//     final secretKey = SecretKey(_fakeKey());
//     final plainOut = BytesBuilder();
//     int offset = 0;

//     for (final meta in chunksMeta) {
//       final int size = (meta["ciphertext_size"] as num).toInt();
//       final String? expectedSha =
//           (meta["ciphertext_sha256"] ?? meta["ciphertext_sha"]) as String?;

//       if (offset + size > encryptedBytes.length) {
//         throw Exception(
//             "Chunk ${meta["index"]} exceeds final.bin length (offset=$offset, size=$size)");
//       }

//       final chunkCipher =
//           encryptedBytes.sublist(offset, offset + size);
//       offset += size;

//       // Integrity check
//       if (expectedSha != null && expectedSha.isNotEmpty) {
//         final actualSha = _sha256Hex(chunkCipher);
//         if (actualSha.toLowerCase() != expectedSha.toLowerCase()) {
//           throw Exception(
//               "ciphertext_sha256 mismatch at index ${meta["index"]}");
//         }
//       }

//       final nonceB64 = meta["nonce_b64"] as String;
//       final macB64 = meta["mac_b64"] as String?;

//       final nonce = base64Decode(nonceB64);
//       final macBytes = macB64 != null ? base64Decode(macB64) : Uint8List(16);

//       final secretBox = SecretBox(
//         chunkCipher,
//         nonce: nonce,
//         mac: Mac(macBytes),
//       );

//       final chunkPlain = await _algorithm.decrypt(
//         secretBox,
//         secretKey: secretKey,
//       );

//       plainOut.add(chunkPlain);
//     }

//     final decrypted = plainOut.toBytes();
//     final mimeType = _guessMimeType(filename);

//     return DecryptedFileResult(
//       bytes: decrypted,
//       filename: filename,
//       mimeType: mimeType,
//     );
//   }

//   static String _guessMimeType(String filename) {
//     final lower = filename.toLowerCase();
//     if (lower.endsWith(".png")) return "image/png";
//     if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
//       return "image/jpeg";
//     }
//     if (lower.endsWith(".webp")) return "image/webp";
//     if (lower.endsWith(".pdf")) return "application/pdf";
//     return "application/octet-stream";
//   }
// }
// ======================================================================================================
// lib/services/download_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/secure_state.dart';

class DownloadService {
  static String get _baseUrl => SecureState.serverUrl;

  static Uri _url(String path) => Uri.parse("$_baseUrl$path");

  static Map<String, String> _headers() =>
      SecureState.authHeader();

  // 1️⃣ Fetch manifest
  static Future<Map<String, dynamic>> fetchManifest(
    String fileId,
  ) async {
    final res = await http.get(
      _url("/upload/file/$fileId/manifest/"),
      headers: _headers(),
    );

    debugPrint("Manifest Status =${res.statusCode}");
    debugPrint("manifest body ${res.body}");
    if (res.statusCode != 200) {
      throw Exception("Failed to fetch manifest");
    }

    return jsonDecode(res.body);
  }

  // 2️⃣ Fetch encrypted file bytes
  static Future<Uint8List> fetchEncryptedData(
    String fileId,
  ) async {
    final res = await http.get(
      _url("/upload/file/$fileId/data/"),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch encrypted file");
    }

    return res.bodyBytes;
  }
}

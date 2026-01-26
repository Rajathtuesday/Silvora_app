// // lib/crypto/file_stream_decryptor.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:path_provider/path_provider.dart';

// import '../../crypto/hkdf.dart';

// class FileStreamDecryptor {
//   final Uint8List masterKey;
//   final Map<String, dynamic> manifest;

//   final Xchacha20 _algo = Xchacha20.poly1305Aead();

//   FileStreamDecryptor({
//     required this.masterKey,
//     required this.manifest,
//   });

//   Future<File> decryptToTempFile(Uint8List encryptedData) async {
//     final tmpDir = await getTemporaryDirectory();
//     final outFile = File("${tmpDir.path}/${manifest['filename']}");

//     final raf = outFile.openSync(mode: FileMode.write);

//     try {
//       final chunks =
//           List<Map<String, dynamic>>.from(manifest['chunks']);

//       for (final chunk in chunks) {
//         final int index = chunk['index'];
//         final int offset = chunk['offset'];
//         final int size = chunk['ciphertext_size'];

//         // ✅ CORRECT: base64 → bytes (24 bytes)
//         final Uint8List nonce =
//             base64Url.decode(chunk['nonce_b64']);



//         // ✅ CORRECT: base64 → bytes (16 bytes)
//         final Uint8List mac =
//             base64Url.decode(chunk['mac_b64']);
//         // 🔎 SAFETY CHECK (add this temporarily)
//         if (nonce.length != 24) {
//           throw Exception(
//             "Invalid nonce length: ${nonce.length}",
//           );
//         }
//         if (mac.length != 16) {
//           throw Exception(
//             "Invalid MAC length: ${mac.length}",
//           );
//         }

//         final cipherSlice = encryptedData.sublist(
//           offset,
//           offset + size,
//         );

//         final derivedKey = await hkdfSha256(
//           ikm: masterKey,
//           info: utf8.encode("silvora-chunk-$index"),
//         );

//         final box = SecretBox(
//           cipherSlice,
//           nonce: nonce,      // 🔥 ONLY nonce
//           mac: Mac(mac),     // 🔥 ONLY mac
//         );

//         final plain = await _algo.decrypt(
//           box,
//           secretKey: SecretKey(derivedKey),
          
//         );

//         raf.writeFromSync(plain);
//       }
//     } finally {
//       raf.closeSync();
//     }

//     return outFile;
//   }
// }
// ===========================================================================
// lib/crypto/file_stream_decryptor.dart
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:path_provider/path_provider.dart';

// import 'hkdf.dart';

/// ============================================================
/// FileStreamDecryptor
/// ============================================================
///
/// - ZERO-KNOWLEDGE SAFE
/// - Server never decrypts anything
/// - Client decrypts chunk-by-chunk
/// - Supports:
///   ✅ Full download (decryptToTempFile)
///   ✅ Streaming preview (decryptStream)
///
/// Manifest-driven:
/// - offsets
/// - ciphertext_size
/// - nonce
/// - mac
///
/// ============================================================
// class FileStreamDecryptor {
//   final Uint8List masterKey;
//   final Map<String, dynamic> manifest;

//   final Xchacha20 _algo = Xchacha20.poly1305Aead();

//   FileStreamDecryptor({
//     required this.masterKey,
//     required this.manifest,
//   });

  // ============================================================
  // 1️⃣ FULL FILE DECRYPT (DOWNLOAD PATH)
  // ============================================================
  //
  // - Requires full encrypted payload
  // - Writes decrypted file to temp
  // - Used by "Download"
  //
  // ============================================================
  // Future<File> decryptToTempFile(Uint8List encryptedData) async {
  //   final tmpDir = await getTemporaryDirectory();
  //   final outFile = File("${tmpDir.path}/${manifest['filename']}");

  //   final raf = outFile.openSync(mode: FileMode.write);

  //   try {
  //     final chunks =
  //         List<Map<String, dynamic>>.from(manifest['chunks']);

  //     for (final chunk in chunks) {
  //       final int index = chunk['index'];
  //       final int offset = chunk['offset'];
  //       final int size = chunk['ciphertext_size'];

  //       final Uint8List nonce =
  //           base64Url.decode(chunk['nonce_b64']);
  //       final Uint8List mac =
  //           base64Url.decode(chunk['mac_b64']);

  //       // Safety checks (keep)
  //       if (nonce.length != 24) {
  //         throw StateError("Invalid nonce length: ${nonce.length}");
  //       }
  //       if (mac.length != 16) {
  //         throw StateError("Invalid MAC length: ${mac.length}");
  //       }

  //       final cipherSlice =
  //           encryptedData.sublist(offset, offset + size);

  //       final derivedKey = await hkdfSha256(
  //         ikm: masterKey,
  //         info: utf8.encode("silvora-chunk-$index"),
  //       );

  //       final box = SecretBox(
  //         cipherSlice,
  //         nonce: nonce,
  //         mac: Mac(mac),
  //       );

  //       final plain = await _algo.decrypt(
  //         box,
  //         secretKey: SecretKey(derivedKey),
  //       );

  //       raf.writeFromSync(plain);
  //     }
  //   } finally {
  //     raf.closeSync();
  //   }

  //   return outFile;
  // }

  // ============================================================
  // 2️⃣ STREAMING DECRYPT (PREVIEW PATH)
  // ============================================================
  //
  // - Does NOT require full encrypted file
  // - Decrypts chunk-by-chunk
  // - Emits plaintext as stream
  // - Can stop early (preview limit)
  //
  // ============================================================
  // Stream<Uint8List> decryptStream(
  //   Stream<Uint8List> encryptedStream, {
  //   int? stopAfterChunks,
  // }) async* {
  //   final chunks =
  //       List<Map<String, dynamic>>.from(manifest['chunks']);

  //   final buffer = BytesBuilder(copy: false);
  //   int chunkCursor = 0;

  //   await for (final data in encryptedStream) {
  //     buffer.add(data);

  //     while (chunkCursor < chunks.length) {
  //       final chunk = chunks[chunkCursor];
  //       final int size = chunk['ciphertext_size'];

  //       if (buffer.length < size) {
  //         break; // wait for more data
  //       }

  //       // Extract exact ciphertext slice
  //       final Uint8List all = buffer.takeBytes();
  //       final Uint8List cipherChunk = all.sublist(0, size);

  //       // Keep remainder in buffer
  //       if (all.length > size) {
  //         buffer.add(all.sublist(size));
  //       }

  //       final int index = chunk['index'];

  //       final Uint8List nonce =
  //           base64Url.decode(chunk['nonce_b64']);
  //       final Uint8List mac =
  //           base64Url.decode(chunk['mac_b64']);

  //       final derivedKey = await hkdfSha256(
  //         ikm: masterKey,
  //         info: utf8.encode("silvora-chunk-$index"),
  //       );

  //       final box = SecretBox(
  //         cipherChunk,
  //         nonce: nonce,
  //         mac: Mac(mac),
  //       );

  //       final Uint8List plain = Uint8List.fromList(
  //         await _algo.decrypt(
  //           box,
  //           secretKey: SecretKey(derivedKey),
  //         ),
  //       );

  //       yield plain;

  //       chunkCursor++;

  //       // Preview stop condition
  //       if (stopAfterChunks != null &&
  //           chunkCursor >= stopAfterChunks) {
  //         return;
  //       }
  //     }
  //   }
  // }

//   Stream<Uint8List> decryptStream(
//   Stream<Uint8List> encryptedStream, {
//   int? stopAfterChunks,
// }) async* {
//   final chunks =
//       List<Map<String, dynamic>>.from(manifest['chunks']);

//   int processed = 0;
//   final buffer = BytesBuilder();

//   await for (final encrypted in encryptedStream) {
//     for (final chunk in chunks) {
//       if (stopAfterChunks != null &&
//           processed >= stopAfterChunks) {
//         return;
//       }

//       final int index = chunk['index'];
//       final int offset = chunk['offset'];
//       final int size = chunk['ciphertext_size'];

//       final cipherSlice =
//           encrypted.sublist(offset, offset + size);

//       final nonce = base64Url.decode(chunk['nonce_b64']);
//       final mac = base64Url.decode(chunk['mac_b64']);

//       final derivedKey = await hkdfSha256(
//         ikm: masterKey,
//         info: utf8.encode("silvora-chunk-$index"),
//       );

//       final box = SecretBox(
//         cipherSlice,
//         nonce: nonce,
//         mac: Mac(mac),
//       );

//       final plain = await _algo.decrypt(
//         box,
//         secretKey: SecretKey(derivedKey),
//       );

//       processed++;
//       yield Uint8List.fromList(plain);
//     }
//   }
// }

// }


// =====================================================================================================
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'hkdf.dart';

/// ============================================================
/// FileStreamDecryptor
/// ============================================================
/// Decrypts an encrypted file using a server-blind manifest.
/// Assumes:
/// - XChaCha20-Poly1305
/// - HKDF-SHA256 per chunk
/// - Manifest-driven offsets (no assumptions)
///
/// ⚠️ IMPORTANT:
/// - DOES NOT assume optional fields
/// - ONLY trusts fields that exist in your manifest
/// ============================================================
class FileStreamDecryptor {
  final Uint8List masterKey;
  final Map<String, dynamic> manifest;

  static final _cipher = Xchacha20.poly1305Aead();

  FileStreamDecryptor({
    required this.masterKey,
    required this.manifest,
  });

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Decrypts encrypted bytes into a temporary file
  Future<File> decryptToTempFile(Uint8List encryptedBytes) async {
    _validateManifest();

    final List chunks = manifest['chunks'] as List;
    final int fileSize = manifest['file_size'] as int;

    debugPrint("🔓 Full decrypt (reference)");
    debugPrint("📄 chunks    = ${chunks.length}");
    debugPrint("📄 file_size = $fileSize");

    // Allocate output buffer
    final Uint8List output = Uint8List(fileSize);

    for (final chunk in chunks) {
      await _decryptChunk(
        encryptedBytes: encryptedBytes,
        output: output,
        chunk: chunk as Map<String, dynamic>,
      );
    }

    return _writeTempFile(output);
  }

  // ============================================================
  // INTERNALS
  // ============================================================

  void _validateManifest() {
    if (manifest['version'] != 1) {
      throw UnsupportedError(
        "Unsupported manifest version: ${manifest['version']}",
      );
    }

    if (manifest['chunks'] == null ||
        manifest['chunks'] is! List ||
        (manifest['chunks'] as List).isEmpty) {
      throw StateError("Manifest contains no chunks");
    }

    if (manifest['file_size'] == null) {
      throw StateError("Manifest missing file_size");
    }
  }

  Future<void> _decryptChunk({
    required Uint8List encryptedBytes,
    required Uint8List output,
    required Map<String, dynamic> chunk,
  }) async {
    // ─────────────────────────────
    // Required fields (STRICT)
    // ─────────────────────────────
    final int index = chunk['index'] as int;
    final int offset = chunk['offset'] as int;
    final int size = chunk['ciphertext_size'] as int;

    final String nonceB64 = chunk['nonce'] as String;
    final String macB64 = chunk['mac'] as String;

    // ─────────────────────────────
    // Decode crypto fields
    // ─────────────────────────────
    final Uint8List nonce = base64Decode(nonceB64);
    final Mac mac = Mac(base64Decode(macB64));

    // ─────────────────────────────
    // Slice encrypted data
    // ─────────────────────────────
    final Uint8List cipherText = encryptedBytes.sublist(
      offset,
      offset + size,
    );

    // ─────────────────────────────
    // Derive per-chunk key
    // ─────────────────────────────
    final Uint8List chunkKey = await hkdfSha256(
      ikm: masterKey,
      info: utf8.encode("silvora-chunk-$index"),
    );

    // ─────────────────────────────
    // Decrypt
    // ─────────────────────────────
    final SecretBox box = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final Uint8List plain = Uint8List.fromList(
      await _cipher.decrypt(
        box,
        secretKey: SecretKey(chunkKey),
      ),
    );

    // ─────────────────────────────
    // Write to output buffer
    // ─────────────────────────────
    output.setRange(offset, offset + plain.length, plain);
  }

  // ============================================================
  // FILE IO
  // ============================================================

  Future<File> _writeTempFile(Uint8List data) async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      "${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}",
    );

    await file.writeAsBytes(data, flush: true);
    debugPrint("📁 Temp file written: ${file.path}");

    return file;
  }
}

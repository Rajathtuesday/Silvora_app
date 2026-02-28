

// =====================================================================================================
// lib/crypto/file_stream_decryptor.dart
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

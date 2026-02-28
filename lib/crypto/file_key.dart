// ============================================================================
// File Key Derivation
//
// Derives a per-file encryption key from the master key.
//
// SECURITY CONTRACT:
// - Deterministic
// - Domain-separated
// - Canonical encoding
// - One key per file
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'hkdf.dart';

const int _fileKeyLength = 32;
const String _fileKeyContext = "silvora:file-key:v1";

Future<Uint8List> deriveFileKey({
  required Uint8List masterKey,
  required String fileId,
}) async {
  if (fileId.isEmpty) {
    throw ArgumentError("fileId must not be empty");
  }

  final Uint8List info = Uint8List.fromList(
    utf8.encode("$_fileKeyContext:$fileId"),
  );

  final Uint8List fileKey = await hkdfSha256(
    ikm: masterKey,
    info: info,
    length: _fileKeyLength,
  );

  if (fileKey.length != _fileKeyLength) {
    throw StateError("Invalid file key length");
  }

  return fileKey;
}



// ========================================================================
// lib/crypto/file_key.dart
import 'dart:typed_data';
import 'hkdf.dart';

Future<Uint8List> deriveFileKey({
  required Uint8List masterKey,
  required String fileId,
}) async {
  return hkdfSha256(
    ikm: masterKey,
    info: "silvora-file-$fileId".codeUnits,
  );
}


// ============================================================================
// lib/crypto/file_decryptor.dart
// lib/crypto/file_decryptor.dart
import 'dart:convert';
import 'dart:typed_data';

import 'hkdf.dart';
import 'xchacha.dart';

class FileDecryptor {
  final Uint8List masterKey;
  final Map<String, dynamic> manifest;

  FileDecryptor({
    required this.masterKey,
    required this.manifest,
  });

  final _crypto = XChaCha();

  Future<Uint8List> decrypt(Uint8List encrypted) async {
    final chunks =
        List<Map<String, dynamic>>.from(manifest["chunks"]);

    final out = BytesBuilder();

    for (final c in chunks) {
      final int offset = c["offset"];
      final int size = c["ciphertext_size"];

      final cipher =
          encrypted.sublist(offset, offset + size);

      // ✅ FIX: await HKDF
      final Uint8List key = await hkdfSha256(
        ikm: masterKey,
        info: utf8.encode("silvora-chunk-${c["index"]}"),
      );

      final plain = await _crypto.decrypt(
        ciphertext: cipher,
        key: key,
        nonce: base64Decode(c["nonce_b64"]),
        mac: base64Decode(c["mac_b64"]),
      );

      out.add(plain);
    }

    return out.toBytes();
  }
}

// import 'dart:convert';
// import 'dart:typed_data';

// import 'xchacha.dart';
// import 'hkdf.dart';

// class FileDecryptor {
//   final XChaCha _crypto = XChaCha();

//   /// Decrypt entire file using manifest + encrypted blob
//   Future<Uint8List> decryptFile({
//     required Map<String, dynamic> manifest,
//     required Uint8List encryptedData,
//     required Uint8List masterKey,
//   }) async {
//     final chunks =
//         List<Map<String, dynamic>>.from(manifest["chunks"]);

//     final out = BytesBuilder();

//     for (final c in chunks) {
//       final int index = c["index"];
//       final int offset = c["offset"];
//       final int size = c["ciphertext_size"];

//       final nonce = base64Decode(c["nonce_b64"]);
//       final mac = base64Decode(c["mac_b64"]);
//       final ciphertext =
//           encryptedData.sublist(offset, offset + size);

//       // 🔑 Per-chunk derived key
//       final key = await hkdfSha256(
//         ikm: masterKey,
//         info: utf8.encode("silvora-chunk-$index"),
//       );

//       final plain = await _crypto.decrypt(
//         ciphertext: ciphertext,
//         nonce: nonce,
//         mac: mac,
//         key: key,
//       );

//       out.add(plain);
//     }

//     return out.toBytes();
//   }
// }
// ========================================================================
// lib/crypto/file_decryptor.dart
// lib/crypto/chunk_crypto.dart
import 'dart:typed_data';
import 'hkdf.dart';

Future<Uint8List> deriveChunkKey({
  required Uint8List fileKey,
  required int chunkIndex,
}) async {
  return hkdfSha256(
    ikm: fileKey,
    info: "silvora-chunk-$chunkIndex".codeUnits,
  );
}

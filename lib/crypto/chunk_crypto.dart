// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// final _algo = Xchacha20.poly1305Aead();

// Future<Uint8List> decryptChunk({
//   required Uint8List key,
//   required Uint8List cipher,
//   required Uint8List nonce,
//   required Uint8List mac,
// }) async {
//   final box = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
//   return Uint8List.fromList(
//     await _algo.decrypt(box, secretKey: SecretKey(key)),
//   );
// }
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

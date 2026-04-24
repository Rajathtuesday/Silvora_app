// import 'dart:convert';
// import 'dart:typed_data';

// import '../../crypto/file_key.dart';
// import '../../crypto/chunk_crypto.dart';
// import '../../state/secure_state.dart';
// import '../../services/api_services.dart';

// class PreviewService {
//   static Future<Uint8List> loadAndDecrypt(String fileId) async {
//     final manifest = await ApiService.fetchManifest(fileId);
//     final encrypted = await ApiService.fetchEncryptedData(fileId);

//     final masterKey = SecureState.requireMasterKey();
//     final fileKey = await deriveFileKey(
//       masterKey: masterKey,
//       fileId: fileId,
//     );

//     final out = BytesBuilder();

//     for (final c in manifest.chunks) {
//       final cipher = encrypted.sublist(
//         c.offset,
//         c.offset + c.ciphertextSize,
//       );

//       final plain = await decryptChunk(
//         key: fileKey,
//         cipher: cipher,
//         nonce: base64Decode(c.nonceB64),
//         mac: base64Decode(c.macB64),
//       );

//       out.add(plain);
//     }

//     return out.toBytes();
//   }
// }

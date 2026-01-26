// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// Uint8List decryptMasterKey({
//   required Uint8List encrypted,
//   required Uint8List key,
// }) {
//   final algo = Xchacha20.poly1305Aead();
//   final nonce = encrypted.sublist(0, 24);
//   final mac = encrypted.sublist(encrypted.length - 16);
//   final cipher = encrypted.sublist(24, encrypted.length - 16);

//   final box = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
//   return Uint8List.fromList(
//     algo.decryptSync(box, secretKey: SecretKey(key)),
//   );
// }
// ========================================================================
// lib/crypto/hkdf.dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

Future<Uint8List> hkdfSha256({
  required Uint8List ikm,
  required List<int> info,
}) async {
  final hkdf = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  );

  final key = await hkdf.deriveKey(
    secretKey: SecretKey(ikm),
    info: info,
  );

  return Uint8List.fromList(await key.extractBytes());
}

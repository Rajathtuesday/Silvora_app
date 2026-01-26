// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// Future<Uint8List> hkdfSha256({
//   required List<int> ikm,
//   required List<int> info,
//   int length = 32,
// }) async {
//   final hkdf = Hkdf(
//     hmac: Hmac.sha256(),
//     outputLength: length,
//   );

//   final key = await hkdf.deriveKey(
//     secretKey: SecretKey(ikm),
//     info: info,
//     nonce: <int>[],
//   );

//   return Uint8List.fromList(await key.extractBytes());
// }
// ======================================================================

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

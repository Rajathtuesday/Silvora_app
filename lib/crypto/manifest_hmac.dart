import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

Future<Uint8List> computeManifestHmac({
  required Uint8List fileKey,
  required Uint8List manifestBytes,
}) async {
  final hmac = Hmac.sha256();
  final mac = await hmac.calculateMac(
    manifestBytes,
    secretKey: SecretKey(fileKey),
  );
  return Uint8List.fromList(mac.bytes);
}

bool constantTimeEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
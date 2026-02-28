// ============================================================================
// HKDF-SHA256
//
// Deterministic key derivation used for:
// - file keys
// - chunk keys
//
// SECURITY CONTRACT:
// - Output length is honored
// - Canonical byte inputs only
// - Stateless
// ============================================================================

import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

Future<Uint8List> hkdfSha256({
  required Uint8List ikm,
  required Uint8List info,
  required int length,
}) async {
  if (ikm.isEmpty) {
    throw ArgumentError("IKM must not be empty");
  }

  if (info.isEmpty) {
    throw ArgumentError("HKDF info must not be empty");
  }

  if (length <= 0) {
    throw ArgumentError("Invalid HKDF output length");
  }

  final Hkdf hkdf = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: length,
  );

  final SecretKey key = await hkdf.deriveKey(
    secretKey: SecretKey(ikm),
    info: info,
  );

  final Uint8List derived =
      Uint8List.fromList(await key.extractBytes());

  if (derived.length != length) {
    throw StateError("HKDF output length mismatch");
  }

  return derived;
}

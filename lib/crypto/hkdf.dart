// lib/crypto/hkdf.dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// HKDF (RFC 5869) split into its two phases so an Extract result can be
/// computed once and reused across many Expand calls.
///
/// Why this matters: Extract only depends on the input key material (here,
/// the vault's master key, which never changes for a whole unlocked
/// session) -- it does NOT depend on the `info` label that makes each
/// derived key unique. The combined hkdfSha256() below redoes Extract on
/// every single call even though, for any given master key, Extract's
/// result is always identical. Decrypting a vault with 1,000 files means
/// 1,000 redundant Extract operations with the exact same input. Caching
/// it once (see SecureState.getMasterKeyPrk) and calling hkdfExpand
/// directly removes that repetition.
///
/// hkdfExtract(ikm) + hkdfExpand(prk, info) MUST produce byte-for-byte the
/// same output as hkdfSha256(ikm, info) below for the same inputs -- this
/// is verified by a dedicated test, since any drift here would make every
/// already-encrypted file undecryptable, the same class of bug as the
/// password-encoding fix earlier.
final _hmac = Hmac.sha256();

/// Extract phase. No salt is passed (matches every existing call site,
/// none of which ever provided one) -- HMAC with an empty key is, after
/// HMAC's own internal zero-padding to block size, equivalent to RFC
/// 5869's "HashLen zero bytes" default for a missing salt.
Future<SecretKey> hkdfExtract(Uint8List ikm) async {
  final mac = await _hmac.calculateMac(
    ikm,
    secretKey: SecretKey(const <int>[]),
  );
  return SecretKey(mac.bytes);
}

/// Expand phase. Cheap -- safe to call as many times as needed with a
/// cached PRK from hkdfExtract.
Future<Uint8List> hkdfExpand({
  required SecretKey prk,
  required List<int> info,
  int outputLength = 32,
}) async {
  var bytes = const <int>[];
  final hashLength = _hmac.hashAlgorithm.hashLengthInBytes;
  final n = outputLength ~/ hashLength;
  final result = Uint8List(outputLength);
  for (var i = 0; i <= n; i++) {
    final sink = await _hmac.newMacSink(secretKey: prk);
    sink.add(bytes);
    if (info.isNotEmpty) sink.add(info);
    sink.add([0xFF & (1 + i)]);
    sink.close();
    final mac = await sink.mac();
    bytes = mac.bytes;
    final offset = i * hashLength;
    if (offset + bytes.length <= result.length) {
      result.setAll(offset, bytes);
    } else {
      result.setAll(offset, bytes.take(result.length - offset));
    }
  }
  return result;
}

/// Combined Extract+Expand -- unchanged behavior/signature from before
/// this split existed. Still the right choice for one-off derivations
/// (e.g. the recovery phrase's auth key, derived once ever) where there's
/// no repeated Extract to avoid and caching a PRK isn't worth the memory
/// lifecycle complexity.
Future<Uint8List> hkdfSha256({
  required Uint8List ikm,
  required List<int> info,
}) async {
  final prk = await hkdfExtract(ikm);
  return hkdfExpand(prk: prk, info: info);
}

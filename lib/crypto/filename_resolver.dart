// lib/crypto/filename_resolver.dart

// Resolves and verifies an encrypted filename.
//
// SECURITY GUARANTEES:
// - Requires unlocked vault
// - Deterministic per-file key
// - Authenticated decryption
// - Semantic integrity (hash verification)
// - Cache only verified plaintext
//
// FAILURE MODEL:
// - Throws on corruption or tampering
import 'dart:typed_data';

import '../state/secure_state.dart';
import '../state/filename_cache.dart';
import 'filename_crypto.dart';
import 'file_key.dart';

class FilenameResolver {
  static Future<String> resolve({
    required String fileId,
    required String ciphertextHex,
    required String nonceHex,
    required String macHex,
  }) async {
    final cached = FilenameCache.get(fileId);
    if (cached != null) return cached;

    final Uint8List masterKey =
        SecureState.requireMasterKey();

    final Uint8List fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: fileId,
    );

    final String name = await FilenameCrypto.decrypt(
      ciphertextHex: ciphertextHex,
      nonceHex: nonceHex,
      macHex: macHex,
      fileKey: fileKey,
    );

    FilenameCache.put(fileId, name);
    return name;
  }
}
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../state/secure_state.dart';
import '../crypto/hkdf.dart';
import '../crypto/xchacha.dart';
import 'auth_client.dart';
import 'retry.dart';

/// The decrypted, client-signed integrity manifest for one file.
///
/// AEAD alone proves each *chunk* decrypts, but not that the chunks are in the
/// right order, all present, and unmodified as a *set*. This manifest binds the
/// SHA-256 of every plaintext chunk + the total count under a key only the
/// client holds, so download can detect reordering, truncation, and tamper.
class IntegrityManifest {
  final int totalChunks;
  final int totalPlainSize;

  /// chunk index -> SHA-256 (hex) of that chunk's *plaintext*.
  final Map<int, String> hashes;

  IntegrityManifest({
    required this.totalChunks,
    required this.totalPlainSize,
    required this.hashes,
  });
}

class IntegrityService {
  static String get _baseUrl => SecureState.serverUrl;
  static Uri _url(String path) => Uri.parse("$_baseUrl$path");

  /// Per-file integrity key — domain-separated from the file/filename keys so a
  /// leak of one never exposes another. The server never sees this key.
  static Future<Uint8List> _integrityKey(String fileId) {
    return hkdfSha256(
      ikm: SecureState.masterKey,
      info: utf8.encode("silvora-integrity-$fileId"),
    );
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// SHA-256 (hex) of a plaintext chunk. Shared by upload (manifest build) and
  /// download (verification) so both sides hash identically.
  static Future<String> hashChunk(List<int> plaintext) async {
    final digest = await Sha256().hash(plaintext);
    return _hex(digest.bytes);
  }

  /// Read the local file, hash each plaintext chunk, then encrypt and upload the
  /// integrity manifest. Hashing reads from the source file (not the uploaded
  /// ciphertext), so it is resume-safe: it works even if some chunks were sent
  /// in an earlier session.
  static Future<bool> buildAndUpload({
    required String fileId,
    required File file,
    required int chunkSize,
  }) async {
    final fileLen = await file.length();
    final totalChunks = fileLen == 0 ? 0 : (fileLen / chunkSize).ceil();

    final chunkHashes = <Map<String, dynamic>>[];
    final raf = await file.open();
    try {
      for (int i = 0; i < totalChunks; i++) {
        await raf.setPosition(i * chunkSize);
        final len = ((i + 1) * chunkSize > fileLen) ? fileLen - i * chunkSize : chunkSize;
        final plain = await raf.read(len);
        chunkHashes.add({"i": i, "h": await hashChunk(plain)});
      }
    } finally {
      await raf.close();
    }

    final manifest = {
      "v": 1,
      "file_id": fileId,
      "total_chunks": totalChunks,
      "total_plain_size": fileLen,
      "chunks": chunkHashes,
    };

    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
    final key = await _integrityKey(fileId);
    final nonce = await XChaCha.randomNonce();
    final box = await XChaCha.encrypt(plaintext: plaintext, key: key, nonce: nonce);

    // Self-describing envelope, same shape as the chunk envelope.
    final envelope = jsonEncode({
      "n": base64Encode(nonce),
      "c": base64Encode(box.cipherText),
      "m": base64Encode(box.mac.bytes),
    });

    final body = utf8.encode(envelope);
    try {
      return await retry<bool>(
        () async {
          final res = await AuthClient.post(
            _url("/file/$fileId/integrity/"),
            headers: {"Content-Type": "application/octet-stream"},
            body: body,
          );
          return res.statusCode == 200;
        },
        retryIf: (ok) => !ok,
      );
    } catch (_) {
      return false;
    }
  }

  /// Fetch + decrypt the integrity manifest. Returns null when the file predates
  /// the integrity layer (server 404), so old files still download.
  static Future<IntegrityManifest?> fetch(String fileId) async {
    final res = await AuthClient.get(_url("/download/file/$fileId/integrity/"));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception("Integrity manifest fetch failed (HTTP ${res.statusCode}).");
    }

    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw Exception("Integrity manifest envelope is corrupt.");
    }

    final nonce = base64Decode(envelope["n"] as String);
    final cipher = base64Decode(envelope["c"] as String);
    final mac = base64Decode(envelope["m"] as String);
    final key = await _integrityKey(fileId);

    final Uint8List plain;
    try {
      plain = await XChaCha.decrypt(
        ciphertext: cipher, key: key, nonce: nonce, mac: mac,
      );
    } catch (_) {
      // Wrong key or the manifest itself was tampered with — fail closed.
      throw Exception("Integrity manifest failed authentication (tampered or wrong key).");
    }

    final m = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    final rawChunks = (m["chunks"] as List).cast<dynamic>();
    final hashes = <int, String>{};
    for (final c in rawChunks) {
      final cm = Map<String, dynamic>.from(c as Map);
      hashes[(cm["i"] as num).toInt()] = cm["h"] as String;
    }

    return IntegrityManifest(
      totalChunks: (m["total_chunks"] as num).toInt(),
      totalPlainSize: (m["total_plain_size"] as num).toInt(),
      hashes: hashes,
    );
  }
}

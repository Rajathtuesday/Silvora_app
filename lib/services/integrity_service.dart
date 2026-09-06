import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../state/secure_state.dart';
import '../crypto/hkdf.dart';
import '../crypto/xchacha.dart';
import 'auth_client.dart';
import 'integrity_version_store.dart';
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
  final int version;

  /// chunk index -> SHA-256 (hex) of that chunk's *plaintext*.
  final Map<int, String> hashes;

  IntegrityManifest({
    required this.totalChunks,
    required this.totalPlainSize,
    required this.hashes,
    required this.version,
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
  ///
  /// [version] is the rollback-protection generation number signed into the
  /// manifest (see IntegrityVersionStore) -- defaults to 1 since this app has
  /// no "replace an existing file's content" flow today (every upload gets a
  /// fresh file_id), so every file's first and only commit is generation 1.
  /// The parameter exists so a future re-upload-in-place feature, or a
  /// server-assigned counter, has somewhere to plug in without reshaping this
  /// method's signature.
  static Future<bool> buildAndUpload({
    required String fileId,
    required File file,
    required int chunkSize,
    int version = 1,
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
      "version": version,
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
      final ok = await retry<bool>(
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
      if (ok) {
        // Establish this device's baseline immediately at upload time, not
        // only on first download -- otherwise a rollback delivered before
        // this file is ever downloaded would have nothing to be compared
        // against.
        await IntegrityVersionStore.recordSeen(fileId, version);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Fetch + decrypt the integrity manifest. Fails closed on anything but a
  /// real manifest -- including 404. upload_service.py's commit() has
  /// required every file to have a manifest since 2026-08-06, so a missing
  /// one is never legitimate; treating 404 as "legacy, skip" would let a
  /// malicious/compromised server silently defeat verification for ANY
  /// file just by lying about the status code, since the server fully
  /// controls which one it sends.
  static Future<IntegrityManifest> fetch(String fileId) async {
    final res = await AuthClient.get(_url("/download/file/$fileId/integrity/"));
    if (res.statusCode == 409) {
      // Server proved (durably, at commit time) this file HAD a manifest.
      // It's missing now -- deleted or tampered with after commit.
      throw Exception(
        "Integrity check failed: this file's manifest was established at "
        "upload and is missing now. Refusing to decrypt unverified.",
      );
    }
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

    // Missing "version" means this manifest predates this fix (2026-09-06) --
    // treat it as generation 1, the lowest possible value, so an old file
    // uploaded before this change doesn't spuriously fail to download.
    final version = (m["version"] as num?)?.toInt() ?? 1;

    // 🔐 ROLLBACK/REPLAY CHECK: an old-but-validly-signed manifest is still a
    // manifest this exact key can decrypt and this exact key signed -- AEAD
    // authentication alone can never catch a compromised/malicious server
    // serving back an earlier, genuinely legitimate-at-the-time bundle for
    // this file instead of the current one. Comparing against the highest
    // version this device has already recorded (upload or a prior download)
    // is what actually catches that. See IntegrityVersionStore for the
    // trust-on-first-use caveat this depends on.
    final lastSeen = await IntegrityVersionStore.getLastSeen(fileId);
    if (lastSeen != null && version < lastSeen) {
      throw Exception(
        "Integrity check failed: this file's manifest version ($version) is "
        "older than the version this device already saw ($lastSeen). "
        "Refusing to decrypt what may be a rolled-back file.",
      );
    }
    await IntegrityVersionStore.recordSeen(fileId, version);

    return IntegrityManifest(
      totalChunks: (m["total_chunks"] as num).toInt(),
      totalPlainSize: (m["total_plain_size"] as num).toInt(),
      hashes: hashes,
      version: version,
    );
  }
}

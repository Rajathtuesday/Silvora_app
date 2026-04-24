import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import '../state/secure_state.dart';
import '../crypto/hkdf.dart';
import '../crypto/file_decryptor.dart';
import 'auth_client.dart';

class DecryptedFileResult {
  final File file;
  final String filename;
  final String mimeType;

  DecryptedFileResult({
    required this.file,
    required this.filename,
    required this.mimeType,
  });
}

class DownloadService {
  static const int _nonceLen = 24; // XChaCha20 nonce is always 24 bytes
  static const int _macLen   = 16; // Poly1305 MAC is always 16 bytes

  static String get _baseUrl => SecureState.serverUrl;
  static Map<String, String> _authHeaders() => SecureState.authHeader();
  static Uri _url(String path) => Uri.parse("$_baseUrl$path");

  static final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

  /// Derive per-file encryption key from master key + fileId
  static Future<SecretKey> _deriveFileKey(String fileId) async {
    final keyBytes = await hkdfSha256(
      ikm:  SecureState.masterKey,
      info: utf8.encode("silvora_file_$fileId"),
    );
    return SecretKey(keyBytes);
  }

  static Future<DecryptedFileResult?> downloadAndDecrypt({
    required String fileId,
    required String filename,
  }) async {
    // ── 1. Fetch manifest ─────────────────────────────────────────
    final http.Response manifestRes;
    try {
      manifestRes = await AuthClient.get(
        _url("/download/file/$fileId/manifest/"),
      ).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception("Network error fetching manifest: $e");
    }

    if (manifestRes.statusCode == 401) throw Exception("Session expired. Please log in again.");
    if (manifestRes.statusCode == 404) throw Exception("File not found on server.");
    if (manifestRes.statusCode != 200) {
      throw Exception("Manifest fetch failed (HTTP ${manifestRes.statusCode}).");
    }

    final Map<String, dynamic> manifest;
    try {
      manifest = jsonDecode(utf8.decode(manifestRes.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Manifest is corrupt or unreadable.");
    }

    final chunksRaw = manifest["chunks"] as List<dynamic>?;
    if (chunksRaw == null || chunksRaw.isEmpty) {
      throw Exception("Manifest has no chunks — file may be corrupt.");
    }

    // ── 2. Parse + sort chunks ────────────────────────────────────
    final chunksMeta = chunksRaw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final m in chunksMeta) {
      // manifest uses key "i" (short for index)
      m["index"] = ((m["index"] ?? m["i"]) as num).toInt();
    }
    chunksMeta.sort((a, b) => (a["index"] as int).compareTo(b["index"] as int));

    // ── 3. Derive file-specific encryption key ────────────────────
    final secretKey = await _deriveFileKey(fileId);
    final file = await FileDecryptor.decryptFile(
      chunksMeta: chunksMeta,
      secretKey: secretKey,
      filename: filename,
      fetchChunk: (index) async {
        final chunkRes = await AuthClient.get(
          _url("/download/file/$fileId/chunk/$index/"),
        ).timeout(const Duration(seconds: 60));
        if (chunkRes.statusCode != 200) {
          throw Exception("Chunk $index download failed (HTTP ${chunkRes.statusCode}).");
        }
        return chunkRes.bodyBytes;
      },
    );

    return DecryptedFileResult(
      file: file,
      filename: filename,
      mimeType: guessMimeType(filename),
    );
  }

  /// Save decrypted file to app documents directory
  static Future<String> saveToDevice(DecryptedFileResult result) async {
    final dir  = await getApplicationDocumentsDirectory();
    final newFile = File("${dir.path}/${result.filename}");
    await result.file.copy(newFile.path);
    return newFile.path;
  }

  static String guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':  return "image/png";
      case 'jpg':
      case 'jpeg': return "image/jpeg";
      case 'webp': return "image/webp";
      case 'gif':  return "image/gif";
      case 'pdf':  return "application/pdf";
      case 'mp4':  return "video/mp4";
      case 'txt':  return "text/plain";
      case 'json': return "application/json";
      default:     return "application/octet-stream";
    }
  }

  static bool isPreviewable(String mimeType) {
    return mimeType.startsWith("image/") || mimeType == "text/plain";
  }
}

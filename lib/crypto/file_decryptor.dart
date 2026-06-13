import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

class FileDecryptor {
  static final Xchacha20 _algorithm = Xchacha20.poly1305Aead();
  static const int _nonceLen = 24;
  static const int _macLen   = 16;

  /// SHA-256 as lowercase hex. Must match IntegrityService.hashChunk byte-for-byte.
  static Future<String> _sha256Hex(List<int> bytes) async {
    final digest = await Sha256().hash(bytes);
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// [expectedHashes] (chunk index -> SHA-256 hex of the plaintext) comes from
  /// the client-signed integrity manifest. When provided, every chunk's
  /// plaintext is hashed after decryption and compared — any reorder,
  /// substitution, or tamper that slipped past per-chunk AEAD is caught here and
  /// the download fails closed. Null = legacy file with no manifest (skip).
  static Future<File> decryptFile({
    required List<Map<String, dynamic>> chunksMeta,
    required SecretKey secretKey,
    required String filename,
    required Future<Uint8List> Function(int index) fetchChunk,
    Map<int, String>? expectedHashes,
  }) async {
    if (expectedHashes != null && expectedHashes.length != chunksMeta.length) {
      // The set of chunks doesn't match what the client signed — truncated or
      // padded by the server. Refuse before writing anything.
      throw Exception(
        "Integrity check failed: expected ${expectedHashes.length} chunks, "
        "server offered ${chunksMeta.length}.",
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$filename");
    final sink = file.openWrite();

    try {
      for (final meta in chunksMeta) {
        final int index = meta["index"] as int;
        final rawBytes = await fetchChunk(index);

        final Map<String, dynamic> envelope;
        try {
          envelope = jsonDecode(utf8.decode(rawBytes)) as Map<String, dynamic>;
        } catch (e) {
          throw Exception("Chunk $index envelope is corrupt or wrong format.");
        }

        final nonce      = base64Decode(envelope["n"] as String);
        final cipherText = base64Decode(envelope["c"] as String);
        final macBytes   = base64Decode(envelope["m"] as String);

        if (nonce.length != _nonceLen || macBytes.length != _macLen) {
          throw Exception("Chunk $index has invalid lengths.");
        }

        final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
        final chunkPlain = await _algorithm.decrypt(secretBox, secretKey: secretKey);

        if (expectedHashes != null) {
          final expected = expectedHashes[index];
          if (expected == null) {
            throw Exception("Integrity check failed: unexpected chunk $index.");
          }
          final actual = await _sha256Hex(chunkPlain);
          if (actual != expected) {
            throw Exception("Integrity check failed: chunk $index does not match its signed hash.");
          }
        }

        sink.add(chunkPlain);
      }
      await sink.flush();
    } catch (e) {
      throw Exception("Decryption failed: $e");
    } finally {
      await sink.close();
    }

    return file;
  }
}

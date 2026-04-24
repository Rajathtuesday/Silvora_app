import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

class FileDecryptor {
  static final Xchacha20 _algorithm = Xchacha20.poly1305Aead();
  static const int _nonceLen = 24;
  static const int _macLen   = 16;

  static Future<File> decryptFile({
    required List<Map<String, dynamic>> chunksMeta,
    required SecretKey secretKey,
    required String filename,
    required Future<Uint8List> Function(int index) fetchChunk,
  }) async {
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

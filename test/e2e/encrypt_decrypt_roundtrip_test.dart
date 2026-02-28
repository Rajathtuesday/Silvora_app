import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/file_key.dart';
import 'package:silvora_app/crypto/chunk_crypto.dart';
import 'package:silvora_app/crypto/file_decryptor.dart';

void main() {
  test('Full file encrypt → decrypt roundtrip', () async {
    final rand = Random(42);
    final original =
        Uint8List.fromList(List.generate(50000, (_) => rand.nextInt(256)));

    final masterKey =
        Uint8List.fromList(List.generate(32, (i) => i));
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: 'file-123',
    );

    const chunkSize = 8192;
    final encryptedChunks = <Uint8List>[];

    for (int i = 0; i < original.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, original.length);
      final chunk = original.sublist(i, end);

      encryptedChunks.add(
        await encryptChunk(
          plaintext: chunk,
          fileKey: fileKey,
          chunkIndex: encryptedChunks.length,
        ),
      );
    }

    final decryptor = FileDecryptor(fileKey: fileKey);
    final decrypted =
        await decryptor.decryptChunks(encryptedChunks: encryptedChunks);

    expect(decrypted, equals(original));
  });
}

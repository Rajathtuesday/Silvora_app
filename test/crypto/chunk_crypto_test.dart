import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/chunk_crypto.dart';

void main() {
  final fileKey = Uint8List.fromList(List.generate(32, (i) => i));
  final plaintext = Uint8List.fromList(List.generate(1024, (i) => i % 256));

  test('Encrypt → decrypt returns original plaintext', () async {
    final encrypted = await encryptChunk(
      plaintext: plaintext,
      fileKey: fileKey,
      chunkIndex: 0,
    );

    final decrypted = await decryptChunk(
      ciphertext: encrypted,
      fileKey: fileKey,
      chunkIndex: 0,
    );

    expect(decrypted, equals(plaintext));
  });

  test('Different chunk index produces different ciphertext', () async {
    final c1 = await encryptChunk(
      plaintext: plaintext,
      fileKey: fileKey,
      chunkIndex: 0,
    );

    final c2 = await encryptChunk(
      plaintext: plaintext,
      fileKey: fileKey,
      chunkIndex: 1,
    );

    expect(c1, isNot(equals(c2)));
  });

  test('Tampered ciphertext fails decryption', () async {
    final encrypted = await encryptChunk(
      plaintext: plaintext,
      fileKey: fileKey,
      chunkIndex: 0,
    );

    encrypted[10] ^= 0xFF;

    expect(
      () => decryptChunk(
        ciphertext: encrypted,
        fileKey: fileKey,
        chunkIndex: 0,
      ),
      throwsA(anything),
    );
  });
}

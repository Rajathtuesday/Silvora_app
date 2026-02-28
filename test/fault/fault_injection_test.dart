import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/file_key.dart';
import 'package:silvora_app/crypto/chunk_crypto.dart';
import 'package:silvora_app/crypto/file_decryptor.dart';
import 'package:silvora_app/crypto/integrity.dart';

void main() {
  late Uint8List original;
  late Uint8List masterKey;
  late Uint8List fileKey;
  late List<Uint8List> encryptedChunks;
  late List<Uint8List> chunkHashes;

  const chunkSize = 4096;

  setUp(() async {
    final rand = Random(123);
    original =
        Uint8List.fromList(List.generate(20000, (_) => rand.nextInt(256)));

    masterKey =
        Uint8List.fromList(List.generate(32, (i) => i));

    fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: 'fault-test-file',
    );

    encryptedChunks = [];
    chunkHashes = [];

    for (int i = 0; i < original.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, original.length);
      final chunk = original.sublist(i, end);

      final encrypted = await encryptChunk(
        plaintext: chunk,
        fileKey: fileKey,
        chunkIndex: encryptedChunks.length,
      );

      encryptedChunks.add(encrypted);
      chunkHashes.add(await hashChunk(encrypted));
    }
  });

  test('Bit-flipped chunk is detected', () async {
    final tampered = Uint8List.fromList(encryptedChunks[0]);
    tampered[10] ^= 0xFF;

    final decryptor = FileDecryptor(fileKey: fileKey);

    expect(
      () async {
        await decryptor.decryptChunks(
          encryptedChunks: [tampered, ...encryptedChunks.skip(1)],
        );
      },
      throwsA(anything),
    );
  });

  test('Reordered chunks are detected via integrity', () async {
    final swapped = List<Uint8List>.from(encryptedChunks);
    final tmp = swapped[0];
    swapped[0] = swapped[1];
    swapped[1] = tmp;

    final hashes = await Future.wait(swapped.map(hashChunk));
    final originalRoot = await merkleRoot(chunkHashes);
    final swappedRoot = await merkleRoot(hashes);

    expect(swappedRoot, isNot(equals(originalRoot)));
  });

  test('Missing chunk is detected', () async {
    final missing = encryptedChunks.sublist(1);

    expect(
      () async {
        final decryptor = FileDecryptor(fileKey: fileKey);
        await decryptor.decryptChunks(encryptedChunks: missing);
      },
      throwsA(anything),
    );
  });

  test('Replay old chunk fails integrity', () async {
    final replayed = List<Uint8List>.from(encryptedChunks);
    replayed[1] = encryptedChunks[0]; // replay chunk 0 as chunk 1

    final hashes = await Future.wait(replayed.map(hashChunk));
    final originalRoot = await merkleRoot(chunkHashes);
    final replayedRoot = await merkleRoot(hashes);

    expect(replayedRoot, isNot(equals(originalRoot)));
  });

  test('Wrong password cannot decrypt correctly', () async {
    final wrongMaster =
        Uint8List.fromList(List.generate(32, (i) => i + 1));

    final wrongFileKey = await deriveFileKey(
      masterKey: wrongMaster,
      fileId: 'fault-test-file',
    );

    final decryptor = FileDecryptor(fileKey: wrongFileKey);

    expect(
      () async {
        await decryptor.decryptChunks(
          encryptedChunks: encryptedChunks,
        );
      },
      throwsA(anything),
    );
  });
}

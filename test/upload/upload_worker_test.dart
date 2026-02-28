import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:silvora_app/infrastructure/uploads/upload_worker.dart';
import 'package:silvora_app/crypto/file_key.dart';
import 'package:silvora_app/crypto/chunk_crypto.dart';

void main() {
  late Directory tempDir;
  late File testFile;

  const chunkSize = 1024;

  setUp(() async {
    // Create temp directory
    tempDir = await Directory.systemTemp.createTemp('upload_worker_test');

    // Create deterministic test file
    final rand = Random(42);
    final bytes =
        Uint8List.fromList(List.generate(5000, (_) => rand.nextInt(256)));

    testFile = File(p.join(tempDir.path, 'test.bin'));
    await testFile.writeAsBytes(bytes);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('UploadWorker encrypts and decrypts chunks correctly', () async {
    final masterKey =
        Uint8List.fromList(List.generate(32, (i) => i));
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: 'file-test-1',
    );

    final worker = UploadWorker(
      file: testFile,
      fileKey: fileKey,
      chunkSize: chunkSize,
    );

    final originalBytes = await testFile.readAsBytes();
    final decryptedOut = BytesBuilder();

    final totalChunks =
        (originalBytes.length / chunkSize).ceil();

    for (int index = 0; index < totalChunks; index++) {
      final chunk = await worker.readAndEncryptChunk(index);

      // Decrypt immediately to verify correctness
      final decrypted = await decryptChunk(
        ciphertext: chunk.encrypted,
        fileKey: fileKey,
        chunkIndex: index,
      );

      decryptedOut.add(decrypted);
    }

    expect(decryptedOut.toBytes(), equals(originalBytes));
  });

  test('Same chunk encrypted twice is deterministic', () async {
    final masterKey =
        Uint8List.fromList(List.generate(32, (i) => i));
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: 'file-test-2',
    );

    final worker = UploadWorker(
      file: testFile,
      fileKey: fileKey,
      chunkSize: chunkSize,
    );

    final c1 = await worker.readAndEncryptChunk(0);
    final c2 = await worker.readAndEncryptChunk(0);

    expect(c1.encrypted, equals(c2.encrypted));
    expect(c1.plainSize, equals(c2.plainSize));
  });

  test('Different chunk indices produce different ciphertext', () async {
    final masterKey =
        Uint8List.fromList(List.generate(32, (i) => i));
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: 'file-test-3',
    );

    final worker = UploadWorker(
      file: testFile,
      fileKey: fileKey,
      chunkSize: chunkSize,
    );

    final c0 = await worker.readAndEncryptChunk(0);
    final c1 = await worker.readAndEncryptChunk(1);

    expect(c0.encrypted, isNot(equals(c1.encrypted)));
  });

  test('Last chunk size is correct', () async {
    final masterKey =
        Uint8List.fromList(List.generate(32, (i) => i));
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: 'file-test-4',
    );

    final worker = UploadWorker(
      file: testFile,
      fileKey: fileKey,
      chunkSize: chunkSize,
    );

    final fileSize = await testFile.length();
    final totalChunks = (fileSize / chunkSize).ceil();
    final lastChunk = await worker.readAndEncryptChunk(totalChunks - 1);

    final expectedLastSize =
        fileSize - (chunkSize * (totalChunks - 1));

    expect(lastChunk.plainSize, expectedLastSize);
  });

  test('Out-of-range chunk index throws', () async {
    final masterKey =
        Uint8List.fromList(List.generate(32, (i) => i));
    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: 'file-test-5',
    );

    final worker = UploadWorker(
      file: testFile,
      fileKey: fileKey,
      chunkSize: chunkSize,
    );

    final totalChunks =
        (await testFile.length() / chunkSize).ceil();

    expect(
      () => worker.readAndEncryptChunk(totalChunks),
      throwsStateError,
    );
  });
}

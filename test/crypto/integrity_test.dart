import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/integrity.dart';

void main() {
  test('Merkle root changes when chunk changes', () async {
    final c1 = Uint8List.fromList([1, 2, 3]);
    final c2 = Uint8List.fromList([4, 5, 6]);

    final h1 = await hashChunk(c1);
    final h2 = await hashChunk(c2);

    final root1 = await merkleRoot([h1, h2]);

    final h2b = await hashChunk(Uint8List.fromList([4, 5, 7]));
    final root2 = await merkleRoot([h1, h2b]);

    expect(root1, isNot(equals(root2)));
  });

  test('Merkle root deterministic', () async {
    final chunks = [
      Uint8List.fromList([1]),
      Uint8List.fromList([2]),
      Uint8List.fromList([3]),
    ];

    final hashes = await Future.wait(chunks.map(hashChunk));

    final r1 = await merkleRoot(hashes);
    final r2 = await merkleRoot(hashes);

    expect(r1, equals(r2));
  });
}

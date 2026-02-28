// ============================================================================
// Integrity Verification (Merkle Tree)
// - Hashes encrypted chunks
// - Builds deterministic Merkle root
// - Zero-knowledge safe
// ============================================================================

import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

final HashAlgorithm _sha256 = Sha256();

Future<Uint8List> hashChunk(Uint8List encryptedChunk) async {
  final hash = await _sha256.hash(encryptedChunk);
  return Uint8List.fromList(hash.bytes);
}

Future<Uint8List> merkleRoot(List<Uint8List> leafHashes) async {
  if (leafHashes.isEmpty) {
    throw ArgumentError("Cannot compute Merkle root of empty list");
  }

  List<Uint8List> level = List.from(leafHashes);

  while (level.length > 1) {
    final List<Uint8List> next = [];

    for (int i = 0; i < level.length; i += 2) {
      if (i + 1 == level.length) {
        // odd count → duplicate last
        next.add(level[i]);
      } else {
        final combined = Uint8List.fromList(
          level[i] + level[i + 1],
        );
        final hash = await _sha256.hash(combined);
        next.add(Uint8List.fromList(hash.bytes));
      }
    }

    level = next;
  }

  return level.first;
}

// ============================================================================
// File Manifest Model (Authoritative)
// Mirrors backend manifest EXACTLY.
// ============================================================================
import 'dart:convert';

class ManifestChunk {
  final int index;
  final int offset;
  final int size;
  final String sha256;

  ManifestChunk({
    required this.index,
    required this.offset,
    required this.size,
    required this.sha256,
  });

  factory ManifestChunk.fromJson(Map<String, dynamic> j) {
    return ManifestChunk(
      index: j['i'],
      offset: j['o'],
      size: j['s'],
      sha256: j['sha256'],
    );
  }
}

class FileManifest {
  final int version;
  final int keyVersion;
  final int totalChunks;
  final int size;
  final List<ManifestChunk> chunks;

  FileManifest({
    required this.version,
    required this.keyVersion,
    required this.totalChunks,
    required this.size,
    required this.chunks,
  });

  factory FileManifest.fromJson(Map<String, dynamic> json) {
    final raw = json['chunks'] as List;

    final chunks =
        raw.map((c) => ManifestChunk.fromJson(c)).toList();

    chunks.sort((a  , b) => a.index.compareTo(b.index));

    return FileManifest(
      version: json['v'],
      keyVersion: json['key_version'],
      totalChunks: json['total_chunks'],
      size: json['size'],
      chunks: chunks,
    );
  }
}

// ========================================================================
// lib/models/file_metadata.dart
class ManifestChunk {
  final int index;
  final int offset;
  final int size;
  final String nonceB64;
  final String macB64;

  ManifestChunk({
    required this.index,
    required this.offset,
    required this.size,
    required this.nonceB64,
    required this.macB64,
  });

  factory ManifestChunk.fromJson(Map<String, dynamic> j) {
    return ManifestChunk(
      index: j["index"],
      offset: j["offset"],
      size: j["ciphertext_size"],
      nonceB64: j["nonce_b64"],
      macB64: j["mac_b64"],
    );
  }
}

class FileManifest {
  final List<ManifestChunk> chunks;

  FileManifest(this.chunks);

  factory FileManifest.fromJson(Map<String, dynamic> json) {
    final list = (json["chunks"] as List)
        .map((c) => ManifestChunk.fromJson(c))
        .toList();

    list.sort((a, b) => a.index.compareTo(b.index));
    return FileManifest(list);
  }
}

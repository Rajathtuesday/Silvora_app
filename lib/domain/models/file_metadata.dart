// lib/models/file_metadata.dart

class ManifestChunk {
  final int index;
  final int size; // ciphertext size ONLY

  ManifestChunk({
    required this.index,
    required this.size,
  });

  factory ManifestChunk.fromJson(Map<String, dynamic> j) {
    return ManifestChunk(
      index: j["index"],
      size: j["ciphertext_size"],
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

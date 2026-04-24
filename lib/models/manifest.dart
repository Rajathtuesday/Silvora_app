// lib/models/manifest.dart
import 'dart:convert';

class ChunkMetadata {
  final int index;
  final int size;
  final String sha256;      // hex
  final String nonceB64;    // base64
  final String macB64;      // base64

  ChunkMetadata({
    required this.index,
    required this.size,
    required this.sha256,
    required this.nonceB64,
    required this.macB64,
  });

  Map<String, dynamic> toJson() => {
        "index": index,
        "size": size,
        "sha256": sha256,
        "nonce_b64": nonceB64,
        "mac_b64": macB64,
      };

  static ChunkMetadata fromJson(Map<String, dynamic> j) => ChunkMetadata(
        index: j['index'],
        size: j['size'],
        sha256: j['sha256'],
        nonceB64: j['nonce_b64'],
        macB64: j['mac_b64'],
      );
}

class UploadManifest {
  final int manifestVersion;
  final String encryption; // "XCHACHA20_POLY1305"
  final String fileSaltB64;
  final String filename;
  final int fileSize;
  final int chunkSize;
  final List<ChunkMetadata> chunks;

  UploadManifest({
    this.manifestVersion = 1,
    required this.encryption,
    required this.fileSaltB64,
    required this.filename,
    required this.fileSize,
    required this.chunkSize,
    required this.chunks,
  });

  Map<String, dynamic> toJson() => {
        "manifest_version": manifestVersion,
        "encryption": encryption,
        "file_salt_b64": fileSaltB64,
        "filename": filename,
        "file_size": fileSize,
        "chunk_size": chunkSize,
        "chunks": chunks.map((c) => c.toJson()).toList(),
      };

  static UploadManifest fromJson(Map<String, dynamic> j) => UploadManifest(
        manifestVersion: j['manifest_version'] ?? 1,
        encryption: j['encryption'],
        fileSaltB64: j['file_salt_b64'],
        filename: j['filename'],
        fileSize: j['file_size'],
        chunkSize: j['chunk_size'],
        chunks: (j['chunks'] as List).map((e) => ChunkMetadata.fromJson(e)).toList(),
      );

  String toJsonString() => jsonEncode(toJson());
}

// ========================================================================
// lib/models/file_item.dart
class FileItem {
  final String fileId;
  final String filenameEnc;
  final String filenameNonce;
  final int size;

  FileItem({
    required this.fileId,
    required this.filenameEnc,
    required this.filenameNonce,
    required this.size,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileId: json["file_id"],
      filenameEnc: json["filename_enc"],
      filenameNonce: json["filename_nonce"],
      size: json["size"],
    );
  }
}

// lib/uploads/upload_session.dart

class UploadSession {
  final String fileId;
  final int chunkSize;
  final int totalChunks;

  /// Indices of chunks already confirmed by server
  final Set<int> uploadedChunks;

  /// Latest manifest revision from server
  int manifestRevision;

  UploadSession({
    required this.fileId,
    required this.chunkSize,
    required this.totalChunks,
    required Set<int> uploadedChunks,
    required this.manifestRevision,
  }) : uploadedChunks = Set<int>.from(uploadedChunks);

  /// Returns true if all chunks are uploaded
  bool get isComplete => uploadedChunks.length == totalChunks;

  /// Returns the next chunk index to upload, or null if done
  int? nextChunkToUpload() {
    for (int i = 0; i < totalChunks; i++) {
      if (!uploadedChunks.contains(i)) {
        return i;
      }
    }
    return null;
  }

  /// Mark a chunk as uploaded
  void markUploaded(int index) {
    uploadedChunks.add(index);
  }
}

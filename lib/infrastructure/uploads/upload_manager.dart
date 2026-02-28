// =============================================================================
// Upload Manager (Backend-Aligned Version)
// =============================================================================

import 'dart:io';
import 'dart:typed_data';

import '../api/upload_api.dart';
import '../../crypto/chunk_crypto.dart';
import 'upload_session.dart';
import 'upload_session_store.dart';

class UploadManager {
  final UploadApi _api;

  UploadManager(this._api);

  // ==========================================================
  // START
  // ==========================================================

  Future<UploadSession> start({
    required File file,
    required String filenameCipherHex,
    required String filenameNonceHex,
    required String filenameMacHex,
    required int chunkSize,
    required String securityMode,
  }) async {
    final fileSize = await file.length();

    final data = await _api.startUpload(
      filenameCiphertextHex: filenameCipherHex,
      filenameNonceHex: filenameNonceHex,
      filenameMacHex: filenameMacHex,
      size: fileSize,
      securityMode: securityMode,
    );

    final totalChunks = (fileSize / chunkSize).ceil();

    final session = UploadSession(
      fileId: data['file_id'],
      chunkSize: chunkSize,
      totalChunks: totalChunks,
      uploadedChunks: {},
      manifestRevision: 0,
    );

    await UploadSessionStore.save(
      fileId: session.fileId,
      filePath: file.path,
      fileSize: fileSize,
      chunkSize: chunkSize,
      totalChunks: totalChunks,
      uploadedChunks: {},
      manifestRevision: 0,
    );

    return session;
  }

  // ==========================================================
  // UPLOAD ONE CHUNK
  // ==========================================================

  Future<void> uploadOneChunk({
    required UploadSession session,
    required File file,
    required Uint8List fileKey,
  }) async {
    final index = session.nextChunkToUpload();
    if (index == null) return;

    final offset = index * session.chunkSize;
    final fileLength = await file.length();

    final raf = file.openSync(mode: FileMode.read);
    raf.setPositionSync(offset);

    final remaining = fileLength - offset;
    final readSize =
        remaining < session.chunkSize ? remaining : session.chunkSize;

    final Uint8List plaintext = raf.readSync(readSize);
    raf.closeSync();

    // 🔐 Encrypt chunk
    final encrypted = await encryptChunk(
      plaintext: plaintext,
      fileKey: fileKey,
      chunkIndex: index,
      fileId: session.fileId,
    );

    // Combine ciphertext + mac because backend stores opaque bytes
    final Uint8List blob =
        Uint8List.fromList(encrypted.ciphertext + encrypted.mac);

    // 🚀 Upload chunk (multipart)
    await _api.uploadChunk(
      fileId: session.fileId,
      index: index,
      encryptedChunk: blob,
    );

    // Mark uploaded
    session.markUploaded(index);

    await UploadSessionStore.save(
      fileId: session.fileId,
      filePath: file.path,
      fileSize: fileLength,
      chunkSize: session.chunkSize,
      totalChunks: session.totalChunks,
      uploadedChunks: session.uploadedChunks,
      manifestRevision: session.manifestRevision,
    );
  }

  // ==========================================================
  // FINISH (COMMIT)
  // ==========================================================

  Future<void> finish(UploadSession session) async {
    await _api.commitUpload(session.fileId);
    await UploadSessionStore.delete(session.fileId);
  }

  // ==========================================================
  // RESUME
  // ==========================================================

  Future<(UploadSession, File)> resume({
    required String fileId,
  }) async {
    final local = await UploadSessionStore.load(fileId);
    if (local == null) {
      throw StateError("No local session");
    }

    final server = await _api.resumeUpload(fileId);

    final uploaded = Set<int>.from(server['uploaded_indices']);

    final session = UploadSession(
      fileId: fileId,
      chunkSize: local['chunk_size'],
      totalChunks: local['total_chunks'],
      uploadedChunks: uploaded,
      manifestRevision: local['manifest_revision'],
    );

    final file = File(local['file_path']);

    if (!file.existsSync()) {
      throw StateError("Original file missing for resume");
    }

    return (session, file);
  }
}
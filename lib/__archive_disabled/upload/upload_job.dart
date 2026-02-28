// lib/upload/upload_job.dart

import 'dart:convert';
import 'upload_state.dart';

class UploadJob {
  // ───────── Identity ─────────
  final String jobId;        // local UUID
  final String uploadId;     // server-issued (nullable until start)

  // ───────── File binding ─────────
  final String filePath;
  final String filename;
  final int fileSize;
  final int chunkSize;

  // ───────── Security binding ─────────
  final String securityMode;           // "zero_knowledge" | "standard"
  final int cryptoVersion;             // bump if derivation changes
  final String vaultKeyFingerprint;    // first 16 bytes of SHA256
  final String fileSaltB64;             // per-file salt

  // ───────── Progress ─────────
  final int totalChunks;
  final Set<int> uploadedChunks;

  // ───────── Lifecycle ─────────
  final UploadState state;
  final UploadPauseReason? pauseReason;
  final String? lastError;

  // ───────── Timestamps ─────────
  final DateTime createdAt;
  final DateTime updatedAt;

  const UploadJob({
    required this.jobId,
    required this.uploadId,
    required this.filePath,
    required this.filename,
    required this.fileSize,
    required this.chunkSize,
    required this.securityMode,
    required this.cryptoVersion,
    required this.vaultKeyFingerprint,
    required this.fileSaltB64,
    required this.totalChunks,
    required this.uploadedChunks,
    required this.state,
    required this.pauseReason,
    required this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  // ───────── Invariants ─────────
  void validate() {
    if (fileSize <= 0) {
      throw StateError("Invalid file size");
    }
    if (chunkSize <= 0) {
      throw StateError("Invalid chunk size");
    }
    if (uploadedChunks.any((i) => i < 0 || i >= totalChunks)) {
      throw StateError("Uploaded chunk index out of bounds");
    }
    if (uploadedChunks.length > totalChunks) {
      throw StateError("Uploaded chunks exceed total chunks");
    }
    if (state == UploadState.completed &&
        uploadedChunks.length != totalChunks) {
      throw StateError(
        "Completed upload with missing chunks",
      );
    }
  }

  // ───────── Immutable update ─────────
  UploadJob copyWith({
    String? uploadId,
    Set<int>? uploadedChunks,
    UploadState? state,
    UploadPauseReason? pauseReason,
    String? lastError,
  }) {
    final nextState = state ?? this.state;
    assertValidTransition(this.state, nextState);

    final updated = UploadJob(
      jobId: jobId,
      uploadId: uploadId ?? this.uploadId,
      filePath: filePath,
      filename: filename,
      fileSize: fileSize,
      chunkSize: chunkSize,
      securityMode: securityMode,
      cryptoVersion: cryptoVersion,
      vaultKeyFingerprint: vaultKeyFingerprint,
      fileSaltB64: fileSaltB64,
      totalChunks: totalChunks,
      uploadedChunks: uploadedChunks ?? this.uploadedChunks,
      state: nextState,
      pauseReason: pauseReason,
      lastError: lastError,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

    updated.validate();
    return updated;
  }

  // ───────── Serialization ─────────
  Map<String, dynamic> toMap() {
    return {
      "job_id": jobId,
      "upload_id": uploadId,
      "file_path": filePath,
      "filename": filename,
      "file_size": fileSize,
      "chunk_size": chunkSize,
      "security_mode": securityMode,
      "crypto_version": cryptoVersion,
      "vault_fingerprint": vaultKeyFingerprint,
      "file_salt_b64": fileSaltB64,
      "total_chunks": totalChunks,
      "uploaded_chunks": jsonEncode(uploadedChunks.toList()),
      "state": state.name,
      "pause_reason": pauseReason?.name,
      "last_error": lastError,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }

  static UploadJob fromMap(Map<String, dynamic> m) {
    final job = UploadJob(
      jobId: m["job_id"],
      uploadId: m["upload_id"],
      filePath: m["file_path"],
      filename: m["filename"],
      fileSize: m["file_size"],
      chunkSize: m["chunk_size"],
      securityMode: m["security_mode"],
      cryptoVersion: m["crypto_version"],
      vaultKeyFingerprint: m["vault_fingerprint"],
      fileSaltB64: m["file_salt_b64"],
      totalChunks: m["total_chunks"],
      uploadedChunks: Set<int>.from(
        (jsonDecode(m["uploaded_chunks"]) as List).cast<int>(),
      ),
      state: UploadState.values.firstWhere(
        (s) => s.name == m["state"],
      ),
      pauseReason: m["pause_reason"] == null
          ? null
          : UploadPauseReason.values.firstWhere(
              (p) => p.name == m["pause_reason"],
            ),
      lastError: m["last_error"],
      createdAt: DateTime.parse(m["created_at"]),
      updatedAt: DateTime.parse(m["updated_at"]),
    );

    job.validate();
    return job;
  }
}

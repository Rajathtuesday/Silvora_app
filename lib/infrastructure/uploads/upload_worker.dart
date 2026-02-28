// // ============================================================================
// // Upload Worker
// //
// // Responsibilities:
// // - Read file chunks
// // - Encrypt chunks using chunk_crypto.dart
// // - Return encrypted payloads
// //
// // SECURITY CONTRACT:
// // - No key derivation here
// // - No random nonces
// // - No MAC handling
// // - Stateless and resumable
// // ============================================================================

// import 'dart:io';
// import 'dart:typed_data';

// import '../crypto/chunk_crypto.dart';

// class EncryptedChunk {
//   final int index;
//   final Uint8List encrypted; // ciphertext || mac
//   final int plainSize;

//   EncryptedChunk({
//     required this.index,
//     required this.encrypted,
//     required this.plainSize,
//   });
// }

// class UploadWorker {
//   final File _file;
//   final Uint8List _fileKey;
//   final int _chunkSize;

//   UploadWorker({
//     required File file,
//     required Uint8List fileKey,
//     required int chunkSize,
//   })  : _file = file,
//         _fileKey = fileKey,
//         _chunkSize = chunkSize;

//   Future<EncryptedChunk> readAndEncryptChunk(int index) async {
//     final int offset = index * _chunkSize;

//     final RandomAccessFile raf =
//         await _file.open(mode: FileMode.read);

//     try {
//       await raf.setPosition(offset);

//       final int remaining = _file.lengthSync() - offset;
//       if (remaining <= 0) {
//         throw StateError("Chunk index out of range");
//       }

//       final int readSize =
//           remaining < _chunkSize ? remaining : _chunkSize;

//       final Uint8List plaintext =
//           Uint8List.fromList(await raf.read(readSize));

//       final Uint8List encrypted = await encryptChunk(
//         plaintext: plaintext,
//         fileKey: _fileKey,
//         chunkIndex: index,
//       );

//       return EncryptedChunk(
//         index: index,
//         encrypted: encrypted,
//         plainSize: plaintext.length,
//       );
//     } finally {
//       await raf.close();
//     }
//   }
// }
// ===============================v2=============================
// ============================================================================
// Upload Worker (E2EE Safe Version)
//
// Responsibilities:
// - Read file chunks
// - Encrypt chunks using chunk_crypto.dart
// - Return structured encrypted payload
//
// SECURITY CONTRACT:
// - No key derivation here
// - No random nonces
// - No MAC generation here
// - Stateless and resumable
// ============================================================================
// NOTE: This worker is designed to be used by UploadManager, which handles manifest management, session state, and retry logic. The worker focuses solely on chunk processing.
// ============================================================================
//lib/infrastructure/uploads/upload_worker.dart

import 'dart:io';
import 'dart:typed_data';

import '../../crypto/chunk_crypto.dart';

/// Structured encrypted chunk returned to UploadManager
class EncryptedChunk {
  final int index;
  final Uint8List ciphertext;
  final Uint8List mac;
  final Uint8List nonce;
  final int plainSize;

  EncryptedChunk({
    required this.index,
    required this.ciphertext,
    required this.mac,
    required this.nonce,
    required this.plainSize,
  });
}

class UploadWorker {
  final File _file;
  final Uint8List _fileKey;
  final int _chunkSize;

  UploadWorker({
    required File file,
    required Uint8List fileKey,
    required int chunkSize,
  })  : _file = file,
        _fileKey = fileKey,
        _chunkSize = chunkSize;

  /// Reads a chunk from disk and encrypts it
  Future<EncryptedChunk> readAndEncryptChunk(int index) async {
    final int offset = index * _chunkSize;

    final RandomAccessFile raf =
        await _file.open(mode: FileMode.read);

    try {
      await raf.setPosition(offset);

      final int fileLength = _file.lengthSync();
      final int remaining = fileLength - offset;

      if (remaining <= 0) {
        throw StateError("Chunk index out of range");
      }

      final int readSize =
          remaining < _chunkSize ? remaining : _chunkSize;

      final Uint8List plaintext =
          Uint8List.fromList(await raf.read(readSize));

      // 🔐 encryptChunk now returns structured result
      final encrypted = await encryptChunk(
        plaintext: plaintext,
        fileKey: _fileKey,
        chunkIndex: index,
        fileId: _file.path, // Use the file path as the fileId for now  
      );

      return EncryptedChunk(
        index: index,
        ciphertext: encrypted.ciphertext,
        mac: encrypted.mac,
        nonce: encrypted.nonce,
        plainSize: plaintext.length,
      );
    } finally {
      await raf.close();
    }
  }
}

// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';

// import '../crypto/hkdf.dart';
// import '../services/upload_service.dart';

// class UploadTaskParams {
//   final String filePath;
//   final int fileSize;
//   final String fileId;
//   final Uint8List masterKey;
//   final int chunkSize;

//   UploadTaskParams({
//     required this.filePath,
//     required this.fileSize,
//     required this.fileId,
//     required this.masterKey,
//     required this.chunkSize,
//   });
// }

// Future<void> uploadWorker(
//   UploadTaskParams params,
//   void Function(int uploadedBytes) onProgress,
// ) async {
//   final file = File(params.filePath);
//   final raf = await file.open();
//   final cipher = Xchacha20.poly1305Aead();

//   final uploaded = await UploadService.resumeUpload(params.fileId);
//   final chunks = (params.fileSize / params.chunkSize).ceil();

//   try {
//     for (int i = 0; i < chunks; i++) {
//       if (uploaded.contains(i)) continue;

//       await raf.setPosition(i * params.chunkSize);
//       final plain = await raf.read(
//         ((i + 1) * params.chunkSize > params.fileSize)
//             ? params.fileSize - i * params.chunkSize
//             : params.chunkSize,
//       );

//       final key = await hkdfSha256(
//         ikm: params.masterKey,
//         info: utf8.encode("silvora-chunk-$i"),
//       );

//       final nonce = await cipher.newNonce();
//       final box = await cipher.encrypt(
//         plain,
//         secretKey: SecretKey(key),
//         nonce: nonce,
//       );

//       await UploadService.uploadChunk(
//         fileId: params.fileId,
//         chunkIndex: i,
//         cipherChunk: Uint8List.fromList(box.cipherText),
//         nonce: Uint8List.fromList(nonce),
//         mac: Uint8List.fromList(box.mac.bytes),
//       );

//       onProgress(plain.length);
//     }
//   } finally {
//     await raf.close();
//   }
// }=
// =================================================================================
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:isolate';

// import 'package:cryptography/cryptography.dart';
// import 'package:flutter/material.dart';

// import '../crypto/hkdf.dart';
// import 'upload_service.dart';

// class UploadTaskParams {
//   final String filePath;
//   final int fileSize;
//   final String fileId;
//   final Uint8List masterKey;
//   final int chunkSize;
//   final Set<int> uploadedChunks;
//   final String accessToken;

//   UploadTaskParams({
//     required this.filePath,
//     required this.fileSize,
//     required this.fileId,
//     required this.masterKey,
//     required this.chunkSize,
//     required this.uploadedChunks,
//     required this.accessToken,
//   });
// }

// Future<void> uploadWorker(
//   UploadTaskParams params,
//   SendPort progressPort,
// ) async {
//   // 🔑 AUTH FOR THIS ISOLATE
//   UploadService.setAccessTokenForIsolate(params.accessToken);

//   final file = File(params.filePath);
//   final raf = await file.open();
//   final cipher = Xchacha20.poly1305Aead();

//   final totalChunks = (params.fileSize / params.chunkSize).ceil();

//   try {
//     for (int i = 0; i < totalChunks; i++) {
//       if (params.uploadedChunks.contains(i)) continue;

//       await raf.setPosition(i * params.chunkSize);
//       final plain = await raf.read(
//         ((i + 1) * params.chunkSize > params.fileSize)
//             ? params.fileSize - i * params.chunkSize
//             : params.chunkSize,
//       );

//       final key = await hkdfSha256(
//         ikm: params.masterKey,
//         info: utf8.encode("silvora-chunk-$i"),
//       );

//       final nonce = await cipher.newNonce();
//       final box = await cipher.encrypt(
//         plain,
//         secretKey: SecretKey(key),
//         nonce: nonce,
//       );

//       await UploadService.uploadChunk(
//         fileId: params.fileId,
//         chunkIndex: i,
//         cipherChunk: Uint8List.fromList(box.cipherText),
//         nonce: Uint8List.fromList(nonce),
//         mac: Uint8List.fromList(box.mac.bytes),
//       );


//       progressPort.send(plain.length);

//     }
//       debugPrint("🧵 Worker finished all chunks, sending DONE");
//       progressPort.send("DONE");
//   }catch (e, st) {
//     debugPrint("❌ Worker error: $e");
//     debugPrint(st.toString());
//     rethrow;}
//     finally {
//     await raf.close();
//     debugPrint("Worker Exiting");
//   }
// }

// /// TOP-LEVEL ENTRY (REQUIRED)
// void uploadWorkerEntry(List<dynamic> args) async {
//   final UploadTaskParams params = args[0];
//   final SendPort port = args[1];
//   await uploadWorker(params, port);
// }
// // =====================================================
// import 'dart:io';
// import 'dart:isolate';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';

// import 'upload_service.dart';
// import '../crypto/hkdf.dart';

// class UploadTaskParams {
//   final String filePath;
//   final int fileSize;
//   final String fileId;
//   final List<int> masterKey;
//   final int chunkSize;
//   final Map<int, bool> uploadedChunks;
//   final String accessToken;

//   UploadTaskParams({
//     required this.filePath,
//     required this.fileSize,
//     required this.fileId,
//     required this.masterKey,
//     required this.chunkSize,
//     required this.uploadedChunks,
//     required this.accessToken,
//   });
// }

// Future<void> uploadWorkerEntry(List<dynamic> args) async {
//   final params = args[0] as UploadTaskParams;
//   final SendPort sendPort = args[1] as SendPort;

//   try {
//     await uploadWorker(params, sendPort);
//   } catch (e, st) {
//     sendPort.send({
//       "type": "ERROR",
//       "error": e.toString(),
//       "stack": st.toString(),
//     });
//   } finally {
//     sendPort.send("EXIT");
//   }
// }

// Future<void> uploadWorker(
//   UploadTaskParams params,
//   SendPort sendPort,
// ) async {
//   final file = File(params.filePath);
//   final raf = file.openSync(mode: FileMode.read);

//   final cipher = Xchacha20.poly1305Aead();
//   final totalChunks =
//       (params.fileSize / params.chunkSize).ceil();

//   for (int index = 0; index < totalChunks; index++) {
//     if (params.uploadedChunks[index] == true) continue;

//     final offset = index * params.chunkSize;
//     raf.setPositionSync(offset);

//     final remaining = params.fileSize - offset;
//     final readSize =
//         remaining < params.chunkSize ? remaining : params.chunkSize;

//     final plaintext = raf.readSync(readSize);

//     try {
//       /// 🔐 Derive per-chunk key (SYNC)
//       final keyBytes = hkdfSha256(
//         ikm: params.masterKey,
//         info: "silvora-chunk-$index".codeUnits,
//       );

//       final nonce = await cipher.newNonce();

//       final box = await cipher.encrypt(
//         plaintext,
//         secretKey: SecretKey(Uint8List.fromList(keyBytes)),
//         nonce: nonce,
//       );

//       /// 🚀 Upload encrypted chunk (OLD API)
//       await UploadService.uploadChunk(
//         fileId: params.fileId,
//         index: index,
//         cipherChunk: Uint8List.fromList(box.cipherText),
//         nonce: Uint8List.fromList(nonce),
//         mac: Uint8List.fromList(box.mac.bytes),
//         accessToken: params.accessToken,
//       );

//       sendPort.send(plaintext.length);
//     } catch (e) {
//       sendPort.send({
//         "type": "CHUNK_ERROR",
//         "chunkIndex": index,
//         "error": e.toString(),
//       });
//       return;
//     }
//   }

//   raf.closeSync();
//   sendPort.send("DONE");
// }
// =====================================================
// import 'dart:io';
// import 'dart:isolate';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';

// import 'upload_service.dart';
// import '../crypto/hkdf.dart';

// class UploadTaskParams {
//   final String filePath;
//   final int fileSize;
//   final String fileId;
//   final List<int> masterKey;
//   final int chunkSize;
//   final Map<int, bool> uploadedChunks;
//   final String accessToken;

//   UploadTaskParams({
//     required this.filePath,
//     required this.fileSize,
//     required this.fileId,
//     required this.masterKey,
//     required this.chunkSize,
//     required this.uploadedChunks,
//     required this.accessToken,
//   });
// }

// Future<void> uploadWorkerEntry(List<dynamic> args) async {
//   final params = args[0] as UploadTaskParams;
//   final SendPort sendPort = args[1] as SendPort;

//   try {
//     await uploadWorker(params, sendPort);
//   } catch (e, st) {
//     sendPort.send({
//       "type": "ERROR",
//       "error": e.toString(),
//       "stack": st.toString(),
//     });
//   } finally {
//     sendPort.send("EXIT");
//   }
// }

// Future<void> uploadWorker(
//   UploadTaskParams params,
//   SendPort sendPort,
// ) async {
//   final file = File(params.filePath);
//   final raf = file.openSync(mode: FileMode.read);

//   final cipher = Xchacha20.poly1305Aead();
//   final totalChunks =
//       (params.fileSize / params.chunkSize).ceil();

//   try {
//     for (int index = 0; index < totalChunks; index++) {
//       if (params.uploadedChunks[index] == true) continue;

//       final offset = index * params.chunkSize;
//       raf.setPositionSync(offset);

//       final remaining = params.fileSize - offset;
//       final readSize =
//           remaining < params.chunkSize ? remaining : params.chunkSize;

//       final Uint8List plaintext =
//           Uint8List.fromList(raf.readSync(readSize));

//       // 🔐 HKDF (SYNC)
//      final Uint8List keyBytes = await hkdfSha256(
//         ikm: Uint8List.fromList(params.masterKey),
//         info: "silvora-chunk-$index".codeUnits,
//       );

//       final Uint8List nonce =
//           Uint8List.fromList(await cipher.newNonce());

//       final SecretBox box = await cipher.encrypt(
//         plaintext,
//         secretKey: SecretKey(keyBytes),
//         nonce: nonce,
//       );


//       await UploadService.uploadChunk(
//         fileId: params.fileId,
//         index: index,
//         cipherChunk: Uint8List.fromList(box.cipherText),
//         nonce: nonce,
//         mac: Uint8List.fromList(box.mac.bytes),
//         accessToken: params.accessToken,
//       );

//       sendPort.send(plaintext.length);
//     }

//     sendPort.send("DONE");
//   } finally {
//     raf.closeSync();
//   }
// }
// // =====================================================
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'upload_service.dart';
import '../crypto/hkdf.dart';

class UploadTaskParams {
  final String filePath;
  final int fileSize;
  final String fileId;
  final Uint8List masterKey; // 🔴 FIXED TYPE
  final int chunkSize;
  final Map<int, bool> uploadedChunks;
  final String accessToken;

  UploadTaskParams({
    required this.filePath,
    required this.fileSize,
    required this.fileId,
    required this.masterKey,
    required this.chunkSize,
    required this.uploadedChunks,
    required this.accessToken,
  });
}

Future<void> uploadWorkerEntry(List<dynamic> args) async {
  final params = args[0] as UploadTaskParams;
  final SendPort sendPort = args[1] as SendPort;

  try {
    await uploadWorker(params, sendPort);
  } catch (e, st) {
    sendPort.send({
      "type": "ERROR",
      "error": e.toString(),
      "stack": st.toString(),
    });
  } finally {
    sendPort.send("EXIT");
  }
}

Future<void> uploadWorker(
  UploadTaskParams params,
  SendPort sendPort,
) async {
  final file = File(params.filePath);
  final raf = file.openSync(mode: FileMode.read);

  final cipher = Xchacha20.poly1305Aead();
  final totalChunks =
      (params.fileSize / params.chunkSize).ceil();

  for (int index = 0; index < totalChunks; index++) {
    if (params.uploadedChunks[index] == true) continue;

    int attempt = 0;

    while (attempt < 2) {
      try {
        final offset = index * params.chunkSize;
        raf.setPositionSync(offset);

        final remaining = params.fileSize - offset;
        final readSize =
            remaining < params.chunkSize ? remaining : params.chunkSize;

        final plaintext = raf.readSync(readSize);

        /// 🔐 FIX 1: await HKDF and keep Uint8List
        final Uint8List chunkKey = await hkdfSha256(
          ikm: params.masterKey,
          info: "silvora-chunk-$index".codeUnits,
        );

        final nonce = await cipher.newNonce();

        final box = await cipher.encrypt(
          plaintext,
          secretKey: SecretKey(chunkKey), // 🔐 FIX 2
          nonce: nonce,
        );

        await UploadService.uploadChunk(
          fileId: params.fileId,
          index: index,
          cipherChunk: Uint8List.fromList(box.cipherText),
          nonce: Uint8List.fromList(nonce),
          mac: Uint8List.fromList(box.mac.bytes),
          accessToken: params.accessToken,
        );

        sendPort.send(plaintext.length);
        break;
      } catch (e) {
        attempt++;

        if (attempt >= 2) {
          sendPort.send({
            "type": "FATAL_CHUNK_ERROR",
            "chunkIndex": index,
            "error": e.toString(),
          });
          raf.closeSync();
          return;
        }
      }
    }
  }

  raf.closeSync();
  sendPort.send("DONE");
}
// =====================================================
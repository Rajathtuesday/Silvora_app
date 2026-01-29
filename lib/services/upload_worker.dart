
// =====================================================
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

import '../crypto/hkdf.dart';

class UploadTaskParams {
  final String serverBaseUrl; // 👈 PASSED IN
  final String filePath;
  final int fileSize;
  final String fileId;
  final Uint8List masterKey;
  final int chunkSize;
  final Map<int, bool> uploadedChunks;
  final String accessToken;

  UploadTaskParams({
    required this.serverBaseUrl,
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

  final uploadBase =
      "${params.serverBaseUrl}/upload/file/${params.fileId}/chunk";

  for (int index = 0; index < totalChunks; index++) {
    if (params.uploadedChunks[index] == true) continue;

    final offset = index * params.chunkSize;
    raf.setPositionSync(offset);

    final remaining = params.fileSize - offset;
    final readSize =
        remaining < params.chunkSize ? remaining : params.chunkSize;

    final plaintext = raf.readSync(readSize);

    final chunkKey = await hkdfSha256(
      ikm: params.masterKey,
      info: "silvora-chunk-$index".codeUnits,
    );

    final nonce = await cipher.newNonce();

    final box = await cipher.encrypt(
      plaintext,
      secretKey: SecretKey(chunkKey),
      nonce: nonce,
    );

    final req = http.MultipartRequest(
      "POST",
      Uri.parse("$uploadBase/$index/"),
    );

    req.headers.addAll({
      "Authorization": "Bearer ${params.accessToken}",
      "X-Chunk-Nonce": base64Encode(nonce),
      "X-Chunk-Mac": base64Encode(box.mac.bytes),
    });

    req.files.add(
      http.MultipartFile.fromBytes(
        "chunk",
        box.cipherText,
        filename: "chunk_$index.bin",
      ),
    );

    final res = await req.send();
    if (res.statusCode != 200) {
      throw Exception("Chunk upload failed");
    }

    sendPort.send(plaintext.length);
  }

  raf.closeSync();
  sendPort.send("DONE");
}

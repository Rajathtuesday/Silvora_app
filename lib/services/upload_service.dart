import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'auth_client.dart';
import 'package:image/image.dart' as img;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../state/secure_state.dart';
import '../crypto/hkdf.dart';

class UploadService {
  static String get _baseUrl => SecureState.serverUrl;
  static Map<String, String> _authHeaders() => SecureState.authHeader();
  static Uri _url(String path) => Uri.parse("$_baseUrl$path");

  // =============================================================
  // 1️⃣ START UPLOAD (Encrypts Filename securely)
  // =============================================================
  static Future<String?> startUpload({
    required String filename,
    required int fileSize,
    required int chunkSize,
    required String securityMode, // "zero_knowledge"
  }) async {
    try {
      final fileId = const Uuid().v4();
      
      // Derive a unique key for encrypting the filename using Master Key
      final nameKeyBytes = await hkdfSha256(
        ikm: SecureState.masterKey,
        info: utf8.encode("silvora_filename_$fileId"),
      );

      final algo = Xchacha20.poly1305Aead();
      final secretKey = SecretKey(nameKeyBytes);
      final nonce = await algo.newNonce();

      // Encrypt the filename string
      final box = await algo.encrypt(
        utf8.encode(filename),
        secretKey: secretKey,
        nonce: nonce,
      );

      final filenameCiphertextHex = box.cipherText.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final filenameNonceHex = nonce.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final filenameMacHex = box.mac.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      final res = await AuthClient.post(
        _url("/file/start/"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "file_id": fileId,
          "filename_ciphertext": filenameCiphertextHex,
          "filename_nonce": filenameNonceHex,
          "filename_mac": filenameMacHex,
          "size": fileSize,
          "chunk_size": chunkSize,
          "security_mode": securityMode,
        }),
      );

      if (res.statusCode != 200) {
        debugPrint("❌ start_upload failed: ${res.body}");
        return null;
      }

      return jsonDecode(res.body)["file_id"] ?? fileId; // Uses local fileId if not echoed
    } catch (e) {
      debugPrint("❌ start_upload exception: $e");
      return null;
    }
  }

  // =============================================================
  // 2️⃣ RESUME UPLOAD
  // =============================================================
  static Future<Set<int>?> resumeUpload(String uploadId) async {
    try {
      final res = await AuthClient.get(
        _url("/file/$uploadId/resume/"),
      );

      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body);
      final List<dynamic> uploaded = decoded["uploaded_indices"];
      return uploaded.map((e) => e as int).toSet();
    } catch (_) {
      return null;
    }
  }

  // =============================================================
  // 3️⃣ UPLOAD CHUNK (ENCRYPTED)
  // =============================================================
  static Future<bool> uploadChunk({
    required String uploadId,
    required int chunkIndex,
    required Uint8List cipherChunk,
    required Uint8List nonce,
    required Uint8List mac,
  }) async {
    try {
      final req = http.MultipartRequest(
        "POST",
        _url("/file/$uploadId/chunk/$chunkIndex/"),
      );

      req.headers.addAll(_authHeaders());

      // Use a self-describing JSON envelope to avoid platform-specific
      // byte packing differences between Android and iOS native crypto.
      final envelope = jsonEncode({
        "n": base64Encode(nonce),
        "c": base64Encode(cipherChunk),
        "m": base64Encode(mac),
      });

      req.files.add(
        http.MultipartFile.fromBytes(
          "chunk",
          utf8.encode(envelope),
          filename: "chunk_$chunkIndex.bin",
        ),
      );

      final res = await req.send();
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("❌ upload_chunk failed: $e");
      return false;
    }
  }

  // =============================================================
  // 4️⃣ FINISH UPLOAD
  // =============================================================
  static Future<bool> finishUpload({
    required String uploadId,
  }) async {
    try {
      final res = await AuthClient.post(  
        _url("/file/$uploadId/commit/"), // fixed to commit route
      );

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


}

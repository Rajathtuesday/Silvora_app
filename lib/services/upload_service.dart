// lib/services/upload_service.dart
// import 'dart:convert';

// import 'package:crypto/crypto.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// import '../state/secure_state.dart';

// class UploadService {
//   // =============================================================
//   // BASE CONFIG
//   // =============================================================

//   static String get _baseUrl => SecureState.serverUrl;

//   static Uri _url(String path) => Uri.parse("$_baseUrl$path");

//   static Map<String, String> _authHeaders() {
//     final token = SecureState.accessToken;
//     if (token == null) {
//       throw StateError("Not authenticated");
//     }
//     return {
//       "Authorization": "Bearer $token",
//     };
//   }

//   // =============================================================
//   // 1️⃣ START UPLOAD  → RETURNS file_id
//   // =============================================================

//   static Future<String> startUpload({
//     required String filename,
//     required int fileSize,
//     required int chunkSize,
//     required String securityMode, // "standard" | "zero_knowledge"
//   }) async {
//     final res = await http.post(
//       _url("/upload/file/start/"),
//       headers: {
//         ..._authHeaders(),
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "filename": filename,
//         "size": fileSize,
//         "chunk_size": chunkSize,
//         "security_mode": securityMode,
//       }),
//     );

//     if (res.statusCode != 200) {
//       debugPrint("❌ startUpload failed: ${res.body}");
//       throw StateError("startUpload failed");
//     }

//     final decoded = jsonDecode(res.body);
//     final fileId = decoded["file_id"];

//     if (fileId == null) {
//       throw StateError("Backend did not return file_id");
//     }

//     debugPrint("🆔 Upload started → file_id = $fileId");
//     return fileId as String;
//   }

//   // =============================================================
//   // 2️⃣ RESUME UPLOAD (BY file_id)
//   // =============================================================

//   static Future<Set<int>> resumeUpload(String fileId) async {
//     final res = await http.get(
//       _url("/upload/file/$fileId/resume/"),
//       headers: _authHeaders(),
//     );

//     if (res.statusCode != 200) {
//       debugPrint("⚠️ resumeUpload failed: ${res.body}");
//       return {};
//     }

//     final decoded = jsonDecode(res.body);
//     final List<dynamic> uploaded = decoded["uploaded_indices"] ?? [];

//     return uploaded.cast<int>().toSet();
//   }

//   // =============================================================
//   // 3️⃣ UPLOAD SINGLE CHUNK (ENCRYPTED)
//   // =============================================================

//   static Future<void> uploadChunk({
//     required String fileId,
//     required int chunkIndex,
//     required Uint8List cipherChunk,
//     required Uint8List nonce,
//     required Uint8List mac,
//   }) async {
//     final req = http.MultipartRequest(
//       "POST",
//       _url("/upload/file/$fileId/chunk/$chunkIndex/"),
//     );

//     req.headers.addAll(_authHeaders());

//     // 🔐 REQUIRED crypto headers
//     req.headers["X-Chunk-Nonce"] = base64Encode(nonce);
//     req.headers["X-Chunk-Mac"] = base64Encode(mac);
//     req.headers["X-Chunk-Ciphertext-Sha256"] =
//         sha256.convert(cipherChunk).toString();

//     req.files.add(
//       http.MultipartFile.fromBytes(
//         "chunk",
//         cipherChunk,
//         filename: "chunk_$chunkIndex.bin",
//       ),
//     );

//     final res = await req.send();

//     if (res.statusCode != 200) {
//       final body = await res.stream.bytesToString();
//       debugPrint("❌ uploadChunk failed: $body");
//       throw StateError("Chunk upload failed");
//     }
//   }

//   // =============================================================
//   // 4️⃣ FINISH UPLOAD (BY file_id)
//   // =============================================================

//   static Future<void> finishUpload(String fileId) async {
//     final res = await http.post(
//       _url("/upload/file/$fileId/finish/"),
//       headers: _authHeaders(),
//     );

//     if (res.statusCode != 200) {
//       debugPrint("❌ finishUpload failed: ${res.body}");
//       throw StateError("finishUpload failed");
//     }

//     debugPrint("✅ Upload complete → file_id = $fileId");
//   }
// }
// // ==================================================================================
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:http/http.dart' as http;

// import '../state/secure_state.dart';

// class UploadService {
//   static String? _isolateToken;
  
//   static get baseUrl => SecureState.serverUrl;

//   // ─────────────────────────────
//   // TOKEN HANDLING (IMPORTANT)
//   // ─────────────────────────────

//   static void setAccessTokenForIsolate(String token) {
//     _isolateToken = token;
//   }

//   static Map<String, String> _authHeaders() {
//     final token = _isolateToken ?? SecureState.accessToken;
//     if (token == null) {
//       throw StateError("Not authenticated");
//     }
//     return {
//       "Authorization": "Bearer $token",
//     };
//   }

//   static Uri _url(String path) =>
//       Uri.parse("${SecureState.serverUrl}$path");

//   // ─────────────────────────────
//   // START
//   // ─────────────────────────────

//   static Future<String> startUpload({
//     required String filename,
//     required int fileSize,
//     required int chunkSize,
//     required String securityMode,
//   }) async {
//     final res = await http.post(
//       _url("/upload/file/start/"),
//       headers: {
//         ..._authHeaders(),
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "filename": filename,
//         "size": fileSize,
//         "chunk_size": chunkSize,
//         "security_mode": securityMode,
//       }),
//     );

//     if (res.statusCode != 200) {
//       throw StateError("startUpload failed");
//     }

//     return jsonDecode(res.body)["file_id"];
//   }

//   // ─────────────────────────────
//   // RESUME (UI ISOLATE ONLY)
//   // ─────────────────────────────

//   static Future<Set<int>> resumeUpload(String fileId) async {
//     final res = await http.get(
//       _url("/upload/file/$fileId/resume/"),
//       headers: _authHeaders(),
//     );

//     if (res.statusCode != 200) return {};

//     final decoded = jsonDecode(res.body);
//     return (decoded["uploaded_indices"] as List).cast<int>().toSet();
//   }

//   // ─────────────────────────────
//   // CHUNK UPLOAD (WORKER)
//   // ─────────────────────────────

//   static Future<void> uploadChunk({
//   required String fileId,
//   required int index,
//   required Uint8List cipherChunk,
//   required Uint8List nonce,
//   required Uint8List mac,
//   required String accessToken,
// }) async {
//   final uri = Uri.parse(
//     "$baseUrl/upload/file/$fileId/chunk/$index/",
//   );

//   final request = http.MultipartRequest("POST", uri)
//     ..headers["Authorization"] = "Bearer $accessToken"
//     ..files.add(
//       http.MultipartFile.fromBytes(
//         "chunk",
//         cipherChunk,
//         filename: "chunk_$index.bin",
//       ),
//     )
//     ..fields["nonce"] = base64Encode(nonce)
//     ..fields["mac"] = base64Encode(mac);

//   final response = await request.send();

//   if (response.statusCode != 200) {
//     throw Exception("Chunk upload failed: ${response.statusCode}");
//   }
// }

//   // ─────────────────────────────
//   // FINISH
//   // ─────────────────────────────

//   static Future<void> finishUpload(String fileId) async {
//     final res = await http.post(
//       _url("/upload/file/$fileId/finish/"),
//       headers: _authHeaders(),
//     );

//     if (res.statusCode != 200) {
//       throw StateError("finishUpload failed");
//     }
//   }
// }
// // =====================================================
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class UploadService {
  static const String baseUrl = "http://10.0.2.2:8000";

  // ─────────────────────────────────────────────
  // START UPLOAD
  // ─────────────────────────────────────────────
  static Future<String> startUpload({
    required String filename,
    required int fileSize,
    required int chunkSize,
    required String securityMode,
  }) async {
    final uri = Uri.parse("$baseUrl/upload/file/start/");

    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: {
        "filename": filename,
        "size": fileSize.toString(),
        "chunk_size": chunkSize.toString(),
        "security_mode": securityMode,
      },
    );

    if (response.statusCode != 200) {
      throw Exception("startUpload failed: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return data["file_id"];
  }

  // ─────────────────────────────────────────────
  // RESUME UPLOAD
  // ─────────────────────────────────────────────
  static Future<Set<int>> resumeUpload(String fileId) async {
    final uri = Uri.parse("$baseUrl/upload/file/$fileId/resume/");

    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode != 200) {
      return {};
    }

    final data = jsonDecode(response.body);
    final List uploaded = data["uploaded_indices"] ?? [];

    return uploaded.map<int>((e) => e as int).toSet();
  }

  // ─────────────────────────────────────────────
  // ✅ CORRECT CHUNK UPLOAD (IMPORTANT)
  // ─────────────────────────────────────────────
  static Future<void> uploadChunk({
    required String fileId,
    required int index,
    required Uint8List cipherChunk,
    required Uint8List nonce,
    required Uint8List mac,
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/upload/file/$fileId/chunk/$index/",
    );

    final request = http.MultipartRequest("POST", uri);

    // 🔐 AUTH + CRYPTO HEADERS
    request.headers.addAll({
      "Authorization": "Bearer $accessToken",
      "X-Chunk-Nonce": base64Encode(nonce),
      "X-Chunk-Mac": base64Encode(mac),
    });

    // 📦 ACTUAL FILE DATA (THIS WAS MISSING BEFORE)
    request.files.add(
      http.MultipartFile.fromBytes(
        "chunk",                 // MUST be called "chunk"
        cipherChunk,
        filename: "chunk_$index.bin",
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception(
        "Chunk upload failed: ${response.statusCode} → $body",
      );
    }
  }

  // ─────────────────────────────────────────────
  // FINISH UPLOAD
  // ─────────────────────────────────────────────
  static Future<void> finishUpload(String fileId) async {
    final uri = Uri.parse("$baseUrl/upload/file/$fileId/finish/");

    final response = await http.post(uri, headers: _authHeaders());

    if (response.statusCode != 200) {
      throw Exception("finishUpload failed: ${response.body}");
    }
  }

  // ─────────────────────────────────────────────
  // AUTH HEADERS
  // ─────────────────────────────────────────────
  static Map<String, String> _authHeaders() {
    // SecureState.accessToken already validated earlier
    return {
      "Authorization": "Bearer ${_token}",
    };
  }

  // ⚠️ Inject this from SecureState in real app
  static late String _token;

  static void setAccessToken(String token) {
    _token = token;
  }
}

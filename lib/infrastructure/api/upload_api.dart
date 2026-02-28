// ============================================================================
// Upload API
//
// Responsible ONLY for HTTP transport.
// - Treats encrypted chunks as opaque bytes
// - No crypto knowledge
// - No nonce / MAC handling
// ============================================================================

// import 'dart:typed_data';
// import 'package:dio/dio.dart';

// import '../state/secure_state.dart';

// class UploadApi {
//   late final Dio _dio;

//   UploadApi({required String accessToken}) {
//     _dio = Dio(
//       BaseOptions(
//         baseUrl: SecureState.serverBaseUrl,
//         connectTimeout: const Duration(seconds: 20),
//         receiveTimeout: const Duration(seconds: 60),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//         },
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // 1️⃣ START UPLOAD
//   // ─────────────────────────────────────────────
//   Future<Map<String, dynamic>> startUpload({
//     required String filenameEnc,
//     required String filenameNonce,
//     required String filenameHash,
//     required int size,
//     required int chunkSize,
//     required String securityMode,
//   }) async {
//     final resp = await _dio.post(
//       '/upload/file/start/',
//       data: {
//         "filename_enc": filenameEnc,
//         "filename_nonce": filenameNonce,
//         "filename_hash": filenameHash,
//         "size": size,
//         "chunk_size": chunkSize,
//         "security_mode": securityMode,
//       },
//     );
//     return resp.data as Map<String, dynamic>;
//   }

//   // ─────────────────────────────────────────────
//   // 2️⃣ RESUME UPLOAD
//   // ─────────────────────────────────────────────
//   Future<Map<String, dynamic>> resumeUpload(String fileId) async {
//     final res = await _dio.get("/upload/file/$fileId/resume/");
//     if (res.statusCode != 200) {
//       throw Exception("Resume failed");
//     }
//     return res.data;
//   }


//   // ─────────────────────────────────────────────
//   // 3️⃣ SET FILENAME (ENCRYPTED)
//   // ─────────────────────────────────────────────
//   Future<void> setFilename({
//     required String fileId,
//     required String enc,
//     required String nonce,
//     required String hash,
//   }) async {
//     await _dio.post(
//       '/upload/file/$fileId/set-filename/',
//       data: {
//         "filename_enc": enc,
//         "filename_nonce": nonce,
//         "filename_hash": hash,
//       },
//     );
//   }

//   // ─────────────────────────────────────────────
//   // 4️⃣ UPLOAD ONE CHUNK (OPAQUE BYTES)
//   // ─────────────────────────────────────────────
//   Future<void> uploadChunk({
//     required String uploadId,
//     required int index,
//     required Uint8List encryptedChunk,
//     required int manifestRevision,
//   }) async {
//     await _dio.post(
//       '/upload/file/$uploadId/chunk/$index/',
//       data: encryptedChunk,
//       options: Options(
//         headers: {
//           'X-Manifest-Revision': manifestRevision.toString(),
//         },
//         contentType: 'application/octet-stream',
//         sendTimeout: const Duration(minutes: 2),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // 5️⃣ FINISH UPLOAD
//   // ─────────────────────────────────────────────
//   Future<void> finishUpload(String fileId) async {
//     await _dio.post(
//       '/upload/file/$fileId/finish/',
//     );
//   }

//   // ─────────────────────────────────────────────
//   // 6️⃣ FETCH MANIFEST
//   // ─────────────────────────────────────────────
//   Future<Map<String, dynamic>> fetchManifest(String fileId) async {
//     final resp = await _dio.get(
//       '/upload/file/$fileId/manifest/',
//     );
//     return resp.data as Map<String, dynamic>;
//   }

//   // ─────────────────────────────────────────────
//   // 7️⃣ RENAME FILE
//   // ─────────────────────────────────────────────
//   Future<void> renameFile({
//     required String fileId,
//     required String encHex,
//     required String nonceHex,
//     required String hashHex,
//   }) async {
//     await _dio.post(
//       "/upload/file/$fileId/rename/",
//       data: {
//         "filename_enc": encHex,
//         "filename_nonce": nonceHex,
//         "filename_hash": hashHex,
//       },
//     );
//   }
// }
// ========================v2===========================
// lib/api/upload_api.dart
// import 'dart:typed_data';
// import 'package:dio/dio.dart';

// import '../state/secure_state.dart';

// class UploadApi {
//   late final Dio _dio;

//   UploadApi({required String accessToken}) {
//     _dio = Dio(
//       BaseOptions(
//         baseUrl: SecureState.serverBaseUrl,
//         connectTimeout: const Duration(seconds: 20),
//         receiveTimeout: const Duration(seconds: 60),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//         },
//       ),
//     );
//   }

//   // 1️⃣ START UPLOAD
//   Future<Map<String, dynamic>> startUpload({
//     required String filename,
//     required int size,
//     required int chunkSize,
//     required String securityMode,
//   }) async {
//     final resp = await _dio.post(
//       '/upload/start/',
//       data: {
//         "filename": filename,
//         "size": size,
//         "chunk_size": chunkSize,
//         "security_mode": securityMode,
//       },
//     );

//     return resp.data as Map<String, dynamic>;
//   }

//   // 2️⃣ RESUME UPLOAD
//   Future<Map<String, dynamic>> resumeUpload(String uploadId) async {
//     final resp = await _dio.get(
//       '/upload/resume/$uploadId/',
//     );

//     return resp.data as Map<String, dynamic>;
//   }

//   // 3️⃣ UPLOAD CHUNK
//   Future<void> uploadChunk({
//     required String uploadId,
//     required int index,
//     required Uint8List encryptedChunk,
//   }) async {
//     await _dio.post(
//       '/upload/chunk/$uploadId/$index/',
//       data: encryptedChunk,
//       options: Options(
//         contentType: 'application/octet-stream',
//       ),
//     );
//   }

//   // 4️⃣ FINISH UPLOAD
//   Future<void> finishUpload(String uploadId) async {
//     await _dio.post(
//       '/upload/finish/$uploadId/',
//     );
//   }

//   // 5️⃣ LIST FILES
//   Future<List<dynamic>> listFiles() async {
//     final resp = await _dio.get('/upload/files/');
//     return resp.data as List<dynamic>;
//   }

//   // 6️⃣ FETCH MANIFEST
//   Future<Map<String, dynamic>> fetchManifest(String fileId) async {
//     final resp = await _dio.get(
//       '/upload/file/$fileId/manifest/',
//     );
//     return resp.data as Map<String, dynamic>;
//   }

//   // 7️⃣ FETCH RAW ENCRYPTED DATA
//   Future<Response> fetchEncryptedData(String fileId) async {
//     return _dio.get(
//       '/upload/file/$fileId/data/',
//       options: Options(responseType: ResponseType.bytes),
//     );
//   }

//   // 8️⃣ DELETE (SOFT DELETE)
//   Future<void> deleteUpload(String uploadId) async {
//     await _dio.delete(
//       '/upload/file/$uploadId/',
//     );
//   }

//   // 9️⃣ QUOTA
//   Future<Map<String, dynamic>> fetchQuota() async {
//     final resp = await _dio.get('/upload/quota/');
//     return resp.data as Map<String, dynamic>;
//   }
// }
// ========================v3===========================
// ============================================================================
// lib/api/upload_api.dart
//
// Single source of truth for upload-related API.
// - Encrypted filename support
// - Chunk upload
// - Streaming download support
// ============================================================================
// ============================================================================
// lib/api/upload_api.dart
// Backend-aligned version for current Django implementation
// ============================================================================

import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../state/secure_state.dart';

class UploadApi {
  late final Dio _dio;

  UploadApi({required String accessToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: SecureState.serverBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 5),
        headers: {
          "Authorization": "Bearer $accessToken",
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        responseBody: false,
      ),
    );
  }

  // ==========================================================
  // START UPLOAD
  // POST file/start/
  // ==========================================================

  Future<Map<String, dynamic>> startUpload({
    required String filenameCiphertextHex,
    required String filenameNonceHex,
    required String filenameMacHex,
    required int size,
    required String securityMode,
  }) async {
    final resp = await _dio.post(
      '/file/start/',
      data: {
        "filename_ciphertext": filenameCiphertextHex,
        "filename_nonce": filenameNonceHex,
        "filename_mac": filenameMacHex,
        "size": size,
        "security_mode": securityMode,
      },
    );

    return resp.data as Map<String, dynamic>;
  }

  // ==========================================================
  // RESUME UPLOAD
  // GET file/<uuid>/resume/
  // ==========================================================

  Future<Map<String, dynamic>> resumeUpload(String fileId) async {
    final resp = await _dio.get(
      '/file/$fileId/resume/',
    );

    return resp.data as Map<String, dynamic>;
  }

  // ==========================================================
  // UPLOAD CHUNK (MULTIPART REQUIRED)
  // POST file/<uuid>/chunk/<index>/
  // ==========================================================

  Future<void> uploadChunk({
    required String fileId,
    required int index,
    required Uint8List encryptedChunk,
  }) async {
    final formData = FormData.fromMap({
      "chunk": MultipartFile.fromBytes(
        encryptedChunk,
        filename: "chunk_$index.bin",
      ),
    });

    await _dio.post(
      '/file/$fileId/chunk/$index/',
      data: formData,
    );
  }

  // ==========================================================
  // COMMIT UPLOAD
  // POST file/<uuid>/commit/
  // ==========================================================

  Future<void> commitUpload(String fileId) async {
    await _dio.post(
      '/file/$fileId/commit/',
    );
  }

  // ==========================================================
  // LIST FILES
  // GET files/
  // ==========================================================

  Future<List<dynamic>> listFiles() async {
    final resp = await _dio.get('/files/');
    return resp.data as List<dynamic>;
  }

  // ==========================================================
  // FETCH QUOTA
  // GET quota/
  // ==========================================================

  Future<Map<String, dynamic>> fetchQuota() async {
    final resp = await _dio.get('/quota/');
    return resp.data as Map<String, dynamic>;
  }

  // ==========================================================
  // DELETE FILE (SOFT DELETE)
  // DELETE file/<uuid>/delete/
  // ==========================================================

  Future<void> deleteFile(String fileId) async {
    await _dio.delete(
      '/file/$fileId/delete/',
    );
  }


  Future<void> setFilenameMetadata({
  required String fileId,
  required String cipherHex,
  required String nonceHex,
  required String macHex,
}) async {
  await _dio.post(
    '/file/$fileId/metadata/',
    data: {
      "filename_ciphertext": cipherHex,
      "filename_nonce": nonceHex,
      "filename_mac": macHex,
    },
  );
}
}
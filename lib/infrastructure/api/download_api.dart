// ============================================================================
// Download API
//
// Responsible ONLY for downloading encrypted data.
// - Treats encrypted chunks as opaque bytes
// - No cryptographic knowledge
// - Symmetric with UploadApi
// ============================================================================

import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../state/secure_state.dart';
class DownloadApi {
  late final Dio _dio;

  DownloadApi({required String accessToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: SecureState.serverBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          "Authorization": "Bearer $accessToken",
        },
      ),
    );
  }

  // 1️⃣ Manifest (JSON)
  Future<Map<String, dynamic>> fetchManifest(String fileId) async {
    final resp = await _dio.get(
      '/download/file/$fileId/manifest/',
      options: Options(responseType: ResponseType.json),
    );

    return resp.data as Map<String, dynamic>;
  }

  // 2️⃣ Chunk (BYTES)
  Future<Uint8List> downloadChunk({
    required String fileId,
    required int index,
  }) async {
    final Response<List<int>> resp =
        await _dio.get<List<int>>(
      '/download/file/$fileId/chunk/$index/',
      options: Options(responseType: ResponseType.bytes),
    );

    if (resp.data == null) {
      throw StateError("Empty chunk response");
    }

    return Uint8List.fromList(resp.data!);
  }
}
// lib/api/upload_api.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../state/secure_state.dart';

class UploadApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: SecureState.serverUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  UploadApi({String? accessToken}) {
    if (accessToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }
  }

  // ---------------------------------------------
  // START UPLOAD
  // ---------------------------------------------
  Future<Map<String, dynamic>> startUpload({
    required String filename,
    required int size,
    required int chunkSize,
    required String securityMode,
  }) async {
    final resp = await _dio.post(
      '/upload/start/',
      data: {
        "filename": filename,
        "size": size,
        "chunk_size": chunkSize,
        "security_mode": securityMode,
      },
    );
    return resp.data;
  }

  // ---------------------------------------------
  // UPLOAD CHUNK (OPAQUE)
  // ---------------------------------------------
  Future<void> uploadChunk({
    required String uploadId,
    required int index,
    required Uint8List chunkBytes,
  }) async {
    await _dio.post(
      '/upload/chunk/$uploadId/$index/',
      data: Stream.fromIterable([chunkBytes]),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
        },
      ),
    );
  }

  // ---------------------------------------------
  // FINISH UPLOAD
  // ---------------------------------------------
  Future<void> finishUpload(String uploadId) async {
    await _dio.post('/upload/finish/$uploadId/');
  }
}

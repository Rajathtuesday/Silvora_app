// ============================================================================
// lib/services/download_service.dart
//
// Production-grade streaming download service using Dio.
// - No full-memory buffering
// - Supports large files (1GB+)
// - Uses ResponseType.stream
// ============================================================================

import 'package:dio/dio.dart';
import '../../state/secure_state.dart';

class DownloadService {
  static String get _baseUrl => SecureState.serverBaseUrl;

  static Dio _dio() {
    final dio = Dio();

    dio.options.headers = SecureState.authHeader();
    dio.options.responseType = ResponseType.json;

    return dio;
  }

  // ─────────────────────────────────────────
  // Fetch Manifest (JSON)
  // ─────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchManifest(
    String fileId,
  ) async {
    final dio = _dio();

    final res = await dio.get(
      "$_baseUrl/file/$fileId/manifest/",
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch manifest");
    }

    return Map<String, dynamic>.from(res.data);
  }

  // ─────────────────────────────────────────
  // Fetch Encrypted File as STREAM
  // ─────────────────────────────────────────
  static Future<ResponseBody> fetchEncryptedStream(
    String fileId,
  ) async {
    final dio = _dio();

    final res = await dio.get<ResponseBody>(
      "$_baseUrl/file/$fileId/data/",
      options: Options(
        responseType: ResponseType.stream,
      ),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch encrypted stream");
    }

    return res.data!;
  }
}

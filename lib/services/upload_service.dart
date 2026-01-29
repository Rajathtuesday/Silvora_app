
//=======================================================================================
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../state/secure_state.dart';

class UploadService {
  // Build upload base URL from SecureState
  static String get baseUrl =>
      "${SecureState.serverBaseUrl}/upload";

  static Map<String, String> _authHeaders() {
    final token = SecureState.accessToken;
    if (token == null) {
      throw Exception("Not authenticated");
    }
    return {"Authorization": "Bearer $token"};
  }

  static Future<String> startUpload({
    required String filename,
    required int fileSize,
    required int chunkSize,
    required String securityMode,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/file/start/"),
      headers: {
        ..._authHeaders(),
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "filename": filename,
        "size": fileSize,
        "chunk_size": chunkSize,
        "security_mode": securityMode,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("startUpload failed");
    }

    return jsonDecode(res.body)["file_id"];
  }

  static Future<Set<int>> resumeUpload(String fileId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/file/$fileId/resume/"),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200) return {};

    final list = jsonDecode(res.body)["uploaded_indices"] ?? [];
    return list.cast<int>().toSet();
  }

  static Future<void> finishUpload(String fileId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/file/$fileId/finish/"),
      headers: _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception("finishUpload failed");
    }
  }
}

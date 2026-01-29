
// ======================================================================================================
// lib/services/api_services.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../state/secure_state.dart';

class ApiService {
  // =====================================================
  // HELPERS
  // =====================================================

  static Uri _url(String path) =>
      Uri.parse("${SecureState.serverBaseUrl}$path");

  static Map<String, String> _headers() =>
      SecureState.authHeader();

  // =====================================================
  // FILE LIST
  // =====================================================

  /// Returns ONLY a list of files
  /// Each item is a Map<String, dynamic>
  static Future<List<Map<String, dynamic>>> listFiles() async {
    final res = await http.get(
      _url("/upload/files/"),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to list files");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      throw Exception("Invalid file list response");
    }

    return decoded.cast<Map<String, dynamic>>();
  }

  // =====================================================
  // FILE MANIFEST
  // =====================================================

  static Future<Map<String, dynamic>> fetchManifest(
    String fileId,
  ) async {
    final res = await http.get(
      _url("/upload/file/$fileId/manifest/"),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Manifest fetch failed");
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // =====================================================
  // ENCRYPTED FILE DATA
  // =====================================================

  static Future<Uint8List> fetchEncryptedData(
    String fileId,
  ) async {
    final res = await http.get(
      _url("/upload/file/$fileId/data/"),
      headers: {
        ..._headers(),
        "Accept": "application/octet-stream",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Encrypted data fetch failed");
    }

    return res.bodyBytes;
  }

  // =====================================================
  // DELETE (MOVE TO TRASH)
  // =====================================================

  static Future<void> deleteFile(String fileId) async {
    final res = await http.delete(
      _url("/upload/file/$fileId/delete/"),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed");
    }
  }

  // =====================================================
  // TRASH
  // =====================================================

  static Future<List<Map<String, dynamic>>> listTrash() async {
    final res = await http.get(
      _url("/upload/trash/"),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to list trash");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      throw Exception("Invalid trash response");
    }

    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> restoreFile(String fileId) async {
    final res = await http.post(
      _url("/upload/file/$fileId/restore/"),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Restore failed");
    }
  }
}
// ======================================================================================================
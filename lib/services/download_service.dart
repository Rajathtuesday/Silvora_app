
// ======================================================================================================
// lib/services/download_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/secure_state.dart';

class DownloadService {
  static String get _baseUrl => SecureState.serverBaseUrl;

  static Uri _url(String path) => Uri.parse("$_baseUrl$path");

  static Map<String, String> _headers() =>
      SecureState.authHeader();

  // 1️⃣ Fetch manifest
  static Future<Map<String, dynamic>> fetchManifest(
    String fileId,
  ) async {
    final res = await http.get(
      _url("/upload/file/$fileId/manifest/"),
      headers: _headers(),
    );

    debugPrint("Manifest Status =${res.statusCode}");
    debugPrint("manifest body ${res.body}");
    if (res.statusCode != 200) {
      throw Exception("Failed to fetch manifest");
    }

    return jsonDecode(res.body);
  }

  // 2️⃣ Fetch encrypted file bytes
  static Future<Uint8List> fetchEncryptedData(
    String fileId,
  ) async {
    final res = await http.get(
      _url("/upload/file/$fileId/data/"),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch encrypted file");
    }

    return res.bodyBytes;
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'auth_client.dart';
import 'package:cryptography/cryptography.dart';

import '../state/secure_state.dart';
import '../crypto/hkdf.dart';

class ApiService {
  static Uri _url(String path) => Uri.parse("${SecureState.serverUrl}$path");

  static Uint8List _hexToBytes(String hex) {
    hex = hex.trim();
    if (hex.length % 2 != 0) throw ArgumentError("Hex mismatch");
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  // ===============================
  // LIST FILES
  // ===============================
  static Future<List<dynamic>> listFiles() async {
    final res = await AuthClient.get(
      _url("/files/"),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to list files");
    }

    final List<dynamic> rawFiles = jsonDecode(res.body);
    final algo = Xchacha20.poly1305Aead();

    for (var f in rawFiles) {
      if (f["filename_ciphertext"] != null) {
        try {
          final fileId = f["file_id"];
          final nameKeyBytes = await hkdfSha256(
            ikm: SecureState.masterKey,
            info: utf8.encode("silvora_filename_$fileId"),
          );

          final box = SecretBox(
            _hexToBytes(f["filename_ciphertext"]),
            nonce: _hexToBytes(f["filename_nonce"]),
            mac: Mac(_hexToBytes(f["filename_mac"])),
          );

          final plainBytes = await algo.decrypt(
            box,
            secretKey: SecretKey(nameKeyBytes),
          );
          
          f["filename"] = utf8.decode(plainBytes);
        } catch (e) {
          debugPrint("Filename decrypt failed for ${f['file_id']}: $e");
          f["filename"] = "Encrypted Vault File";
        }
      } else {
        f["filename"] = f["filename"] ?? "Unknown Format";
      }
    }

    return rawFiles;
  }

  // ===============================
  // STORAGE QUOTA (this user's usage)
  // ===============================
  static Future<Map<String, int>> getQuota() async {
    final res = await AuthClient.get(_url("/quota/"));
    if (res.statusCode != 200) {
      throw Exception("Failed to fetch quota");
    }
    final data = jsonDecode(res.body);
    return {
      "used": (data["used_bytes"] as num).toInt(),
      "limit": (data["limit_bytes"] as num).toInt(),
    };
  }

  // ===============================
  // DELETE FILE (TRASH)
  // ===============================
  static Future<void> deleteFile(String fileId) async {
    final res = await AuthClient.delete(
      _url("/file/$fileId/delete/"),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to push file to trash");
    }
  }

  // ===============================
  // LIST TRASH
  // ===============================
  static Future<List<dynamic>> listTrash() async {
    final res = await AuthClient.get(
      _url("/trash/"),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch trash");
    }

    final List<dynamic> rawFiles = jsonDecode(res.body);
    final algo = Xchacha20.poly1305Aead();

    for (var f in rawFiles) {
      if (f["filename_ciphertext"] != null) {
        try {
          final nameKeyBytes = await hkdfSha256(
            ikm: SecureState.masterKey,
            info: utf8.encode("silvora_filename_${f["file_id"]}"),
          );
          final box = SecretBox(
            _hexToBytes(f["filename_ciphertext"]),
            nonce: _hexToBytes(f["filename_nonce"]),
            mac: Mac(_hexToBytes(f["filename_mac"])),
          );
          final plain = await algo.decrypt(box, secretKey: SecretKey(nameKeyBytes));
          f["filename"] = utf8.decode(plain);
        } catch (e) {
          debugPrint("Filename decrypt failed in trash for ${f['file_id']}: $e");
          f["filename"] = "Encrypted File";
        }
      }
    }
    return rawFiles;
  }

  // ===============================
  // RESTORE FILE FROM TRASH
  // ===============================
  static Future<void> restoreFile(String fileId) async {
    final res = await AuthClient.post(
      _url("/file/$fileId/restore/"),
    );
    if (res.statusCode != 200) {
      throw Exception("Restore failed (HTTP ${res.statusCode})");
    }
  }

  // ===============================
  // PERMANENTLY DELETE (purge now)
  // ===============================
  static Future<void> permanentlyDeleteFile(String fileId) async {
    final res = await AuthClient.delete(
      _url("/file/$fileId/delete/"),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception("Permanent delete failed (HTTP ${res.statusCode})");
    }
  }
}

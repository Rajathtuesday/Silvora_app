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
  static Future<Map<String, dynamic>> getQuota() async {
    final res = await AuthClient.get(_url("/quota/"));
    if (res.statusCode != 200) {
      throw Exception("Failed to fetch quota");
    }
    final data = jsonDecode(res.body);
    return {
      "used": (data["used_bytes"] as num).toInt(),
      "limit": (data["limit_bytes"] as num).toInt(),
      "tier": data["tier"] as String?,
      // Both null unless a cancelled subscription is mid-grace-period.
      "graceEndsAt": data["grace_ends_at"] != null ? DateTime.parse(data["grace_ends_at"]) : null,
      "purgeAt": data["purge_at"] != null ? DateTime.parse(data["purge_at"]) : null,
    };
  }

  // ===============================
  // RENAME FILE
  // ===============================
  // Re-encrypts the filename under the exact same per-file key used at
  // upload time (derived from file_id, via listFiles' same scheme) and
  // sends the new ciphertext — the server only ever sees opaque bytes,
  // same zero-knowledge guarantee as upload.
  static Future<void> renameFile(String fileId, String newFilename) async {
    final nameKeyBytes = await hkdfSha256(
      ikm: SecureState.masterKey,
      info: utf8.encode("silvora_filename_$fileId"),
    );

    final algo = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(nameKeyBytes);
    final nonce = await algo.newNonce();

    final box = await algo.encrypt(
      utf8.encode(newFilename),
      secretKey: secretKey,
      nonce: nonce,
    );

    final res = await AuthClient.post(
      _url("/file/$fileId/rename/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "filename_ciphertext": _bytesToHex(box.cipherText),
        "filename_nonce": _bytesToHex(nonce),
        "filename_mac": _bytesToHex(box.mac.bytes),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to rename file");
    }
  }

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  // ===============================
  // CURRENT USER PROFILE (email verification state)
  // ===============================
  static Future<void> fetchCurrentUser() async {
    final res = await AuthClient.get(_url("/api/auth/me/"));
    if (res.statusCode != 200) {
      // Non-blocking by design — a failed fetch here must never block
      // login/unlock. Leave SecureState's profile fields at their defaults
      // and let the next successful fetch (e.g. next app open) catch up.
      return;
    }
    final data = jsonDecode(res.body);
    SecureState.userEmail = data["email"] as String?;
    SecureState.emailVerified = data["email_verified"] == true;
  }

  // ===============================
  // EMAIL VERIFICATION — resend
  // ===============================
  /// Returns a user-facing message from the backend response (success or
  /// error) — the backend already returns friendly text, no need to invent
  /// new copy here.
  static Future<String> resendVerificationEmail() async {
    final res = await AuthClient.post(_url("/api/auth/resend-verification/"));
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      return data["error"] as String? ?? "Could not send verification email.";
    }
    if (data["status"] == "already_verified") {
      return "Your email is already verified.";
    }
    return "Verification email sent — check your inbox.";
  }

  // ===============================
  // BILLING — create a subscription
  // ===============================
  /// tier: "pro" | "enterprise". interval: "monthly" | "yearly".
  /// Returns {subscription_id, razorpay_key_id} for the checkout SDK — the
  /// actual tier upgrade happens server-side via Razorpay's webhook, not
  /// from this response.
  static Future<Map<String, String>> createSubscription(String tier, String interval) async {
    final res = await AuthClient.post(
      _url("/api/billing/subscribe/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"tier": tier, "interval": interval}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) {
      throw Exception(data["error"] as String? ?? "Could not start subscription.");
    }
    return {
      "subscription_id": data["subscription_id"] as String,
      "razorpay_key_id": data["razorpay_key_id"] as String,
    };
  }

  // ===============================
  // ACCOUNT DELETION
  // ===============================
  static Future<void> deleteAccount(String password) async {
    final res = await AuthClient.post(
      _url("/api/auth/account/delete/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"password": password}),
    );

    if (res.statusCode != 200) {
      String message = "Failed to delete account";
      try {
        final data = jsonDecode(res.body);
        if (data["error"] != null) message = data["error"];
      } catch (_) {}
      throw Exception(message);
    }
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

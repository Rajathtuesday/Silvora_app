
//==================================
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UploadRetryStore {
  static const String _keyData = 'upload_retry_data';
  static const String _keyAutoTried = 'upload_retry_auto_tried';

  // ─────────────────────────────────────────────
  // SAVE RETRY STATE
  // ─────────────────────────────────────────────
  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyData, jsonEncode(data));
    await prefs.setBool(_keyAutoTried, false);
  }

  // ─────────────────────────────────────────────
  // CHECKS
  // ─────────────────────────────────────────────

  /// Is there any pending upload data?
  static Future<bool> hasPendingUpload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyData);
  }

  /// Was auto-resume already attempted?
  static Future<bool> wasAutoResumeTried() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoTried) ?? false;
  }

  // ─────────────────────────────────────────────
  // STATE MUTATIONS
  // ─────────────────────────────────────────────

  static Future<void> markAutoResumeTried() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoTried, true);
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyData);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyData);
    await prefs.remove(_keyAutoTried);
  }
}
// ─────────────────────────────────────────────
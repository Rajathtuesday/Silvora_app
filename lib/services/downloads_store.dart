import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One entry in the on-device download library.
class DownloadedItem {
  final String filename;
  final String path; // app-private persistent path
  final String mime;
  final int size;
  final DateTime savedAt;

  DownloadedItem({
    required this.filename,
    required this.path,
    required this.mime,
    required this.size,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        "filename": filename,
        "path": path,
        "mime": mime,
        "size": size,
        "savedAt": savedAt.toIso8601String(),
      };

  factory DownloadedItem.fromJson(Map<String, dynamic> j) => DownloadedItem(
        filename: j["filename"] as String,
        path: j["path"] as String,
        mime: j["mime"] as String,
        size: (j["size"] as num).toInt(),
        savedAt: DateTime.tryParse(j["savedAt"] as String? ?? "") ?? DateTime.now(),
      );
}

/// Persistent, in-app "Downloads" library — the WhatsApp-style list of files the
/// user has pulled out of the vault. Decrypted bytes live in an app-private
/// folder (still off the public gallery); the user can open, share, or push a
/// copy to the public Downloads folder on demand.
class DownloadsStore {
  static const _indexKey = "silvora_downloads_index";
  static const _channel = MethodChannel("silvora/mediastore");
  static const _dirName = "Silvora Downloads";

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory("${base.path}/$_dirName");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── Index (SharedPreferences) ───────────────────────────────────────────
  static Future<List<DownloadedItem>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded
        .map((e) => DownloadedItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((it) => File(it.path).existsSync()) // drop entries whose file is gone
        .toList();
    // Newest first.
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  static Future<void> _saveIndex(List<DownloadedItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_indexKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static String _dedupe(String name, Set<String> taken) {
    if (!taken.contains(name)) return name;
    final dot = name.lastIndexOf('.');
    final stem = dot == -1 ? name : name.substring(0, dot);
    final ext = dot == -1 ? '' : name.substring(dot);
    var n = 1;
    while (taken.contains("$stem ($n)$ext")) {
      n++;
    }
    return "$stem ($n)$ext";
  }

  /// Copy a decrypted file into the persistent library and record it. Returns
  /// the new item.
  static Future<DownloadedItem> add({
    required File source,
    required String filename,
    required String mime,
  }) async {
    final dir = await _dir();
    final items = await list();
    final taken = items.map((e) => e.filename).toSet();
    final safeName = _dedupe(filename, taken);

    final dest = File("${dir.path}/$safeName");
    await source.copy(dest.path);

    final item = DownloadedItem(
      filename: safeName,
      path: dest.path,
      mime: mime,
      size: await dest.length(),
      savedAt: DateTime.now(),
    );

    await _saveIndex([item, ...items]);
    return item;
  }

  static Future<void> delete(DownloadedItem item) async {
    final f = File(item.path);
    if (await f.exists()) await f.delete();
    final items = await list();
    items.removeWhere((e) => e.path == item.path);
    await _saveIndex(items);
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  static Future<OpenResult> open(DownloadedItem item) =>
      OpenFilex.open(item.path, type: item.mime);

  static Future<void> share(DownloadedItem item) async {
    await Share.shareXFiles([XFile(item.path, mimeType: item.mime)]);
  }

  /// Push a copy into the public Downloads/Silvora folder (visible in Files /
  /// Gallery). Returns a human-readable location.
  static Future<String> saveToPhone(DownloadedItem item) async {
    final bytes = await File(item.path).readAsBytes();
    final res = await _channel.invokeMethod<String>("saveToDownloads", {
      "bytes": Uint8List.fromList(bytes),
      "filename": item.filename,
      "mime": item.mime,
    });
    return res ?? "Downloads/Silvora";
  }
}

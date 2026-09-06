import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, per file, the highest integrity-manifest version this device
/// has ever seen for that file -- the client-side half of rollback/replay
/// protection for the integrity manifest (see IntegrityService).
///
/// ASSUMED SHAPE, NOT YET BACKEND-CONFIRMED (2026-09-06): this assumes the
/// client-signed integrity manifest carries an integer `version` field that
/// is meant to increase every time a file's content is committed, and that a
/// download whose manifest reports a version lower than one already seen for
/// that file means the server rolled the file back to an older, still
/// validly-signed state. A backend change is being designed in parallel
/// (silvora_backend) to expose a real, server-authoritative version number
/// for this same purpose; once that lands, whatever it actually calls the
/// field and however it computes it needs to be reconciled with the `version`
/// read in IntegrityService.fetch()/buildAndUpload() -- this store itself
/// (an opaque fileId -> int map) does not need to change either way.
///
/// Known, honest limitation: this is trust-on-first-use, the same model SSH
/// host keys and Signal safety numbers use, not a globally-verified
/// guarantee. A fresh install or a different device has no memory of prior
/// versions and will silently accept whatever version the server first
/// offers it for a given file. It still closes a real gap for the common
/// case: a device that has already seen a file's current state will now
/// detect and refuse a later attempt to quietly roll that file back to an
/// older, validly-signed snapshot.
class IntegrityVersionStore {
  static const _prefsKey = "silvora_integrity_last_seen_version";

  static Future<Map<String, int>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      // Corrupt local cache -- treat as empty rather than crash. Worst case,
      // this device re-establishes its baseline on the next fetch/upload.
      return {};
    }
  }

  static Future<void> _writeAll(Map<String, int> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(all));
  }

  /// The highest version this device has recorded for [fileId], or null if
  /// this device has never seen a manifest for this file before (first
  /// download/upload ever on this device, or the local cache was cleared).
  static Future<int?> getLastSeen(String fileId) async {
    final all = await _readAll();
    return all[fileId];
  }

  /// Records [version] as seen for [fileId] -- but only ever moves the
  /// stored value forward, never backward, so a single successful rollback
  /// response can't poison the baseline downward for the next check.
  static Future<void> recordSeen(String fileId, int version) async {
    final all = await _readAll();
    final current = all[fileId];
    if (current == null || version > current) {
      all[fileId] = version;
      await _writeAll(all);
    }
  }

  /// Forgets the recorded version for [fileId]. File IDs are UUIDs and are
  /// never reused by a new upload, so this is purely hygiene (keeps the
  /// store from growing forever) -- call it when a file is permanently
  /// erased.
  static Future<void> forget(String fileId) async {
    final all = await _readAll();
    if (all.remove(fileId) != null) {
      await _writeAll(all);
    }
  }
}

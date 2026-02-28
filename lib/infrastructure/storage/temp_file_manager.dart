import 'dart:io';

class TempFileManager {
  static const String _prefix = "silvora_";
  static const String _suffix = ".tmp";

  // ─────────────────────────────────────────
  // Create a temp file path
  // ─────────────────────────────────────────

  static Future<File> createTempFile(String fileId) async {
    final dir = Directory.systemTemp;

    final file = File(
      "${dir.path}/$_prefix$fileId$_suffix",
    );

    if (file.existsSync()) {
      await file.delete();
    }

    return file;
  }

  // ─────────────────────────────────────────
  // Delete single temp file
  // ─────────────────────────────────────────

  static Future<void> deleteTempFile(String fileId) async {
    final file = File(
      "${Directory.systemTemp.path}/$_prefix$fileId$_suffix",
    );

    if (file.existsSync()) {
      await file.delete();
    }
  }

  // ─────────────────────────────────────────
  // Clean ALL silvora temp files
  // ─────────────────────────────────────────

  static Future<void> cleanAll() async {
    final dir = Directory.systemTemp;

    if (!dir.existsSync()) return;

    final files = dir.listSync();

    for (final entity in files) {
      if (entity is File) {
        final name = entity.path.split(Platform.pathSeparator).last;

        if (name.startsWith(_prefix) &&
            name.endsWith(_suffix)) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }
}

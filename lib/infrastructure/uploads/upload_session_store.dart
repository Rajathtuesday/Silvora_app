// ==========================================================
// lib/uploads/upload_session_store.dart
// Crash-safe resumable upload session persistence
// ==========================================================

import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class UploadSessionStore {
  static const _dbName = 'upload_sessions.db';
  static const _table = 'sessions';

  static Database? _db;

  // ─────────────────────────────────────────────
  // DB OPEN (VERSION 2 — adds file_path + file_size)
  // ─────────────────────────────────────────────

  static Future<Database> _open() async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      path,
      version: 2, // ⬅️ IMPORTANT (was 1)
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            file_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            chunk_size INTEGER NOT NULL,
            total_chunks INTEGER NOT NULL,
            uploaded_chunks TEXT NOT NULL,
            manifest_revision INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE $_table ADD COLUMN file_path TEXT NOT NULL DEFAULT ''");
          await db.execute(
              "ALTER TABLE $_table ADD COLUMN file_size INTEGER NOT NULL DEFAULT 0");
        }
      },
    );

    return _db!;
  }

  // ─────────────────────────────────────────────
  // SAVE (UPSERT)
  // ─────────────────────────────────────────────

  static Future<void> save({
    required String fileId,
    required String filePath,
    required int fileSize,
    required int chunkSize,
    required int totalChunks,
    required Set<int> uploadedChunks,
    required int manifestRevision,
  }) async {
    final db = await _open();

    await db.insert(
      _table,
      {
        'file_id': fileId,
        'file_path': filePath,
        'file_size': fileSize,
        'chunk_size': chunkSize,
        'total_chunks': totalChunks,
        'uploaded_chunks': jsonEncode(uploadedChunks.toList()),
        'manifest_revision': manifestRevision,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────
  // LOAD BY FILE ID
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>?> load(String fileId) async {
    final db = await _open();

    final rows = await db.query(
      _table,
      where: 'file_id = ?',
      whereArgs: [fileId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _deserialize(rows.first);
  }

  // ─────────────────────────────────────────────
  // LOAD MOST RECENT SESSION
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>?> loadAny() async {
    final db = await _open();

    final rows = await db.query(
      _table,
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _deserialize(rows.first);
  }

  // ─────────────────────────────────────────────
  // DELETE ONE SESSION
  // ─────────────────────────────────────────────

  static Future<void> delete(String fileId) async {
    final db = await _open();
    await db.delete(
      _table,
      where: 'file_id = ?',
      whereArgs: [fileId],
    );
  }

  // ─────────────────────────────────────────────
  // CLEAR ALL SESSIONS
  // ─────────────────────────────────────────────

  static Future<void> clearAll() async {
    final db = await _open();
    await db.delete(_table);
  }

  // ─────────────────────────────────────────────
  // INTERNAL DESERIALIZER
  // ─────────────────────────────────────────────

  static Map<String, dynamic> _deserialize(Map<String, Object?> row) {
    return {
      'file_id': row['file_id'] as String,
      'file_path': row['file_path'] as String,
      'file_size': row['file_size'] as int,
      'chunk_size': row['chunk_size'] as int,
      'total_chunks': row['total_chunks'] as int,
      'uploaded_chunks': Set<int>.from(
        jsonDecode(row['uploaded_chunks'] as String),
      ),
      'manifest_revision': row['manifest_revision'] as int,
    };
  }
}

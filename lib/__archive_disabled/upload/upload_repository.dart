// // lib/upload/upload_repository.dart

// import 'dart:async';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';

// import 'upload_job.dart';
// import 'upload_state.dart';

// class UploadRepository {
//   static const _dbName = 'uploads.db';
//   static const _dbVersion = 1;

//   static final UploadRepository _instance =
//       UploadRepository._internal();

//   factory UploadRepository() => _instance;

//   UploadRepository._internal();

//   Database? _db;

//   // ─────────────────────────────────────────────
//   // DB INIT
//   // ─────────────────────────────────────────────
//   Future<Database> _getDb() async {
//     if (_db != null) return _db!;

//     final path = join(await getDatabasesPath(), _dbName);

//     _db = await openDatabase(
//       path,
//       version: _dbVersion,
//       onCreate: (db, _) async {
//         await db.execute('''
//         CREATE TABLE upload_jobs (
//           job_id TEXT PRIMARY KEY,
//           upload_id TEXT,
//           file_path TEXT NOT NULL,
//           filename TEXT NOT NULL,
//           file_size INTEGER NOT NULL,
//           chunk_size INTEGER NOT NULL,
//           security_mode TEXT NOT NULL,
//           crypto_version INTEGER NOT NULL,
//           vault_fingerprint TEXT NOT NULL,
//           file_salt_b64 TEXT NOT NULL,
//           total_chunks INTEGER NOT NULL,
//           uploaded_chunks TEXT NOT NULL,
//           state TEXT NOT NULL,
//           pause_reason TEXT,
//           last_error TEXT,
//           created_at TEXT NOT NULL,
//           updated_at TEXT NOT NULL
//         )
//         ''');
//       },
//     );

//     return _db!;
//   }

//   // ─────────────────────────────────────────────
//   // CRUD
//   // ─────────────────────────────────────────────

//   Future<void> insertJob(UploadJob job) async {
//     final db = await _getDb();
//     await db.insert(
//       'upload_jobs',
//       job.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.abort,
//     );
//   }

//   Future<void> updateJob(UploadJob job) async {
//     final db = await _getDb();
//     await db.update(
//       'upload_jobs',
//       job.toMap(),
//       where: 'job_id = ?',
//       whereArgs: [job.jobId],
//     );
//   }

//   Future<UploadJob?> getJob(String jobId) async {
//     final db = await _getDb();
//     final rows = await db.query(
//       'upload_jobs',
//       where: 'job_id = ?',
//       whereArgs: [jobId],
//       limit: 1,
//     );

//     if (rows.isEmpty) return null;
//     return UploadJob.fromMap(rows.first);
//   }

//   Future<List<UploadJob>> getActiveJobs() async {
//     final db = await _getDb();
//     final rows = await db.query(
//       'upload_jobs',
//       where: 'state NOT IN (?, ?)',
//       whereArgs: [
//         UploadState.completed.name,
//         UploadState.failed.name,
//       ],
//     );

//     return rows.map(UploadJob.fromMap).toList();
//   }

//   Future<void> deleteJob(String jobId) async {
//     final db = await _getDb();
//     await db.delete(
//       'upload_jobs',
//       where: 'job_id = ?',
//       whereArgs: [jobId],
//     );
//   }
// }

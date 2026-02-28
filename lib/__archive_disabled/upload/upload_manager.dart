// // lib/upload/upload_manager.dart

// import 'dart:async';
// import 'dart:isolate';

// import '../state/secure_state.dart';
// import '../services/upload_worker.dart';
// import 'upload_repository.dart';
// import 'upload_job.dart';
// import 'upload_state.dart';

// typedef ResumePrompt = Future<bool> Function(UploadJob job);

// class UploadManager {
//   static final UploadManager _instance =
//       UploadManager._internal();

//   factory UploadManager() => _instance;

//   UploadManager._internal();

//   final UploadRepository _repo = UploadRepository();

//   UploadJob? _activeJob;
//   bool _workerRunning = false;

//   ResumePrompt? _resumePrompt;

//   /// UI registers this
//   void registerResumePrompt(ResumePrompt prompt) {
//     _resumePrompt = prompt;
//   }

//   // ─────────────────────────────────────────────
//   // STARTUP
//   // ─────────────────────────────────────────────
//   Future<void> restoreOnAppStart() async {
//     final jobs = await _repo.getActiveJobs();
//     if (jobs.isEmpty) return;

//     // Single upload enforced
//     _activeJob = jobs.first;
//   }

//   // ─────────────────────────────────────────────
//   // START UPLOAD
//   // ─────────────────────────────────────────────
//   Future<void> start(UploadJob job) async {
//     if (_activeJob != null) {
//       throw StateError("Another upload already running");
//     }

//     _activeJob = job;
//     await _repo.insertJob(job);

//     await _runWorker(job, retryAllowed: true);
//   }

//   // ─────────────────────────────────────────────
//   // WORKER EXECUTION
//   // ─────────────────────────────────────────────
//   Future<void> _runWorker(
//     UploadJob job, {
//     required bool retryAllowed,
//   }) async {
//     if (_workerRunning) return;
//     _workerRunning = true;

//     final receivePort = ReceivePort();

//     receivePort.listen((msg) async {
//       if (msg is int) {
//         // chunk uploaded
//         final updated = job.copyWith(
//           uploadedChunks: {...job.uploadedChunks, msg},
//           state: UploadState.running,
//         );
//         _activeJob = updated;
//         await _repo.updateJob(updated);
//         return;
//       }

//       if (msg == 'DONE') {
//         final finished = job.copyWith(
//           state: UploadState.completed,
//         );
//         await _repo.updateJob(finished);
//         _cleanup();
//         return;
//       }

//       if (msg is Map && msg['type'] == 'ERROR') {
//         await _handleWorkerError(job, retryAllowed);
//       }
//     });

//     try {
//       await Isolate.spawn(
//         uploadWorkerEntry,
//         [
//           job, // UploadJob snapshot
//           SecureState.accessToken!,
//           receivePort.sendPort,
//         ],
//       );
//     } catch (_) {
//       await _handleWorkerError(job, retryAllowed);
//     }
//   }

//   // ─────────────────────────────────────────────
//   // ERROR HANDLING
//   // ─────────────────────────────────────────────
//   Future<void> _handleWorkerError(
//     UploadJob job,
//     bool retryAllowed,
//   ) async {
//     _workerRunning = false;

//     if (retryAllowed) {
//       // One silent retry (network hiccup)
//       await _runWorker(job, retryAllowed: false);
//       return;
//     }

//     // Ask user
//     if (_resumePrompt == null) return;

//     final shouldResume = await _resumePrompt!(job);

//     if (shouldResume) {
//       final resumed = job.copyWith(
//         state: UploadState.resuming,
//         pauseReason: null,
//       );
//       await _repo.updateJob(resumed);
//       await _runWorker(resumed, retryAllowed: false);
//     } else {
//       final paused = job.copyWith(
//         state: UploadState.paused,
//         pauseReason: UploadPauseReason.networkLost,
//       );
//       await _repo.updateJob(paused);
//       _cleanup();
//     }
//   }

//   // ─────────────────────────────────────────────
//   // AUTH / VAULT EVENTS
//   // ─────────────────────────────────────────────
//   Future<void> onAuthLost() async {
//     if (_activeJob == null) return;

//     final paused = _activeJob!.copyWith(
//       state: UploadState.paused,
//       pauseReason: UploadPauseReason.authRequired,
//     );
//     await _repo.updateJob(paused);
//     _cleanup();
//   }

//   Future<void> onVaultLocked() async {
//     if (_activeJob == null) return;

//     final paused = _activeJob!.copyWith(
//       state: UploadState.paused,
//       pauseReason: UploadPauseReason.vaultLocked,
//     );
//     await _repo.updateJob(paused);
//     _cleanup();
//   }

//   // ─────────────────────────────────────────────
//   // CLEANUP
//   // ─────────────────────────────────────────────
//   void _cleanup() {
//     _workerRunning = false;
//     _activeJob = null;
//   }
// }

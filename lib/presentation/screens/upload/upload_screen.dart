// //==========================================================
// // lib/screens/upload/upload_screen.dart
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import '../../api/upload_api.dart';
// import '../../uploads/upload_manager.dart';
// import '../../uploads/upload_session.dart';
// import '../../crypto/file_key.dart';
// import '../../crypto/filename_crypto.dart';
// import '../../state/secure_state.dart';

// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';

// enum UploadState {
//   idle,
//   fileSelected,
//   starting,
//   uploading,
//   finishing,
//   error,
// }

// class SilvoraColors {
//   static const Color accent = Color(0xFF9255E8);
//   static const Color background = Colors.black;
//   static const Color surface = Color(0xFF121212);
// }

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   UploadState _state = UploadState.idle;
//   double _progress = 0.0;

//   static const int chunkSize = 2 * 1024 * 1024;

//   // ───────────────── FILE PICK ─────────────────

//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _state = UploadState.fileSelected;
//     });

//     HapticFeedback.selectionClick();
//   }

//   // ───────────────── UPLOAD FLOW (OPTION A) ─────────────────

//   Future<void> _startUpload() async {
//     if (_file == null) return;

//     final token = SecureState.accessToken;
//     if (token == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     final Uint8List masterKey = SecureState.requireMasterKey();
//     final String filename = _file!.path.split('/').last;
//     final int fileSize = await _file!.length();

//     final api = UploadApi(accessToken: token);
//     final manager = UploadManager(api);

//     setState(() => _state = UploadState.starting);

//     // 1️⃣ START UPLOAD (NO FILENAME YET)
//     final UploadSession session = await manager.start(
//       filenameEnc: "00",     // placeholder
//       filenameNonce: "00",
//       filenameHash: "00",
//       fileSize: fileSize,
//       chunkSize: chunkSize,
//       securityMode: "zero_knowledge",
//     );

//     final String fileId = session.fileId;

//     // 2️⃣ DERIVE FILE KEY FROM file_id (CRITICAL)
//     final Uint8List fileKey = await deriveFileKey(
//       masterKey: masterKey,
//       fileId: fileId,
//     );

//     // 3️⃣ ENCRYPT FILENAME
//     final encrypted = await FilenameCrypto.encrypt(
//       filename: filename,
//       fileKey: fileKey,
//     );

//     // 4️⃣ SET ENCRYPTED FILENAME (OPTION A CORE)
//     await api.setFilename(
//       fileId: fileId,
//       enc: encrypted.encHex,
//       nonce: encrypted.nonceHex,
//       hash: encrypted.hashHex,
//     );

//     // 5️⃣ UPLOAD CHUNKS
//     setState(() => _state = UploadState.uploading);

//     int sentBytes = 0;

//     while (!session.isComplete) {
//       final index = session.nextChunkToUpload();
//       if (index == null) break;

//       await manager.uploadOneChunk(
//         session: session,
//         index: index,
//         file: _file!,
//         fileKey: fileKey,
//       );

//       final int size = (index == session.totalChunks - 1)
//           ? fileSize - index * chunkSize
//           : chunkSize;

//       sentBytes += size;

//       setState(() {
//         _progress = sentBytes / fileSize;
//       });
//     }

//     // 6️⃣ FINISH
//     setState(() => _state = UploadState.finishing);
//     await manager.finish(session);

//     if (!mounted) return;

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const FileListScreen()),
//     );
//   }

//   // ───────────────── UI ─────────────────

//   @override
//   Widget build(BuildContext context) {
//     final uploading =
//         _state == UploadState.uploading ||
//         _state == UploadState.finishing;

//     return Scaffold(
//       backgroundColor: SilvoraColors.background,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text("Secure Upload"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             if (uploading) ...[
//               LinearProgressIndicator(
//                 value: _progress,
//                 color: SilvoraColors.accent,
//                 backgroundColor: Colors.white12,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "${(_progress * 100).round()}%",
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ] else ...[
//               const Spacer(),
//               _uploadButton(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() => Card(
//         color: SilvoraColors.surface,
//         child: ListTile(
//           leading:
//               const Icon(Icons.lock_outline, color: SilvoraColors.accent),
//           title: Text(
//             _file == null
//                 ? "Choose a file"
//                 : _file!.path.split('/').last,
//             style: const TextStyle(color: Colors.white),
//           ),
//           onTap: _pickFile,
//         ),
//       );

//   Widget _uploadButton() => SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: SilvoraColors.accent,
//             padding: const EdgeInsets.symmetric(vertical: 14),
//           ),
//           onPressed:
//               _state == UploadState.fileSelected ? _startUpload : null,
//           child: const Text("Upload securely"),
//         ),
//       );
// }
// //==========================================================v4
// // ==========================================================
// // lib/screens/upload/upload_screen.dart
// // ==========================================================
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import '../../api/upload_api.dart';
// import '../../uploads/upload_manager.dart';
// import '../../uploads/upload_session.dart';
// import '../../uploads/upload_session_store.dart';
// import '../../crypto/file_key.dart';
// import '../../crypto/filename_crypto.dart';
// import '../../state/secure_state.dart';

// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';

// enum UploadState {
//   idle,
//   fileSelected,
//   starting,
//   uploading,
//   finishing,
//   error,
// }

// class SilvoraColors {
//   static const Color accent = Color(0xFF9255E8);
//   static const Color background = Colors.black;
//   static const Color surface = Color(0xFF121212);
// }

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   UploadSession? _session;

//   UploadState _state = UploadState.idle;
//   double _progress = 0.0;
//   String _statusText = "";

//   static const int chunkSize = 2 * 1024 * 1024;

//   // ───────────────── INIT ─────────────────

//   @override
//   void initState() {
//     super.initState();
//     _checkForResume();
//   }

//   // ───────────────── RESUME CHECK ─────────────────

//   Future<void> _checkForResume() async {
//     final existing = await UploadSessionStore.loadAny();
//     if (existing == null) return;

//     final resume = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Resume upload?"),
//         content: const Text(
//           "An unfinished secure upload was found.\n\n"
//           "Do you want to continue where you left off?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Discard"),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Resume"),
//           ),
//         ],
//       ),
//     );

//     if (resume != true) {
//       await UploadSessionStore.clearAll();
//       return;
//     }

//     final token = SecureState.accessToken;
//     if (token == null) return;

//     final api = UploadApi(accessToken: token);
//     final manager = UploadManager(api);

//     setState(() {
//       _state = UploadState.uploading;
//       _statusText = "Resuming upload…";
//     });

//     final session =
//         await manager.resume(fileId: existing['file_id']);

//     _session = session;
//     await _continueUpload(session);
//   }

//   // ───────────────── FILE PICK ─────────────────

//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _state = UploadState.fileSelected;
//     });

//     HapticFeedback.selectionClick();
//   }

//   // ───────────────── START NEW UPLOAD ─────────────────

//   Future<void> _startUpload() async {
//     if (_file == null) return;

//     final token = SecureState.accessToken;
//     if (token == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     final Uint8List masterKey = SecureState.requireMasterKey();
//     final String filename = _file!.path.split('/').last;
//     final int fileSize = await _file!.length();

//     final api = UploadApi(accessToken: token);
//     final manager = UploadManager(api);

//     setState(() {
//       _state = UploadState.starting;
//       _statusText = "Preparing secure upload…";
//     });

//     // 1️⃣ START SESSION
//     final session = await manager.start(
//       file: _file!,
//       filenameEnc: encrypted.encHex,
//       filenameNonce: encrypted.nonceHex,
//       filenameHash: encrypted.hashHex,
//       chunkSize: chunkSize,
//       securityMode: "zero_knowledge",
//     );


//     _session = session;

//     // 2️⃣ FILE KEY
//     final Uint8List fileKey = await deriveFileKey(
//       masterKey: masterKey,
//       fileId: session.fileId,
//     );

//     // 3️⃣ ENCRYPT FILENAME
//     final encrypted = await FilenameCrypto.encrypt(
//       filename: filename,
//       fileKey: fileKey,
//     );

//     // 4️⃣ SET FILENAME
//     await api.setFilename(
//       fileId: session.fileId,
//       enc: encrypted.encHex,
//       nonce: encrypted.nonceHex,
//       hash: encrypted.hashHex,
//     );

//     await _continueUpload(session);
//   }

//   // ───────────────── CONTINUE UPLOAD ─────────────────

//   Future<void> _continueUpload(UploadSession session) async {
//     if (_file == null) {
//       setState(() {
//         _state = UploadState.error;
//         _statusText = "Original file missing";
//       });
//       return;
//     }

//     final Uint8List fileKey = await deriveFileKey(
//       masterKey: SecureState.requireMasterKey(),
//       fileId: session.fileId,
//     );

//     final api = UploadApi(accessToken: SecureState.accessToken!);
//     final manager = UploadManager(api);

//     final int fileSize = await _file!.length();
//     int sentBytes = session.uploadedChunks.length * chunkSize;

//     setState(() {
//       _state = UploadState.uploading;
//       _statusText = "Uploading encrypted chunks…";
//     });

//     while (!session.isComplete) {
//       final index = session.nextChunkToUpload();
//       if (index == null) break;

//       await manager.uploadOneChunk(
//         session: session,
//         index: index,
//         file: _file!,
//         fileKey: fileKey,
//       );

//       sentBytes += chunkSize;
//       setState(() {
//         _progress = sentBytes / fileSize;
//       });
//     }

//     setState(() {
//       _state = UploadState.finishing;
//       _statusText = "Finalizing upload…";
//     });

//     await manager.finish(session);

//     if (!mounted) return;

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const FileListScreen()),
//     );
//   }

//   // ───────────────── UI ─────────────────

//   @override
//   Widget build(BuildContext context) {
//     final uploading =
//         _state == UploadState.uploading ||
//         _state == UploadState.finishing;

//     return Scaffold(
//       backgroundColor: SilvoraColors.background,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text("Secure Upload"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 20),

//             if (uploading) ...[
//               LinearProgressIndicator(
//                 value: _progress,
//                 color: SilvoraColors.accent,
//                 backgroundColor: Colors.white12,
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 "${(_progress * 100).round()}% • $_statusText",
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ] else ...[
//               const Spacer(),
//               _uploadButton(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() => Card(
//         color: SilvoraColors.surface,
//         child: ListTile(
//           leading:
//               const Icon(Icons.lock_outline, color: SilvoraColors.accent),
//           title: Text(
//             _file == null
//                 ? "Choose a file"
//                 : _file!.path.split('/').last,
//             style: const TextStyle(color: Colors.white),
//           ),
//           subtitle: const Text(
//             "End-to-end encrypted • Resumable",
//             style: TextStyle(color: Colors.white54),
//           ),
//           onTap: _pickFile,
//         ),
//       );

//   Widget _uploadButton() => SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: SilvoraColors.accent,
//             padding: const EdgeInsets.symmetric(vertical: 14),
//           ),
//           onPressed:
//               _state == UploadState.fileSelected ? _startUpload : null,
//           child: const Text("Upload securely"),
//         ),
//       );
// }



// v5 =============================================
// ==========================================================
// lib/screens/upload/upload_screen.dart
// ==========================================================

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/api/upload_api.dart';
import '../../../infrastructure/uploads/upload_manager.dart';
import '../../../infrastructure/uploads/upload_session.dart';
import '../../../infrastructure/uploads/upload_session_store.dart';
import '../../../crypto/file_key.dart';
import '../../../crypto/filename_crypto.dart';
import '../../../state/secure_state.dart';
import '../files/file_list_screen.dart';

enum UploadState {
  idle,
  fileSelected,
  uploading,
  finishing,
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  File? _file;
  UploadSession? _session;

  UploadState _state = UploadState.idle;
  double _progress = 0;

  static const int chunkSize = 2 * 1024 * 1024;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _checkResume();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ───────────────── RESUME ─────────────────

  Future<void> _checkResume() async {
    final existing = await UploadSessionStore.loadAny();
    if (existing == null) return;

    try {
      final token = SecureState.accessToken;
      if (token == null) return;

      final manager = UploadManager(
        UploadApi(accessToken: token),
      );

      final result = await manager.resume(
        fileId: existing['file_id'],
      );

      _session = result.$1;
      _file = result.$2;

      await _continueUpload();
    } catch (_) {
      await UploadSessionStore.delete(existing['file_id']);
    }
  }

  // ───────────────── PICK ─────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path == null) return;

    setState(() {
      _file = File(result!.files.single.path!);
      _state = UploadState.fileSelected;
    });
  }

  // ───────────────── START ─────────────────

  Future<void> _startUpload() async {
    if (_file == null) return;

    final masterKey = SecureState.requireMasterKey();
    final filename = _file!.path.split('/').last;

    final manager = UploadManager(
      UploadApi(accessToken: SecureState.accessToken!),
    );

    final session = await manager.start(
      file: _file!,
      filenameCipherHex: "",
      filenameNonceHex: "",
      filenameMacHex: "",
      chunkSize: chunkSize,
      securityMode: "E2EE",
    );

    _session = session;

    final fileKey = await deriveFileKey(
      masterKey: masterKey,
      fileId: session.fileId,
    );

    final encrypted = await FilenameCrypto.encrypt(
      filename: filename,
      fileKey: fileKey,
    );

    final api = UploadApi(accessToken: SecureState.accessToken!);

    await api.setFilenameMetadata(
      fileId: session.fileId,
      cipherHex: encrypted.ciphertextHex,
      nonceHex: encrypted.nonceHex,
      macHex: encrypted.macHex,
    );

    await _continueUpload();
  }

  // ───────────────── CONTINUE ─────────────────

  Future<void> _continueUpload() async {
    if (_session == null || _file == null) return;

    final manager = UploadManager(
      UploadApi(accessToken: SecureState.accessToken!),
    );

    final fileKey = await deriveFileKey(
      masterKey: SecureState.requireMasterKey(),
      fileId: _session!.fileId,
    );

    setState(() => _state = UploadState.uploading);

    while (!_session!.isComplete) {
      await manager.uploadOneChunk(
        session: _session!,
        file: _file!,
        fileKey: fileKey,
      );

      setState(() {
        _progress =
            _session!.uploadedChunks.length / _session!.totalChunks;
      });
    }

    setState(() => _state = UploadState.finishing);

    await manager.finish(_session!);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FileListScreen()),
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secure Upload")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseController,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7C5CFF),
                        Color(0xFF9B87FF),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_file != null)
                Text(
                  _file!.path.split('/').last,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 30),
              if (_state == UploadState.idle)
                ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text("Choose File"),
                ),
              if (_state == UploadState.fileSelected)
                ElevatedButton(
                  onPressed: _startUpload,
                  child: const Text("Start Upload"),
                ),
              if (_state == UploadState.uploading ||
                  _state == UploadState.finishing)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 12),
                    Text("${(_progress * 100).round()}%"),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
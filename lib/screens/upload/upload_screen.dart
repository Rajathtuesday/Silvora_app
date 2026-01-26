// // lib/screens/upload/upload_screen.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';

// enum _ToastType { success, error, info }

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _selectedFile;
//   bool _isUploading = false;
//   double _progress = 0.0;

//   bool _zeroKnowledge = false;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

//   @override
//   void initState() {
//     super.initState();
//     _checkForPendingUpload();
//   }

//   Future<void> _checkForPendingUpload() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (prefs.getString("active_upload_id") != null && mounted) {
//       _showToast("Unfinished upload detected", _ToastType.info);
//     }
//   }

//   void _showToast(String msg, _ToastType type) {
//     final messenger = ScaffoldMessenger.of(context);
//     messenger.clearSnackBars();
//     messenger.showSnackBar(SnackBar(content: Text(msg)));
//   }

//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _selectedFile = File(result!.files.single.path!);
//     });
//   }

//   Future<void> _startUpload() async {
//     if (_selectedFile == null || _isUploading) return;

//     final file = _selectedFile!;
//     final fileLen = await file.length();
//     final filename = file.path.split(Platform.pathSeparator).last;

//     setState(() {
//       _isUploading = true;
//       _progress = 0;
//     });

//     // 🔐 REQUIRE UNLOCKED VAULT
//     final masterKey = SecureState.requireMasterKey();

//     final uploadId = await UploadService.startUpload(
//       filename: filename,
//       fileSize: fileLen,
//       chunkSize: chunkSize,
//       securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//     );

//     if (uploadId == null) {
//       _showToast("Upload start failed", _ToastType.error);
//       setState(() => _isUploading = false);
//       return;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString("active_upload_id", uploadId);

//     final uploadedChunks =
//         await UploadService.resumeUpload(uploadId) ?? {};

//     final raf = await file.open();
//     final totalChunks = (fileLen / chunkSize).ceil();

//     try {
//       for (int i = 0; i < totalChunks; i++) {
//         if (uploadedChunks.contains(i)) continue;

//         await raf.setPosition(i * chunkSize);
//         final plain = await raf.read(
//           ((i + 1) * chunkSize > fileLen)
//               ? fileLen - i * chunkSize
//               : chunkSize,
//         );

//         // 🔑 PER-CHUNK KEY (MUST MATCH DECRYPT)
//         final derivedKey = await hkdfSha256(
//           ikm: masterKey,
//           info: utf8.encode("silvora-chunk-$i"),
//         );

//         final nonce = await _algorithm.newNonce();

//         final box = await _algorithm.encrypt(
//           plain,
//           secretKey: SecretKey(derivedKey),
//           nonce: nonce,
//         );

//         final ok = await UploadService.uploadChunk(
//           uploadId: uploadId,
//           chunkIndex: i,
//           cipherChunk: Uint8List.fromList(box.cipherText),
//           nonce: Uint8List.fromList(nonce),
//           mac: Uint8List.fromList(box.mac.bytes),
//         );

//         if (!ok) {
//           throw Exception("Chunk $i upload failed");
//         }

//         setState(() {
//           _progress = (i + 1) / totalChunks;
//         });
//       }
//     } finally {
//       await raf.close();
//     }

//     await UploadService.finishUpload(uploadId: uploadId);
//     await prefs.remove("active_upload_id");

//     setState(() => _isUploading = false);
//     _showToast("Upload complete", _ToastType.success);

//     if (!mounted) return;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const FileListScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ElevatedButton(
//               onPressed: _pickFile,
//               child: const Text("Choose File"),
//             ),
//             SwitchListTile(
//               title: const Text("Zero-Knowledge Mode"),
//               value: _zeroKnowledge,
//               onChanged: (v) => setState(() => _zeroKnowledge = v),
//             ),
//             if (_isUploading)
//               LinearProgressIndicator(value: _progress),
//             ElevatedButton(
//               onPressed: _startUpload,
//               child: const Text("Encrypt & Upload"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// ========================================================================
// lib/upload_screen.dart ui updated ine lets see this in android studio 
// lib/screens/upload/upload_screen.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _selectedFile;
//   bool _isUploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = false;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _selectedFile = File(result!.files.single.path!);
//     });
//   }

//   Future<void> _startUpload() async {
//     if (_selectedFile == null || _isUploading) return;

//     final file = _selectedFile!;
//     final fileLen = await file.length();
//     final filename = file.path.split(Platform.pathSeparator).last;

//     setState(() {
//       _isUploading = true;
//       _progress = 0;
//     });

//     final masterKey = SecureState.requireMasterKey();

//     final uploadId = await UploadService.startUpload(
//       filename: filename,
//       fileSize: fileLen,
//       chunkSize: chunkSize,
//       securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//     );

//     if (uploadId == null) {
//       setState(() => _isUploading = false);
//       return;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString("active_upload_id", uploadId);

//     final uploadedChunks =
//         await UploadService.resumeUpload(uploadId) ?? {};

//     final raf = await file.open();
//     final totalChunks = (fileLen / chunkSize).ceil();

//     try {
//       for (int i = 0; i < totalChunks; i++) {
//         if (uploadedChunks.contains(i)) continue;

//         await raf.setPosition(i * chunkSize);
//         final plain = await raf.read(
//           ((i + 1) * chunkSize > fileLen)
//               ? fileLen - i * chunkSize
//               : chunkSize,
//         );

//         final derivedKey = await hkdfSha256(
//           ikm: masterKey,
//           info: utf8.encode("silvora-chunk-$i"),
//         );

//         final nonce = await _algorithm.newNonce();
//         final box = await _algorithm.encrypt(
//           plain,
//           secretKey: SecretKey(derivedKey),
//           nonce: nonce,
//         );

//         final ok = await UploadService.uploadChunk(
//           uploadId: uploadId,
//           chunkIndex: i,
//           cipherChunk: Uint8List.fromList(box.cipherText),
//           nonce: Uint8List.fromList(nonce),
//           mac: Uint8List.fromList(box.mac.bytes),
//         );

//         if (!ok) throw Exception("Upload failed");

//         setState(() {
//           _progress = (i + 1) / totalChunks;
//         });
//       }
//     } finally {
//       await raf.close();
//     }

//     await UploadService.finishUpload(uploadId: uploadId);
//     await prefs.remove("active_upload_id");

//     if (!mounted) return;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const FileListScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     if (_selectedFile == null)
//                       const Text(
//                         "Select a file to encrypt and upload",
//                         style: TextStyle(fontSize: 16),
//                       )
//                     else
//                       Text(
//                         _selectedFile!.path.split("/").last,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     const SizedBox(height: 12),
//                     ElevatedButton.icon(
//                       onPressed: _pickFile,
//                       icon: const Icon(Icons.attach_file),
//                       label: const Text("Choose File"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             SwitchListTile(
//               title: const Text("Zero-Knowledge Encryption"),
//               subtitle: const Text(
//                 "Only you can decrypt this file",
//               ),
//               value: _zeroKnowledge,
//               onChanged: (v) => setState(() => _zeroKnowledge = v),
//             ),
//             const SizedBox(height: 12),
//             if (_isUploading) ...[
//               LinearProgressIndicator(value: _progress),
//               const SizedBox(height: 8),
//               Text("${(_progress * 100).toStringAsFixed(0)}%"),
//             ],
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isUploading ? null : _startUpload,
//                 child: const Text("Encrypt & Upload"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// // ========================================================================

// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _selectedFile;
//   bool _isUploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = false;

//   DateTime? _uploadStartedAt;
//   int _uploadedBytes = 0;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────
//   String _formatDuration(Duration d) {
//     if (d.inSeconds < 60) {
//       return "${d.inSeconds}s";
//     }
//     return "${d.inMinutes}m ${d.inSeconds % 60}s";
//   }

//   String? _estimatedTimeRemaining(int totalBytes) {
//     if (_uploadStartedAt == null || _uploadedBytes == 0) return null;

//     final elapsed =
//         DateTime.now().difference(_uploadStartedAt!).inMilliseconds;

//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed; // bytes/ms
//     final remainingBytes = totalBytes - _uploadedBytes;

//     if (remainingBytes <= 0) return "Finishing…";

//     final remainingMs = remainingBytes / speed;
//     return _formatDuration(Duration(milliseconds: remainingMs.round()));
//   }

//   // ─────────────────────────────────────────────
//   // File picker
//   // ─────────────────────────────────────────────
//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _selectedFile = File(result!.files.single.path!);
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────
//   Future<void> _startUpload() async {
//     if (_selectedFile == null || _isUploading) return;

//     final file = _selectedFile!;
//     final fileLen = await file.length();
//     final filename = file.path.split(Platform.pathSeparator).last;

//     setState(() {
//       _isUploading = true;
//       _progress = 0;
//       _uploadedBytes = 0;
//       _uploadStartedAt = DateTime.now();
//     });

//     final masterKey = SecureState.requireMasterKey();

//     final uploadId = await UploadService.startUpload(
//       filename: filename,
//       fileSize: fileLen,
//       chunkSize: chunkSize,
//       securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//     );

//     if (uploadId == null) {
//       setState(() => _isUploading = false);
//       return;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString("active_upload_id", uploadId);

//     final uploadedChunks =
//         await UploadService.resumeUpload(uploadId) ?? {};

//     final raf = await file.open();
//     final totalChunks = (fileLen / chunkSize).ceil();

//     try {
//       for (int i = 0; i < totalChunks; i++) {
//         if (uploadedChunks.contains(i)) continue;

//         await raf.setPosition(i * chunkSize);
//         final plain = await raf.read(
//           ((i + 1) * chunkSize > fileLen)
//               ? fileLen - i * chunkSize
//               : chunkSize,
//         );

//         final derivedKey = await hkdfSha256(
//           ikm: masterKey,
//           info: utf8.encode("silvora-chunk-$i"),
//         );

//         final nonce = await _algorithm.newNonce();
//         final box = await _algorithm.encrypt(
//           plain,
//           secretKey: SecretKey(derivedKey),
//           nonce: nonce,
//         );

//         final ok = await UploadService.uploadChunk(
//           uploadId: uploadId,
//           chunkIndex: i,
//           cipherChunk: Uint8List.fromList(box.cipherText),
//           nonce: Uint8List.fromList(nonce),
//           mac: Uint8List.fromList(box.mac.bytes),
//         );

//         if (!ok) throw Exception("Upload failed");

//         _uploadedBytes += plain.length;

//         setState(() {
//           _progress = _uploadedBytes / fileLen;
//         });
//       }
//     } finally {
//       await raf.close();
//     }

//     await UploadService.finishUpload(uploadId: uploadId);
//     await prefs.remove("active_upload_id");

//     if (!mounted) return;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const FileListScreen()),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final totalBytes = _selectedFile?.lengthSync() ?? 0;
//     final eta = totalBytes > 0
//         ? _estimatedTimeRemaining(totalBytes)
//         : null;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Secure Upload"),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints:
//                     BoxConstraints(minHeight: constraints.maxHeight),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 32),

//                     // ───────── File card ─────────
//                     Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(18),
//                         child: Column(
//                           children: [
//                             Icon(
//                               Icons.insert_drive_file,
//                               size: 40,
//                               color:
//                                   Theme.of(context).colorScheme.primary,
//                             ),
//                             const SizedBox(height: 10),
//                             Text(
//                               _selectedFile == null
//                                   ? "Choose a file to encrypt"
//                                   : _selectedFile!.path
//                                       .split("/")
//                                       .last,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             ElevatedButton.icon(
//                               onPressed: _pickFile,
//                               icon: const Icon(Icons.attach_file),
//                               label: const Text("Choose File"),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // ───────── ZK toggle ─────────
//                     Padding(
//                       padding:
//                           const EdgeInsets.symmetric(horizontal: 16),
//                       child: Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: SwitchListTile(
//                           title: const Text(
//                             "Zero-Knowledge Encryption",
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           subtitle: const Text(
//                             "Even Silvora cannot decrypt this file",
//                           ),
//                           value: _zeroKnowledge,
//                           onChanged: _isUploading
//                               ? null
//                               : (v) =>
//                                   setState(() => _zeroKnowledge = v),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 32),

//                     // ───────── CENTERED CTA ─────────
//                     Padding(
//                       padding:
//                           const EdgeInsets.symmetric(horizontal: 24),
//                       child: Column(
//                         children: [
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed:
//                                   _isUploading ? null : _startUpload,
//                               style: ElevatedButton.styleFrom(
//                                 padding:
//                                     const EdgeInsets.symmetric(
//                                   vertical: 18,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius:
//                                       BorderRadius.circular(18),
//                                 ),
//                                 elevation: 6,
//                               ),
//                               child: const Text(
//                                 "Encrypt & Upload",
//                                 style: TextStyle(
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),

//                           if (_isUploading) ...[
//                             const SizedBox(height: 16),
//                             LinearProgressIndicator(
//                               value: _progress,
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               "${(_progress * 100).toStringAsFixed(0)}% • "
//                               "${eta ?? "Estimating…"} remaining",
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//========================================================================
// lib/screens/upload/upload_screen.dart

// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:silvora_app/services/vault_service.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _cipher = Xchacha20.poly1305Aead();

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 1024 * 256) return null;
//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;
//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   //─────────────────────────────────────────────
//   // ensure vault unloacked 
//   // ─────────────────────────────────────────────
//   Future<bool> _ensureVaultUnlocked() async {
//   if (!SecureState.isLocked) return true;

//   final controller = TextEditingController();
//   bool unlocked = false;

//   await showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (_) => AlertDialog(
//       title: const Text("Unlock vault"),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             "Your vault is locked for security.\nEnter your password to continue.",
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: controller,
//             obscureText: true,
//             decoration: const InputDecoration(
//               labelText: "Password",
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text("Cancel"),
//         ),
//         ElevatedButton(
//           onPressed: () async {
//             try {
//               await VaultService.unlockWithPassword(controller.text);
//               unlocked = true;
//               if (mounted) Navigator.pop(context);
//             } catch (_) {
//               // optional: show error
//             }
//           },
//           child: const Text("Unlock"),
//         ),
//       ],
//     ),
//   );

//   return unlocked;
// }


//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//   if (_file == null || _uploading) return;

//   final file = _file!;
//   final size = await file.length();
//   final name = file.uri.pathSegments.last;

//   setState(() {
//     _uploading = true;
//     _startedAt = DateTime.now();
//   });

//   final ok = await _ensureVaultUnlocked();
//   if (!ok) {
//     setState(() => _uploading = false);
//     return;
//   }

//   final masterKey = SecureState.requireMasterKey();


//   // ✅ START UPLOAD → fileId
//   final String fileId = await UploadService.startUpload(
//     filename: name,
//     fileSize: size,
//     chunkSize: chunkSize,
//     securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//   );

//   // 🔐 persist active upload (resume-safe)
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setString("active_file_id", fileId);

//   // ✅ RESUME USING fileId
//   final uploaded = await UploadService.resumeUpload(fileId);

//   final raf = await file.open();
//   final chunks = (size / chunkSize).ceil();

//   try {
//     for (int i = 0; i < chunks; i++) {
//       if (uploaded.contains(i)) continue;

//       await raf.setPosition(i * chunkSize);
//       final plain = await raf.read(
//         ((i + 1) * chunkSize > size)
//             ? size - i * chunkSize
//             : chunkSize,
//       );

//       final key = await hkdfSha256(
//         ikm: masterKey,
//         info: utf8.encode("silvora-chunk-$i"),
//       );

//       final nonce = await _cipher.newNonce();
//       final box = await _cipher.encrypt(
//         plain,
//         secretKey: SecretKey(key),
//         nonce: nonce,
//       );

//       // ✅ uploadChunk now RETURNS void
//       await UploadService.uploadChunk(
//         fileId: fileId,
//         chunkIndex: i,
//         cipherChunk: Uint8List.fromList(box.cipherText),
//         nonce: Uint8List.fromList(nonce),
//         mac: Uint8List.fromList(box.mac.bytes),
//       );

//       _uploadedBytes += plain.length;
//       setState(() => _progress = _uploadedBytes / size);
//     }
//   } finally {
//     await raf.close();
//   }

//   // ✅ finishUpload takes positional fileId
//   await UploadService.finishUpload(fileId);

//   await prefs.remove("active_file_id");

//   if (!mounted) return;
//   Navigator.pushReplacement(
//     context,
//     MaterialPageRoute(builder: (_) => const FileListScreen()),
//   );
// }


//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Upload"),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               _fileCard(),
//               const SizedBox(height: 16),
//               _zkCard(),
//               const Spacer(),
//               _uploadArea(eta),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // Widgets
//   // ─────────────────────────────────────────────

//   Widget _fileCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.insert_drive_file_rounded,
//                 size: 40,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Tap to choose a file"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const Icon(Icons.chevron_right),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _zkCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle: const Text("Encrypted locally. Even Silvora can’t read it."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadArea(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Encrypting & uploading…" : "Upload securely",
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(color: Colors.grey, fontSize: 13),
//           ),
//         ],
//       ],
//     );
//   }
// }
// ===================================================================================
// lib/screens/upload/upload_screen.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../../services/vault_service.dart';
// import '../files/file_list_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _cipher = Xchacha20.poly1305Aead();

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 1024 * 256) return null;
//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;
//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Unlock prompt (local)
//   // ─────────────────────────────────────────────

//   Future<bool> _ensureVaultUnlocked() async {
//     if (!SecureState.isLocked) return true;

//     final controller = TextEditingController();
//     bool unlocked = false;

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         title: const Text("Unlock vault"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Your vault is locked for security.\nEnter your password to continue.",
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: controller,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: "Password",
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 await VaultService.unlockWithPassword(controller.text);
//                 unlocked = true;
//                 if (mounted) Navigator.pop(context);
//               } catch (e) {
//                 // show a small error hint (not blocking)
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Unlock failed")),
//                 );
//               }
//             },
//             child: const Text("Unlock"),
//           ),
//         ],
//       ),
//     );

//     return unlocked;
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     // quick auth guard — prevents "Not authenticated" exceptions
//     if (SecureState.accessToken == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Session expired — please log in.")),
//       );
//       Navigator.pushReplacementNamed(context, '/login');
//       return;
//     }

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     setState(() {
//       _uploading = true;
//       _startedAt = DateTime.now();
//       _progress = 0.0;
//       _uploadedBytes = 0;
//     });

//     try {
//       final ok = await _ensureVaultUnlocked();
//       if (!ok) {
//         setState(() => _uploading = false);
//         return;
//       }

//       final masterKey = SecureState.requireMasterKey();

//       // ✅ START UPLOAD → fileId
//       final String fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );

//       // 🔐 persist active upload (resume-safe)
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString("active_file_id", fileId);

//       // ✅ RESUME USING fileId
//       final uploaded = await UploadService.resumeUpload(fileId);

//       final raf = await file.open();
//       final chunks = (size / chunkSize).ceil();

//       try {
//         for (int i = 0; i < chunks; i++) {
//           if (uploaded.contains(i)) continue;

//           await raf.setPosition(i * chunkSize);
//           final plain = await raf.read(
//             ((i + 1) * chunkSize > size) ? size - i * chunkSize : chunkSize,
//           );

//           final key = await hkdfSha256(
//             ikm: masterKey,
//             info: utf8.encode("silvora-chunk-$i"),
//           );

//           final nonce = await _cipher.newNonce();
//           final box = await _cipher.encrypt(
//             plain,
//             secretKey: SecretKey(key),
//             nonce: nonce,
//           );

//           await UploadService.uploadChunk(
//             fileId: fileId,
//             chunkIndex: i,
//             cipherChunk: Uint8List.fromList(box.cipherText),
//             nonce: Uint8List.fromList(nonce),
//             mac: Uint8List.fromList(box.mac.bytes),
//           );

//           _uploadedBytes += plain.length;
//           setState(() => _progress = _uploadedBytes / size);
//         }
//       } finally {
//         await raf.close();
//       }

//       // ✅ finishUpload takes positional fileId
//       await UploadService.finishUpload(fileId);
//       await prefs.remove("active_file_id");

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     } catch (e) {
//       // friendly error UI
//       debugPrint("Upload error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Upload failed: ${e.toString()}")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _uploading = false;
//           _progress = 0.0;
//         });
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Upload"),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               _fileCard(),
//               const SizedBox(height: 16),
//               _zkCard(),
//               const Spacer(),
//               _uploadArea(eta),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // Widgets
//   // ─────────────────────────────────────────────

//   Widget _fileCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.insert_drive_file_rounded,
//                 size: 40,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Tap to choose a file"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const Icon(Icons.chevron_right),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _zkCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle: const Text("Encrypted locally. Even Silvora can’t read it."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadArea(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Encrypting & uploading…" : "Upload securely",
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(color: Colors.grey, fontSize: 13),
//           ),
//         ],
//       ],
//     );
//   }
// }
// ===================================================================================================
// lib/screens/upload/upload_screen.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../../services/vault_service.dart';
// import '../files/file_list_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _cipher = Xchacha20.poly1305Aead();

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 1024 * 256) return null;
//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;
//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Unlock prompt (local)
//   // ─────────────────────────────────────────────

//   // Future<bool> _ensureVaultUnlocked() async {
//   //   if (!SecureState.isLocked) return true;

//   //   final controller = TextEditingController();
//   //   bool unlocked = false;

//   //   await showDialog(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (_) => AlertDialog(
//   //       title: const Text("Unlock vault"),
//   //       content: Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           const Text(
//   //             "Your vault is locked for security.\nEnter your password to continue.",
//   //           ),
//   //           const SizedBox(height: 12),
//   //           TextField(
//   //             controller: controller,
//   //             obscureText: true,
//   //             decoration: const InputDecoration(
//   //               labelText: "Password",
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //       actions: [
//   //         TextButton(
//   //           onPressed: () => Navigator.pop(context),
//   //           child: const Text("Cancel"),
//   //         ),
//   //         ElevatedButton(
//   //           onPressed: () async {
//   //             try {
//   //               await VaultService.unlockWithPassword(controller.text);
//   //               unlocked = true;
//   //               if (mounted) Navigator.pop(context);
//   //             } catch (e) {
//   //               // show a small error hint (not blocking)
//   //               ScaffoldMessenger.of(context).showSnackBar(
//   //                 const SnackBar(content: Text("Unlock failed")),
//   //               );
//   //             }
//   //           },
//   //           child: const Text("Unlock"),
//   //         ),
//   //       ],
//   //     ),
//   //   );

//   //   return unlocked;
//   // }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     // quick auth guard — prevents "Not authenticated" exceptions
//     if (SecureState.accessToken == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Session expired — please log in.")),
//       );
//       Navigator.pushReplacementNamed(context, '/login');
//       return;
//     }

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     setState(() {
//       _uploading = true;
//       _startedAt = DateTime.now();
//       _progress = 0.0;
//       _uploadedBytes = 0;
//     });

//     try {
//       // final ok = await _ensureVaultUnlocked();
//       // if (!ok) {
//       //   setState(() => _uploading = false);
//       //   return;
//       // }

//       final masterKey = SecureState.requireMasterKey();

//       // ✅ START UPLOAD → fileId
//       final String fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );

//       // 🔐 persist active upload (resume-safe)
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString("active_file_id", fileId);

//       // ✅ RESUME USING fileId
//       final uploaded = await UploadService.resumeUpload(fileId);

//       final raf = await file.open();
//       final chunks = (size / chunkSize).ceil();

//       try {
//         for (int i = 0; i < chunks; i++) {
//           if (uploaded.contains(i)) continue;

//           await raf.setPosition(i * chunkSize);
//           final plain = await raf.read(
//             ((i + 1) * chunkSize > size) ? size - i * chunkSize : chunkSize,
//           );

//           final key = await hkdfSha256(
//             ikm: masterKey,
//             info: utf8.encode("silvora-chunk-$i"),
//           );

//           final nonce = await _cipher.newNonce();
//           final box = await _cipher.encrypt(
//             plain,
//             secretKey: SecretKey(key),
//             nonce: nonce,
//           );

//           await UploadService.uploadChunk(
//             fileId: fileId,
//             chunkIndex: i,
//             cipherChunk: Uint8List.fromList(box.cipherText),
//             nonce: Uint8List.fromList(nonce),
//             mac: Uint8List.fromList(box.mac.bytes),
//           );

//           _uploadedBytes += plain.length;
//           setState(() => _progress = _uploadedBytes / size);
//         }
//       } finally {
//         await raf.close();
//       }

//       // ✅ finishUpload takes positional fileId
//       await UploadService.finishUpload(fileId);
//       await prefs.remove("active_file_id");

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     } catch (e) {
//       // friendly error UI
//       debugPrint("Upload error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Upload failed: ${e.toString()}")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _uploading = false;
//           _progress = 0.0;
//         });
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Upload"),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               _fileCard(),
//               const SizedBox(height: 16),
//               _zkCard(),
//               const Spacer(),
//               _uploadArea(eta),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // Widgets
//   // ─────────────────────────────────────────────

//   Widget _fileCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.insert_drive_file_rounded,
//                 size: 40,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Tap to choose a file"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const Icon(Icons.chevron_right),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _zkCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle: const Text("Encrypted locally. Even Silvora can’t read it."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadArea(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Encrypting & uploading…" : "Upload securely",
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(color: Colors.grey, fontSize: 13),
//           ),
//         ],
//       ],
//     );
//   }
// }
// =============================================================================================
// // lib/screens/upload/upload_screen.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _cipher = Xchacha20.poly1305Aead();
  


//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 256 * 1024) return null;

//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;

//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     setState(() {
//       _uploading = true;
//       _startedAt = DateTime.now();
//       _progress = 0.0;
//       _uploadedBytes = 0;
//     });

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       final fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );
//       debugPrint("Started upload with fileId: $fileId");

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString("active_file_id", fileId);

//       final uploaded = await UploadService.resumeUpload(fileId);
//       final raf = await file.open();
//       final chunks = (size / chunkSize).ceil();

//       try {
//         for (int i = 0; i < chunks; i++) {
//           if (uploaded.contains(i)) continue;

//           await raf.setPosition(i * chunkSize);
//           final plain = await raf.read(
//             ((i + 1) * chunkSize > size)
//                 ? size - i * chunkSize
//                 : chunkSize,
//           );

//           final key = await hkdfSha256(
//             ikm: masterKey,
//             info: utf8.encode("silvora-chunk-$i"),
//           );

//           final nonce = await _cipher.newNonce();
//           final box = await _cipher.encrypt(
//             plain,
//             secretKey: SecretKey(key),
//             nonce: nonce,
//           );

//           await UploadService.uploadChunk(
//             fileId: fileId,
//             chunkIndex: i,
//             cipherChunk: Uint8List.fromList(box.cipherText),
//             nonce: Uint8List.fromList(nonce),
//             mac: Uint8List.fromList(box.mac.bytes),
//           );

//           _uploadedBytes += plain.length;
//           setState(() => _progress = _uploadedBytes / size);
//           debugPrint("⬆️ Uploading chunk $i");

//         }
//       } finally {
//         await raf.close();
//       }

//       await UploadService.finishUpload(fileId);
//       await prefs.remove("active_file_id");

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     } catch (e) {
//       debugPrint("Upload error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Upload failed")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _uploading = false);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     // SecureState.markUserActive();

//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const Spacer(),
//             _uploadSection(eta),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadSection(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Uploading…" : "Upload securely",
//               style:
//                   const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(fontSize: 13, color: Colors.grey),
//           ),
//         ],
//       ],
//     );
//   }
// }
// ====================================================================================================
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import '../../services/upload_worker.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;
//   final Xchacha20 _cipher = Xchacha20.poly1305Aead();

//   // 🔑 Resume keys
//   static const _kActiveFileId = "active_file_id";
//   static const _kUploadPath = "upload_file_path";
//   static const _kUploadSize = "upload_file_size";

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 256 * 1024) return null;

//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;

//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Upload (RESUMABLE)
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     setState(() {
//       _uploading = true;
//       _startedAt = DateTime.now();
//       _progress = 0.0;
//       _uploadedBytes = 0;
//     });

//     final prefs = await SharedPreferences.getInstance();

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       // 🔁 CHECK FOR EXISTING UPLOAD
//       final existingFileId = prefs.getString(_kActiveFileId);
//       final existingPath = prefs.getString(_kUploadPath);
//       final existingSize = prefs.getInt(_kUploadSize);

//       late final String fileId;

//       if (existingFileId != null &&
//           existingPath == file.path &&
//           existingSize == size) {
//         // ✅ RESUME
//         debugPrint("🔁 Resuming upload: $existingFileId");
//         fileId = existingFileId;
//       } else {
//         // 🆕 START NEW
//         debugPrint("🆕 Starting new upload");

//         fileId = await UploadService.startUpload(
//           filename: name,
//           fileSize: size,
//           chunkSize: chunkSize,
//           securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//         );

//         await prefs.setString(_kActiveFileId, fileId);
//         await prefs.setString(_kUploadPath, file.path);
//         await prefs.setInt(_kUploadSize, size);
//       }

//       final uploaded = await UploadService.resumeUpload(fileId);
//       final raf = await file.open();
//       final chunks = (size / chunkSize).ceil();

//       try {
//         for (int i = 0; i < chunks; i++) {
//           if (uploaded.contains(i)) continue;

//           await raf.setPosition(i * chunkSize);
//           final plain = await raf.read(
//             ((i + 1) * chunkSize > size)
//                 ? size - i * chunkSize
//                 : chunkSize,
//           );

//           final key = await hkdfSha256(
//             ikm: masterKey,
//             info: utf8.encode("silvora-chunk-$i"),
//           );

//           final nonce = await _cipher.newNonce();
//           final box = await _cipher.encrypt(
//             plain,
//             secretKey: SecretKey(key),
//             nonce: nonce,
//           );

//           await UploadService.uploadChunk(
//             fileId: fileId,
//             chunkIndex: i,
//             cipherChunk: Uint8List.fromList(box.cipherText),
//             nonce: Uint8List.fromList(nonce),
//             mac: Uint8List.fromList(box.mac.bytes),
//           );

//           _uploadedBytes += plain.length;
//           setState(() => _progress = _uploadedBytes / size);
//           debugPrint("⬆️ Uploading chunk $i");
//         }
//       } finally {
//         await raf.close();
//       }

//       await UploadService.finishUpload(fileId);

//       // 🧹 CLEAN UP RESUME STATE
//       await prefs.remove(_kActiveFileId);
//       await prefs.remove(_kUploadPath);
//       await prefs.remove(_kUploadSize);

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     } catch (e) {
//       debugPrint("Upload error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _uploading = false);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const Spacer(),
//             _uploadSection(eta),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadSection(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Uploading…" : "Upload securely",
//               style:
//                   const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(fontSize: 13, color: Colors.grey),
//           ),
//         ],
//       ],
//     );
//   }
// }
//=============================================================================
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:isolate';
// import 'dart:ui';

// import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';


// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import 'package:flutter/foundation.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;

//   // 🔑 Resume keys
//   static const _kActiveFileId = "active_file_id";
//   static const _kUploadPath = "upload_file_path";
//   static const _kUploadSize = "upload_file_size";

//   late final ReceivePort _progressPort;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _progressPort = ReceivePort();
//     IsolateNameServer.registerPortWithName(
//       _progressPort.sendPort,
//       "upload_progress",
//     );

//     _progressPort.listen((message) {
//       if (message is int && mounted) {
//         _uploadedBytes += message;
//         setState(() {
//           _progress = _uploadedBytes / (_file?.lengthSync() ?? 1);
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     IsolateNameServer.removePortNameMapping("upload_progress");
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 256 * 1024) return null;

//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;

//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Upload (RESUMABLE + ISOLATE)
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     setState(() {
//       _uploading = true;
//       _startedAt = DateTime.now();
//       _progress = 0.0;
//       _uploadedBytes = 0;
//     });

//     final prefs = await SharedPreferences.getInstance();

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       // 🔁 RESUME CHECK
//       final existingFileId = prefs.getString(_kActiveFileId);
//       final existingPath = prefs.getString(_kUploadPath);
//       final existingSize = prefs.getInt(_kUploadSize);

//       late final String fileId;

//       if (existingFileId != null &&
//           existingPath == file.path &&
//           existingSize == size) {
//         debugPrint("🔁 Resuming upload: $existingFileId");
//         fileId = existingFileId;
//       } else {
//         debugPrint("🆕 Starting new upload");

//         fileId = await UploadService.startUpload(
//           filename: name,
//           fileSize: size,
//           chunkSize: chunkSize,
//           securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//         );

//         await prefs.setString(_kActiveFileId, fileId);
//         await prefs.setString(_kUploadPath, file.path);
//         await prefs.setInt(_kUploadSize, size);
//       }

//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: Uint8List.fromList(masterKey),
//         chunkSize: chunkSize,
//       );

//       await Isolate.run(() async {
//         await uploadWorker(
//           params,
//           (uploadedBytes) {
//             final port =
//                 IsolateNameServer.lookupPortByName("upload_progress");
//             port?.send(uploadedBytes);
//           },
//         );
//       });

//       await UploadService.finishUpload(fileId);

//       // 🧹 CLEAN UP
//       await prefs.remove(_kActiveFileId);
//       await prefs.remove(_kUploadPath);
//       await prefs.remove(_kUploadSize);

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     } catch (e) {
//       debugPrint("Upload error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _uploading = false);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const Spacer(),
//             _uploadSection(eta),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadSection(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Uploading…" : "Upload securely",
//               style:
//                   const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(fontSize: 13, color: Colors.grey),
//           ),
//         ],
//       ],
//     );
//   }
// }
// =======================================================================================================cehck=
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;

//   // Resume keys
//   static const _kActiveFileId = "active_file_id";
//   static const _kUploadPath = "upload_file_path";
//   static const _kUploadSize = "upload_file_size";

//   late final ReceivePort _progressPort;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _progressPort = ReceivePort();
//     _progressPort.listen((message) {
//       if (message is int && mounted) {
//         _uploadedBytes += message;
//         setState(() {
//           _progress = _uploadedBytes / (_file?.lengthSync() ?? 1);
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 256 * 1024) return null;

//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;

//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Upload (RESUMABLE + ISOLATE)
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     setState(() {
//       _uploading = true;
//       _startedAt = DateTime.now();
//       _progress = 0.0;
//       _uploadedBytes = 0;
//     });

//     final prefs = await SharedPreferences.getInstance();

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       final existingFileId = prefs.getString(_kActiveFileId);
//       final existingPath = prefs.getString(_kUploadPath);
//       final existingSize = prefs.getInt(_kUploadSize);

//       late final String fileId;

//       if (existingFileId != null &&
//           existingPath == file.path &&
//           existingSize == size) {
//         fileId = existingFileId;
//       } else {
//         fileId = await UploadService.startUpload(
//           filename: name,
//           fileSize: size,
//           chunkSize: chunkSize,
//           securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//         );

//         await prefs.setString(_kActiveFileId, fileId);
//         await prefs.setString(_kUploadPath, file.path);
//         await prefs.setInt(_kUploadSize, size);
//       }

//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: Uint8List.fromList(masterKey),
//         chunkSize: chunkSize,
//       );

//       await Isolate.spawn(
//         _uploadIsolateEntry,
//         {
//           "params": params,
//           "sendPort": _progressPort.sendPort,
//         },
//       );

//       await UploadService.finishUpload(fileId);

//       await prefs.remove(_kActiveFileId);
//       await prefs.remove(_kUploadPath);
//       await prefs.remove(_kUploadSize);

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     } catch (e) {
//       debugPrint("Upload error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _uploading = false);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const Spacer(),
//             _uploadSection(eta),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadSection(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Uploading…" : "Upload securely",
//               style:
//                   const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(fontSize: 13, color: Colors.grey),
//           ),
//         ],
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // ISOLATE ENTRY (MUST BE TOP-LEVEL / STATIC)
// // ─────────────────────────────────────────────

// Future<void> _uploadIsolateEntry(Map<String, dynamic> message) async {
//   final UploadTaskParams params = message["params"];
//   final SendPort sendPort = message["sendPort"];

//   await uploadWorker(params, sendPort);
// }
// ============================================================--------------------========================
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../crypto/hkdf.dart';
// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;

//   int _uploadedBytes = 0;
//   DateTime? _startedAt;

//   static const int chunkSize = 2 * 1024 * 1024;

//   // Resume keys
//   static const _kActiveFileId = "active_file_id";
//   static const _kUploadPath = "upload_file_path";
//   static const _kUploadSize = "upload_file_size";

//   late final ReceivePort _progressPort;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _progressPort = ReceivePort();
//     _progressPort.listen((message) {
//       if (message is int && mounted) {
//         _uploadedBytes += message;
//         setState(() {
//           _progress = _uploadedBytes / (_file?.lengthSync() ?? 1);
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // Helpers
//   // ─────────────────────────────────────────────

//   String _fileSize(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     return mb < 1
//         ? "${(bytes / 1024).toStringAsFixed(1)} KB"
//         : "${mb.toStringAsFixed(2)} MB";
//   }

//   String? _eta(int total) {
//     if (_startedAt == null || _uploadedBytes < 256 * 1024) return null;

//     final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
//     if (elapsed <= 0) return null;

//     final speed = _uploadedBytes / elapsed;
//     final remaining = total - _uploadedBytes;

//     if (remaining <= 0) return "Finishing…";

//     final seconds = (remaining / speed / 1000).round();
//     return seconds < 60 ? "${seconds}s left" : "${seconds ~/ 60}m left";
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     setState(() {
//       _file = File(result!.files.single.path!);
//       _progress = 0;
//       _uploadedBytes = 0;
//     });
//   }

//   // ─────────────────────────────────────────────
//   // Upload (RESUMABLE + ISOLATE)
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     setState(() {
//       _uploading = true;
//       _startedAt = DateTime.now();
//       _progress = 0.0;
//       _uploadedBytes = 0;
//     });

//     final prefs = await SharedPreferences.getInstance();

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       // ── RESUME CHECK (UI ISOLATE, AUTH SAFE)
//       final existingFileId = prefs.getString(_kActiveFileId);
//       final existingPath = prefs.getString(_kUploadPath);
//       final existingSize = prefs.getInt(_kUploadSize);

//       late final String fileId;

//       if (existingFileId != null &&
//           existingPath == file.path &&
//           existingSize == size) {
//         debugPrint("🔁 Resuming upload: $existingFileId");
//         fileId = existingFileId;
//       } else {
//         debugPrint("🆕 Starting new upload");

//         fileId = await UploadService.startUpload(
//           filename: name,
//           fileSize: size,
//           chunkSize: chunkSize,
//           securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//         );

//         await prefs.setString(_kActiveFileId, fileId);
//         await prefs.setString(_kUploadPath, file.path);
//         await prefs.setInt(_kUploadSize, size);
//       }

//       // ── RESUME DATA (UI ISOLATE)
//       final uploadedChunks = await UploadService.resumeUpload(fileId);

//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: Uint8List.fromList(masterKey),
//         chunkSize: chunkSize,
//         uploadedChunks: uploadedChunks,
//       );

//       // ── RUN WORKER (BLOCKING, SAFE)
//       final isolate = await Isolate.spawn(
//   uploadWorkerEntry,
//   [params, _progressPort.sendPort],
// );

// await _progressPort.firstWhere((_) => false);


//       // ── FINISH ONLY AFTER WORKER COMPLETES
//       await UploadService.finishUpload(fileId);

//       // ── CLEAN UP
//       await prefs.remove(_kActiveFileId);
//       await prefs.remove(_kUploadPath);
//       await prefs.remove(_kUploadSize);

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     } catch (e) {
//       debugPrint("Upload error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _uploading = false);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final total = _file?.lengthSync() ?? 0;
//     final eta = total > 0 ? _eta(total) : null;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const Spacer(),
//             _uploadSection(eta),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n${_fileSize(_file!.lengthSync())}",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadSection(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Uploading…" : "Upload securely",
//               style:
//                   const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(fontSize: 13, color: Colors.grey),
//           ),
//         ],
//       ],
//     );
//   }
// }
// ===============================================================roll back might not have ui =========
// import 'dart:io';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import 'reflex_game.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   bool _uploading = false;
//   double _progress = 0.0;
//   bool _zeroKnowledge = true;
//   bool _doneHandled = false;

//   int _uploadedBytes = 0;
//   int _totalBytes = 1;

//   static const int chunkSize = 2 * 1024 * 1024;

//   late ReceivePort _progressPort;
//   String? _activeFileId;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _progressPort = ReceivePort();
//     _progressPort.listen((msg) async {
//       debugPrint("📩 UI received: $msg");

//       if (!mounted) return;

//       if (msg is int) {
//         _uploadedBytes += msg;
//         setState(() {
//           _progress = _uploadedBytes / _totalBytes;
//         });
//       }

//       if (msg == "DONE" && !_doneHandled) {
//         _doneHandled = true;
//         debugPrint("✅ Worker signaled DONE");
        
        

//         try {
//           await UploadService.finishUpload(_activeFileId!);
//           debugPrint("🏁 finishUpload completed");
//         } catch (e) {
//           debugPrint("❌ finishUpload failed: $e");
//         }

//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const FileListScreen()),
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     final file = File(result!.files.single.path!);

//     setState(() {
//       _file = file;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//     });

//     _totalBytes = await file.length();
//     debugPrint("📂 Picked file: ${file.path}");
//     debugPrint("📏 File size: $_totalBytes bytes");
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     setState(() => _uploading = true);

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     debugPrint("🚀 Starting upload");
//     debugPrint("📄 Filename: $name");
//     debugPrint("🔐 Zero knowledge: $_zeroKnowledge");

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       final fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );

//       _activeFileId = fileId;
//       debugPrint("🆔 file_id = $fileId");

//       final uploadedChunks = await UploadService.resumeUpload(fileId);
//       debugPrint("🔁 Resuming, already uploaded: $uploadedChunks");

//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: masterKey,
//         chunkSize: chunkSize,
//         uploadedChunks: uploadedChunks,
//         accessToken: SecureState.accessToken!,
//       );

//       debugPrint("🧵 Spawning worker isolate");

//       await Isolate.spawn(
//         uploadWorkerEntry,
//         [params, _progressPort.sendPort],
//       );

//       debugPrint("🧵 Worker isolate started");
//     } catch (e, st) {
//       debugPrint("❌ Upload error: $e");
//       debugPrint(st.toString());

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }

//       setState(() => _uploading = false);
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const Spacer(),
//             _uploadSection(null),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n${_totalBytes} bytes",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadSection(String? eta) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _uploading ? null : _upload,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//             ),
//             child: Text(
//               _uploading ? "Uploading…" : "Upload securely",
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),

//         if (_uploading) ...[
//           const SizedBox(height: 16),
//           LinearProgressIndicator(value: _progress),
//           const SizedBox(height: 8),
//           Text(
//             "${(_progress * 100).toStringAsFixed(0)}% • ${eta ?? "Encrypting…"}",
//             style: const TextStyle(fontSize: 13, color: Colors.grey),
//           ),

//           const SizedBox(height: 24),

//           SizedBox(
//             height: 220,
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const ReflexGame(),
//             ),
//           ),
//         ],
//       ],
//     );
//   }

// }
// // ────────────────game in center one─────────────────────────────
// import 'dart:io';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';


// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import 'reflex_game.dart';
// import 'calm_orb_game.dart';

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;

//   bool _uploading = false;
//   bool _zeroKnowledge = true;
//   bool _doneHandled = false;

//   double _progress = 0.0;
//   int _uploadedBytes = 0;
//   int _totalBytes = 1;

//   static const int chunkSize = 2 * 1024 * 1024;

//   late final ReceivePort _progressPort;
//   String? _activeFileId;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _progressPort = ReceivePort();
//     _progressPort.listen(_handleWorkerMessage);
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // Worker → UI messages
//   // ─────────────────────────────────────────────

//   Future<void> _handleWorkerMessage(dynamic msg) async {
//     debugPrint("📩 UI received: $msg");

//     if (!mounted) return;

//     if (msg is int) {
//       _uploadedBytes += msg;
//       setState(() {
//         _progress = _uploadedBytes / _totalBytes;
//       });
//       return;
//     }

//     if (msg == "DONE" && !_doneHandled) {
//       _doneHandled = true;
//       debugPrint("✅ Worker signaled DONE");

//       try {
//         await UploadService.finishUpload(_activeFileId!);
//         debugPrint("🏁 finishUpload completed");
//       } catch (e) {
//         debugPrint("❌ finishUpload failed: $e");
//       }

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const FileListScreen()),
//       );
//     }
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_uploading) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     final file = File(result!.files.single.path!);
//     final size = await file.length();

//     setState(() {
//       _file = file;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//       _totalBytes = size;
//     });

//     debugPrint("📂 Picked file: ${file.path}");
//     debugPrint("📏 File size: $_totalBytes bytes");
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _uploading) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     setState(() {
//       _uploading = true;
//       _doneHandled = false;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//     });

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     debugPrint("🚀 Starting upload");
//     debugPrint("📄 Filename: $name");
//     debugPrint("🔐 Zero knowledge: $_zeroKnowledge");

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       final fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );

//       _activeFileId = fileId;
//       debugPrint("🆔 file_id = $fileId");

//       final uploadedChunks = await UploadService.resumeUpload(fileId);
//       debugPrint("🔁 Resuming, already uploaded: $uploadedChunks");

//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: masterKey,
//         chunkSize: chunkSize,
//         uploadedChunks: uploadedChunks,
//         accessToken: SecureState.accessToken!,
//       );

//       debugPrint("🧵 Spawning worker isolate");

//       await Isolate.spawn(
//         uploadWorkerEntry,
//         [params, _progressPort.sendPort],
//       );

//       debugPrint("🧵 Worker isolate started");
//     } catch (e, st) {
//       debugPrint("❌ Upload error: $e");
//       debugPrint(st.toString());

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }

//       setState(() => _uploading = false);
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const SizedBox(height: 24),

//             if (_uploading) ...[
//               LinearProgressIndicator(value: _progress),
//               const SizedBox(height: 8),
//               Text(
//                 "${(_progress * 100).toStringAsFixed(0)}% • Encrypting & uploading",
//                 style: const TextStyle(fontSize: 13, color: Colors.grey),
//               ),
//               const SizedBox(height: 24),

//               Expanded(
//                 child: Center(
//                   child: Card(
//                     elevation: 6,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.all(24),
//                       child: SizedBox(
//                         width: 260,
//                         child: CalmOrbGame(),
//                         // child: ReflexGame(), //--> for taping the button game 
//                         // child:  FocusRingGame(), // --> for focusing the ring game
//                       ),
//                     ),
//                   ),
//                 ),
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

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n$_totalBytes bytes",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _uploading ? null : (v) => setState(() => _zeroKnowledge = v),
//       ),
//     );
//   }

//   Widget _uploadButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _upload,
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//         ),
//         child: const Text(
//           "Upload securely",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }
// }
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~state machine~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// import 'dart:io';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import 'calm_orb_game.dart';

// /// ─────────────────────────────────────────────
// /// Upload State Machine
// /// ─────────────────────────────────────────────
// enum UploadState {
//   idle,
//   fileSelected,
//   ready,
//   starting,
//   uploading,
//   done,
//   finishing,
//   finished,
//   error,
// }


// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;

//   UploadState _state = UploadState.idle;

//   bool _zeroKnowledge = true;

//   double _progress = 0.0;
//   int _uploadedBytes = 0;
//   int _totalBytes = 1;

//   static const int chunkSize = 2 * 1024 * 1024;

//   late final ReceivePort _progressPort;
//   String? _activeFileId;


  
//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _progressPort = ReceivePort();
//     _progressPort.listen(_handleWorkerMessage);
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // Worker → UI messages
//   // ─────────────────────────────────────────────

//   Future<void> _handleWorkerMessage(dynamic msg) async {
//     debugPrint("📩 UI received: $msg");

//     if (!mounted) return;

//     /// Progress updates
//     if (msg is int && _state == UploadState.uploading) {
//       _uploadedBytes += msg;
//       setState(() {
//         _progress = _uploadedBytes / _totalBytes;
//       });
//       return;
//     }

//     /// DONE signal (only valid in uploading)
//     if (msg == "DONE" && _state == UploadState.uploading) {
//       debugPrint("✅ Worker signaled DONE");

//       setState(() {
//         _state = UploadState.finishing;
//       });

//       try {
//         await UploadService.finishUpload(_activeFileId!);
//         debugPrint("🏁 finishUpload completed");

//         if (!mounted) return;
//         setState(() {
//           _state = UploadState.done;
//         });

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const FileListScreen()),
//         );
//       } catch (e) {
//         debugPrint("❌ finishUpload failed: $e");
//         setState(() {
//           _state = UploadState.error;
//         });
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_state != UploadState.idle) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     final file = File(result!.files.single.path!);
//     final size = await file.length();

//     setState(() {
//       _file = file;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//       _totalBytes = size;
//     });

//     debugPrint("📂 Picked file: ${file.path}");
//     debugPrint("📏 File size: $_totalBytes bytes");
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _state != UploadState.idle) return;

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     setState(() {
//       _state = UploadState.starting;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//     });

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     debugPrint("🚀 Starting upload");
//     debugPrint("📄 Filename: $name");
//     debugPrint("🔐 Zero knowledge: $_zeroKnowledge");

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       final fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );

//       _activeFileId = fileId;
//       debugPrint("🆔 file_id = $fileId");

//       final uploadedChunks = await UploadService.resumeUpload(fileId);
//       debugPrint("🔁 Resuming, already uploaded: $uploadedChunks");

//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: masterKey,
//         chunkSize: chunkSize,
//         uploadedChunks: uploadedChunks,
//         accessToken: SecureState.accessToken!,
//       );

//       setState(() {
//         _state = UploadState.uploading;
//       });

//       debugPrint("🧵 Spawning worker isolate");

//       await Isolate.spawn(
//         uploadWorkerEntry,
//         [params, _progressPort.sendPort],
//       );

//       debugPrint("🧵 Worker isolate started");
//     } catch (e, st) {
//       debugPrint("❌ Upload error: $e");
//       debugPrint(st.toString());

//       setState(() {
//         _state = UploadState.error;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final bool showUploadUI =
//         _state == UploadState.uploading || _state == UploadState.finishing;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const SizedBox(height: 24),

//             if (showUploadUI) ...[
//               LinearProgressIndicator(value: _progress),
//               const SizedBox(height: 8),
//               Text(
//                 "${(_progress * 100).toStringAsFixed(0)}% • Encrypting & uploading",
//                 style: const TextStyle(fontSize: 13, color: Colors.grey),
//               ),
//               const SizedBox(height: 24),

//               Expanded(
//                 child: Center(
//                   child: Card(
//                     elevation: 6,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.all(24),
//                       child: SizedBox(
//                         width: 260,
//                         child: CalmOrbGame(),
//                       ),
//                     ),
//                   ),
//                 ),
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

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n$_totalBytes bytes",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged:
//             _state == UploadState.idle ? (v) => setState(() => _zeroKnowledge = v) : null,
//       ),
//     );
//   }

//   Widget _uploadButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _upload,
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//         ),
//         child: const Text(
//           "Upload securely",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }
// }
// =====================================================================================================
// import 'dart:io';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../../state/upload_retry_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import 'calm_orb_game.dart';

// /// ─────────────────────────────────────────────
// /// Upload State Machine
// /// ─────────────────────────────────────────────
// enum UploadState {
//   idle,
//   fileSelected,
//   starting,
//   uploading,
//   finishing,
//   finished,
//   error,
// }

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;

//   UploadState _state = UploadState.idle;

//   bool _zeroKnowledge = true;

//   double _progress = 0.0;
//   int _uploadedBytes = 0;
//   int _totalBytes = 1;

//   static const int chunkSize = 2 * 1024 * 1024;

//   late final ReceivePort _progressPort;
//   String? _activeFileId;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _progressPort = ReceivePort();
//     _progressPort.listen(_handleWorkerMessage);
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // State transition helper
//   // ─────────────────────────────────────────────

//   void _transitionTo(UploadState next) {
//     debugPrint("🔁 STATE: $_state → $next");
//     setState(() => _state = next);
//   }

//   // ─────────────────────────────────────────────
//   // Worker → UI messages
//   // ─────────────────────────────────────────────

//   Future<void> _handleWorkerMessage(dynamic msg) async {
//     debugPrint("📩 UI received: $msg");

//     if (!mounted) return;

//     // Progress updates
//     if (msg is int && _state == UploadState.uploading) {
//       _uploadedBytes += msg;
//       setState(() {
//         _progress = _uploadedBytes / _totalBytes;
//       });
//       return;
//     }

//     // DONE signal
//     if (msg == "DONE" && _state == UploadState.uploading) {
//       debugPrint("✅ Worker signaled DONE");

//       _transitionTo(UploadState.finishing);

//       try {
//         await UploadService.finishUpload(_activeFileId!);
//         debugPrint("🏁 finishUpload completed");
//         await UploadRetryStore.clear();
//         debugPrint("🧹 RetryStore cleared");


//         if (!mounted) return;
//         _transitionTo(UploadState.finished);

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const FileListScreen()),
//         );
//       } catch (e) {
//         debugPrint("❌ finishUpload failed: $e");
//         _transitionTo(UploadState.error);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_state != UploadState.idle) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     final file = File(result!.files.single.path!);
//     final size = await file.length();

//     setState(() {
//       _file = file;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//       _totalBytes = size;
//     });

//     debugPrint("📂 Picked file: ${file.path}");
//     debugPrint("📏 File size: $_totalBytes bytes");

//     _transitionTo(UploadState.fileSelected);
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   // Future<void> _upload() async {
//   //   if (_file == null || _state != UploadState.fileSelected) {
//   //     debugPrint("⛔ Upload blocked in state $_state");
//   //     return;
//   //   }

//   //   if (SecureState.accessToken == null) {
//   //     Navigator.pushReplacement(
//   //       context,
//   //       MaterialPageRoute(builder: (_) => const LoginScreen()),
//   //     );
//   //     return;
//   //   }

//   //   _transitionTo(UploadState.starting);

//   //   final file = _file!;
//   //   final size = await file.length();
//   //   final name = file.uri.pathSegments.last;

//   //   debugPrint("🚀 Starting upload");
//   //   debugPrint("📄 Filename: $name");
//   //   debugPrint("🔐 Zero knowledge: $_zeroKnowledge");

//   //   try {
//   //     final masterKey = SecureState.requireMasterKey();

//   //     final fileId = await UploadService.startUpload(
//   //       filename: name,
//   //       fileSize: size,
//   //       chunkSize: chunkSize,
//   //       securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//   //     );

//   //     _activeFileId = fileId;
//   //     debugPrint("🆔 file_id = $fileId");

//   //     await UploadRetryStore.save({
//   //       "fileId": fileId,
//   //       "filePath": file.path,
//   //       "fileSize": size,
//   //       "chunkSize": chunkSize,
//   //       "zeroKnowledge": _zeroKnowledge,
//   //       "startedAt": DateTime.now().millisecondsSinceEpoch,
//   //     });

//   //     debugPrint("💾 RetryStore saved");




//   //     final uploadedChunks = await UploadService.resumeUpload(fileId);
//   //     debugPrint("🔁 Resuming, already uploaded: $uploadedChunks");

//   //     final params = UploadTaskParams(
//   //       filePath: file.path,
//   //       fileSize: size,
//   //       fileId: fileId,
//   //       masterKey: masterKey,
//   //       chunkSize: chunkSize,
//   //       uploadedChunks: uploadedMap,
//   //       accessToken: SecureState.accessToken!,
//   //     );

//   //     _transitionTo(UploadState.uploading);

//   //     debugPrint("🧵 Spawning worker isolate");

//   //     await Isolate.spawn(
//   //       uploadWorkerEntry,
//   //       [params, _progressPort.sendPort],
//   //     );

//   //     debugPrint("🧵 Worker isolate started");
//   //   } catch (e, st) {
//   //     debugPrint("❌ Upload error: $e");
//   //     debugPrint(st.toString());

//   //     _transitionTo(UploadState.error);

//   //     if (mounted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text("Upload failed")),
//   //       );
//   //     }
//   //   }
//   // }

//   Future<void> _upload() async {
//   if (_file == null || _state != UploadState.fileSelected) {
//     debugPrint("⛔ Upload blocked in state $_state");
//     return;
//   }

//   if (SecureState.accessToken == null) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//     );
//     return;
//   }

//   _transitionTo(UploadState.starting);

//   final file = _file!;
//   final size = await file.length();
//   final name = file.uri.pathSegments.last;

//   debugPrint("🚀 Starting upload");
//   debugPrint("📄 Filename: $name");
//   debugPrint("🔐 Zero knowledge: $_zeroKnowledge");

//   try {
//     final masterKey = SecureState.requireMasterKey();

//     /// 1️⃣ START UPLOAD (SERVER)
//     final fileId = await UploadService.startUpload(
//       filename: name,
//       fileSize: size,
//       chunkSize: chunkSize,
//       securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//     );

//     _activeFileId = fileId;
//     debugPrint("🆔 file_id = $fileId");

//     /// 2️⃣ RESUME INFO FROM SERVER (Set<int>)
//     final Set<int> uploadedChunks =
//         await UploadService.resumeUpload(fileId);

//     debugPrint("🔁 Resuming, already uploaded: $uploadedChunks");

//     /// 3️⃣ FIX: Convert Set<int> → Map<int, bool>
//     final Map<int, bool> uploadedMap = {
//       for (final index in uploadedChunks) index: true,
//     };

//     /// 4️⃣ SAVE RETRY STATE (CLIENT)
//     await UploadRetryStore.save({
//       "fileId": fileId,
//       "filePath": file.path,
//       "fileSize": size,
//       "chunkSize": chunkSize,
//       "zeroKnowledge": _zeroKnowledge,
//       "uploadedChunks": uploadedMap,
//       "startedAt": DateTime.now().millisecondsSinceEpoch,
//     });

//     debugPrint("💾 RetryStore saved");

//     /// 5️⃣ BUILD WORKER PARAMS
//     final params = UploadTaskParams(
//       filePath: file.path,
//       fileSize: size,
//       fileId: fileId,
//       masterKey: masterKey,
//       chunkSize: chunkSize,
//       uploadedChunks: uploadedMap,
//       accessToken: SecureState.accessToken!,
//     );

//     _transitionTo(UploadState.uploading);

//     debugPrint("🧵 Spawning worker isolate");

//     await Isolate.spawn(
//       uploadWorkerEntry,
//       [params, _progressPort.sendPort],
//     );

//     debugPrint("🧵 Worker isolate started");
//   } catch (e, st) {
//     debugPrint("❌ Upload error: $e");
//     debugPrint(st.toString());

//     _transitionTo(UploadState.error);

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Upload failed")),
//       );
//     }
//   }
// }


//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final bool showUploadUI =
//         _state == UploadState.uploading || _state == UploadState.finishing;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const SizedBox(height: 24),

//             if (showUploadUI) ...[
//               LinearProgressIndicator(value: _progress),
//               const SizedBox(height: 8),
//               Text(
//                 "${(_progress * 100).toStringAsFixed(0)}% • Encrypting & uploading",
//                 style: const TextStyle(fontSize: 13, color: Colors.grey),
//               ),
//               const SizedBox(height: 24),

//               Expanded(
//                 child: Center(
//                   child: Card(
//                     elevation: 6,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.all(24),
//                       child: SizedBox(
//                         width: 260,
//                         child: CalmOrbGame(),
//                       ),
//                     ),
//                   ),
//                 ),
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

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n$_totalBytes bytes",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _state == UploadState.idle
//             ? (v) => setState(() => _zeroKnowledge = v)
//             : null,
//       ),
//     );
//   }

//   Widget _uploadButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _upload,
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//         ),
//         child: const Text(
//           "Upload securely",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }
// }
//=================================================================================================
// import 'dart:io';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../../state/upload_retry_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import 'calm_orb_game.dart';

// /// ─────────────────────────────────────────────
// /// Upload State Machine
// /// ─────────────────────────────────────────────
// enum UploadState {
//   idle,
//   fileSelected,
//   starting,
//   uploading,
//   retrying,
//   finishing,
//   finished,
//   error,
// }

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;
//   UploadState _state = UploadState.idle;

//   bool _zeroKnowledge = true;

//   double _progress = 0.0;
//   int _uploadedBytes = 0;
//   int _totalBytes = 1;

//   static const int chunkSize = 2 * 1024 * 1024;

//   late final ReceivePort _progressPort;
//   String? _activeFileId;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     _progressPort = ReceivePort();
//     _progressPort.listen(_handleWorkerMessage);
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // State helper
//   // ─────────────────────────────────────────────

//   void _transitionTo(UploadState next) {
//     debugPrint("🔁 STATE: $_state → $next");
//     setState(() => _state = next);
//   }

//   // ─────────────────────────────────────────────
//   // Worker → UI messages
//   // ─────────────────────────────────────────────

//   Future<void> _handleWorkerMessage(dynamic msg) async {
//     debugPrint("📩 UI received: $msg");

//     if (!mounted) return;

//     // Progress update
//     if (msg is int && _state == UploadState.uploading) {
//       _uploadedBytes += msg;
//       setState(() {
//         _progress = _uploadedBytes / _totalBytes;
//       });
//       return;
//     }

//     // Worker finished
//     if (msg == "DONE" && _state == UploadState.uploading) {
//       _transitionTo(UploadState.finishing);

//       try {
//         await UploadService.finishUpload(_activeFileId!);
//         await UploadRetryStore.clear();

//         debugPrint("🏁 Upload finished & retry cleared");

//         if (!mounted) return;
//         _transitionTo(UploadState.finished);

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const FileListScreen()),
//         );
//       } catch (e) {
//         debugPrint("❌ finishUpload failed: $e");
//         _transitionTo(UploadState.error);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_state != UploadState.idle) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     final file = File(result!.files.single.path!);
//     final size = await file.length();

//     setState(() {
//       _file = file;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//       _totalBytes = size;
//     });

//     debugPrint("📂 Picked file: ${file.path}");
//     debugPrint("📏 File size: $_totalBytes bytes");

//     _transitionTo(UploadState.fileSelected);
//   }

//   // ─────────────────────────────────────────────
//   // Upload
//   // ─────────────────────────────────────────────

//   Future<void> _upload() async {
//     if (_file == null || _state != UploadState.fileSelected) {
//       debugPrint("⛔ Upload blocked in state $_state");
//       return;
//     }

//     if (SecureState.accessToken == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//       return;
//     }

//     _transitionTo(UploadState.starting);

//     final file = _file!;
//     final size = await file.length();
//     final name = file.uri.pathSegments.last;

//     debugPrint("🚀 Starting upload");
//     debugPrint("📄 Filename: $name");
//     debugPrint("🔐 Zero knowledge: $_zeroKnowledge");

//     try {
//       final masterKey = SecureState.requireMasterKey();

//       /// 1️⃣ Start upload (server)
//       final fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );

//       _activeFileId = fileId;
//       debugPrint("🆔 file_id = $fileId");

//       /// 2️⃣ Resume info (server is source of truth)
//       final Set<int> uploadedSet =
//           await UploadService.resumeUpload(fileId);

//       final Map<int, bool> uploadedMap = {
//         for (final i in uploadedSet) i: true,
//       };

//       debugPrint("🔁 Resuming, already uploaded: $uploadedSet");

//       /// 3️⃣ Save retry metadata (NO SECRETS)
//       await UploadRetryStore.save({
//         "fileId": fileId,
//         "filePath": file.path,
//         "fileSize": size,
//         "chunkSize": chunkSize,
//         "zeroKnowledge": _zeroKnowledge,
//         "startedAt": DateTime.now().millisecondsSinceEpoch,
//       });

//       debugPrint("💾 RetryStore saved");

//       /// 4️⃣ Spawn worker
//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: masterKey,
//         chunkSize: chunkSize,
//         uploadedChunks: uploadedMap,
//         accessToken: SecureState.accessToken!,
//       );

//       _transitionTo(UploadState.uploading);

//       debugPrint("🧵 Spawning worker isolate");

//       await Isolate.spawn(
//         uploadWorkerEntry,
//         [params, _progressPort.sendPort],
//       );
//     } catch (e, st) {
//       debugPrint("❌ Upload error: $e");
//       debugPrint(st.toString());

//       _transitionTo(UploadState.error);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Upload failed")),
//         );
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final showUploadUI =
//         _state == UploadState.uploading || _state == UploadState.finishing;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const SizedBox(height: 24),

//             if (showUploadUI) ...[
//               LinearProgressIndicator(value: _progress),
//               const SizedBox(height: 8),
//               Text(
//                 "${(_progress * 100).toStringAsFixed(0)}% • Encrypting & uploading",
//                 style: const TextStyle(fontSize: 13, color: Colors.grey),
//               ),
//               const SizedBox(height: 24),

//               Expanded(
//                 child: Center(
//                   child: Card(
//                     elevation: 6,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.all(24),
//                       child: SizedBox(
//                         width: 260,
//                         child: CalmOrbGame(),
//                       ),
//                     ),
//                   ),
//                 ),
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

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 42,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n$_totalBytes bytes",
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Silvora never sees your data."),
//         value: _zeroKnowledge,
//         onChanged: _state == UploadState.idle
//             ? (v) => setState(() => _zeroKnowledge = v)
//             : null,
//       ),
//     );
//   }

//   Widget _uploadButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _upload,
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//         ),
//         child: const Text(
//           "Upload securely",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }
// }
//==================================================================================================
// import 'dart:io';
// import 'dart:isolate';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// import '../../services/upload_service.dart';
// import '../../services/upload_worker.dart';
// import '../../state/secure_state.dart';
// import '../../state/upload_retry_state.dart';
// import '../files/file_list_screen.dart';
// import '../login/login_screen.dart';
// import 'calm_orb_game.dart';

// /// ─────────────────────────────────────────────
// /// Upload State Machine
// /// ─────────────────────────────────────────────
// enum UploadState {
//   idle,
//   fileSelected,
//   starting,
//   uploading,
//   retrying,
//   finishing,
//   finished,
//   error,
// }

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _file;

//   UploadState _state = UploadState.idle;

//   bool _zeroKnowledge = true;

//   double _progress = 0.0;
//   int _uploadedBytes = 0;
//   int _totalBytes = 1;

//   static const int chunkSize = 2 * 1024 * 1024;

//   static const int maxRetries = 1;
//   int _retryCount = 0;

//   late final ReceivePort _progressPort;
//   String? _activeFileId;

//   // ─────────────────────────────────────────────
//   // Lifecycle
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     _progressPort = ReceivePort();
//     _progressPort.listen(_handleWorkerMessage);
//   }

//   @override
//   void dispose() {
//     _progressPort.close();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // State transition helper
//   // ─────────────────────────────────────────────

//   void _transitionTo(UploadState next) {
//     debugPrint("🔁 STATE: $_state → $next");
//     setState(() => _state = next);
//   }

//   // ─────────────────────────────────────────────
//   // Worker → UI messages
//   // ─────────────────────────────────────────────

//   Future<void> _handleWorkerMessage(dynamic msg) async {
//     if (!mounted) return;

//     debugPrint("📩 UI received: $msg");

//     // Progress
//     if (msg is int && _state == UploadState.uploading) {
//       _uploadedBytes += msg;
//       setState(() {
//         _progress = _uploadedBytes / _totalBytes;
//       });
//       return;
//     }

//     // Chunk failure
//     if (msg is Map && msg["type"] == "CHUNK_ERROR") {
//       debugPrint("⚠️ Chunk error at ${msg["chunkIndex"]}");

//       if (_retryCount < maxRetries) {
//         _retryCount++;
//         _transitionTo(UploadState.retrying);
//         _retryUpload();
//       } else {
//         _transitionTo(UploadState.error);
//         _showRetryDialog();
//       }
//       return;
//     }

//     // Upload complete
//     if (msg == "DONE" && _state == UploadState.uploading) {
//       _transitionTo(UploadState.finishing);

//       try {
//         await UploadService.finishUpload(_activeFileId!);
//         await UploadRetryStore.clear();

//         _transitionTo(UploadState.finished);

//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const FileListScreen()),
//         );
//       } catch (e) {
//         debugPrint("❌ finishUpload failed: $e");
//         _transitionTo(UploadState.error);
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // Pick file
//   // ─────────────────────────────────────────────

//   Future<void> _pickFile() async {
//     if (_state != UploadState.idle) return;

//     final result = await FilePicker.platform.pickFiles();
//     if (result?.files.single.path == null) return;

//     final file = File(result!.files.single.path!);
//     final size = await file.length();

//     setState(() {
//       _file = file;
//       _uploadedBytes = 0;
//       _progress = 0.0;
//       _totalBytes = size;
//       _retryCount = 0;
//     });

//     debugPrint("📂 Picked file: ${file.path}");
//     debugPrint("📏 File size: $_totalBytes bytes");

//     _transitionTo(UploadState.fileSelected);
//   }

//   // ─────────────────────────────────────────────
//   // Upload start
//   // ─────────────────────────────────────────────

// Future<void> _upload() async {
//   if (_file == null || _state != UploadState.fileSelected) {
//     debugPrint("⛔ Upload blocked in state $_state");
//     return;
//   }

//   if (SecureState.accessToken == null) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//     );
//     return;
//   }

//   // ✅ FIX: initialize UploadService token
//   UploadService.setAccessToken(SecureState.accessToken!);

//   _transitionTo(UploadState.starting);

//   final file = _file!;
//   final size = await file.length();
//   final name = file.uri.pathSegments.last;


//     try {
//       final masterKey = SecureState.requireMasterKey();

//       final fileId = await UploadService.startUpload(
//         filename: name,
//         fileSize: size,
//         chunkSize: chunkSize,
//         securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
//       );

//       _activeFileId = fileId;

//       final uploadedSet = await UploadService.resumeUpload(fileId);
//       final uploadedMap = {
//         for (final i in uploadedSet) i: true,
//       };

//       await UploadRetryStore.save({
//         "fileId": fileId,
//         "filePath": file.path,
//         "fileSize": size,
//         "chunkSize": chunkSize,
//         "uploadedChunks": uploadedMap,
//         "zeroKnowledge": _zeroKnowledge,
//       });

//       final params = UploadTaskParams(
//         filePath: file.path,
//         fileSize: size,
//         fileId: fileId,
//         masterKey: masterKey,
//         chunkSize: chunkSize,
//         uploadedChunks: uploadedMap,
//         accessToken: SecureState.accessToken!,
//       );

//       _transitionTo(UploadState.uploading);

//       await Isolate.spawn(
//         uploadWorkerEntry,
//         [params, _progressPort.sendPort],
//       );
//     } catch (e, st) {
//       debugPrint("❌ Upload error: $e");
//       debugPrint(st.toString());
//       _transitionTo(UploadState.error);
//     }
//   }

//   // ─────────────────────────────────────────────
//   // Auto retry
//   // ─────────────────────────────────────────────

//   Future<void> _retryUpload() async {
//     if (_activeFileId == null || _file == null) return;

//     final uploadedSet =
//         await UploadService.resumeUpload(_activeFileId!);

//     final uploadedMap = {
//       for (final i in uploadedSet) i: true,
//     };

//     final params = UploadTaskParams(
//       filePath: _file!.path,
//       fileSize: _totalBytes,
//       fileId: _activeFileId!,
//       masterKey: SecureState.requireMasterKey(),
//       chunkSize: chunkSize,
//       uploadedChunks: uploadedMap,
//       accessToken: SecureState.accessToken!,
//     );

//     _transitionTo(UploadState.uploading);

//     await Isolate.spawn(
//       uploadWorkerEntry,
//       [params, _progressPort.sendPort],
//     );
//   }

//   // ─────────────────────────────────────────────
//   // Ask user after retry
//   // ─────────────────────────────────────────────

//   void _showRetryDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         title: const Text("Upload paused"),
//         content: const Text(
//           "Connection was interrupted. Retry upload?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _retryCount = 0;
//               _retryUpload();
//             },
//             child: const Text("Retry"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _transitionTo(UploadState.error);
//             },
//             child: const Text("Cancel"),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final uploading =
//         _state == UploadState.uploading ||
//         _state == UploadState.retrying ||
//         _state == UploadState.finishing;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Secure Upload")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _filePickerCard(),
//             const SizedBox(height: 16),
//             _encryptionCard(),
//             const SizedBox(height: 24),

//             if (uploading) ...[
//               LinearProgressIndicator(value: _progress),
//               const SizedBox(height: 8),
//               Text(
//                 "${(_progress * 100).toStringAsFixed(0)}% • Uploading",
//                 style: const TextStyle(fontSize: 13, color: Colors.grey),
//               ),
//               const SizedBox(height: 24),
//               const Expanded(
//                 child: Center(child: CalmOrbGame()),
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

//   Widget _filePickerCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Row(
//             children: [
//               const Icon(Icons.cloud_upload_rounded, size: 42),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   _file == null
//                       ? "Choose a file to upload"
//                       : "${_file!.uri.pathSegments.last}\n$_totalBytes bytes",
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _encryptionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: SwitchListTile(
//         title: const Text("Zero-knowledge encryption"),
//         subtitle:
//             const Text("Encrypted locally. Server never sees your data."),
//         value: _zeroKnowledge,
//         onChanged:
//             _state == UploadState.idle ? (v) => setState(() => _zeroKnowledge = v) : null,
//       ),
//     );
//   }

//   Widget _uploadButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _upload,
//         child: const Text("Upload securely"),
//       ),
//     );
//   }
// }
//====================old one is good and feels like stable ========================================
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/upload_service.dart';
import '../../services/upload_worker.dart';
import '../../state/secure_state.dart';
import '../../state/upload_retry_state.dart';
import '../files/file_list_screen.dart';
import '../login/login_screen.dart';
import 'calm_orb_game.dart';

enum UploadState {
  idle,
  fileSelected,
  starting,
  uploading,
  finishing,
  finished,
  error,
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _file;
  UploadState _state = UploadState.idle;

  bool _zeroKnowledge = true;

  double _progress = 0.0;
  int _uploadedBytes = 0;
  int _totalBytes = 1;

  static const int chunkSize = 2 * 1024 * 1024;

  late final ReceivePort _progressPort;
  String? _activeFileId;

  @override
  void initState() {
    super.initState();
    _progressPort = ReceivePort();
    _progressPort.listen(_handleWorkerMessage);
  }

  @override
  void dispose() {
    _progressPort.close();
    super.dispose();
  }

  void _transitionTo(UploadState next) {
    debugPrint("🔁 STATE: $_state → $next");
    setState(() => _state = next);
  }

  Future<void> _handleWorkerMessage(dynamic msg) async {
    if (!mounted) return;

    if (msg is int && _state == UploadState.uploading) {
      _uploadedBytes += msg;
      setState(() {
        _progress = _uploadedBytes / _totalBytes;
      });
      return;
    }

    if (msg is Map && msg["type"] == "FATAL_CHUNK_ERROR") {
      _transitionTo(UploadState.error);
      _showRetryDialog();
      return;
    }

    if (msg == "DONE" && _state == UploadState.uploading) {
      _transitionTo(UploadState.finishing);

      await UploadService.finishUpload(_activeFileId!);
      await UploadRetryStore.clear();

      if (!mounted) return;
      _transitionTo(UploadState.finished);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FileListScreen()),
      );
    }
  }

  Future<void> _pickFile() async {
    if (_state != UploadState.idle) return;

    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path == null) return;

    final file = File(result!.files.single.path!);
    final size = await file.length();

    setState(() {
      _file = file;
      _uploadedBytes = 0;
      _progress = 0.0;
      _totalBytes = size;
    });

    _transitionTo(UploadState.fileSelected);
  }

  Future<void> _upload() async {
    if (_file == null || _state != UploadState.fileSelected) return;

    if (SecureState.accessToken == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    _transitionTo(UploadState.starting);

    final file = _file!;
    final size = await file.length();
    final name = file.uri.pathSegments.last;

    final masterKey = SecureState.requireMasterKey();

    final fileId = await UploadService.startUpload(
      filename: name,
      fileSize: size,
      chunkSize: chunkSize,
      securityMode: _zeroKnowledge ? "zero_knowledge" : "standard",
    );

    _activeFileId = fileId;

    final uploadedSet = await UploadService.resumeUpload(fileId);
    final uploadedMap = {for (final i in uploadedSet) i: true};

    await UploadRetryStore.save({
      "fileId": fileId,
      "filePath": file.path,
      "fileSize": size,
      "chunkSize": chunkSize,
      "zeroKnowledge": _zeroKnowledge,
      "uploadedChunks": uploadedMap,
    });

    final params = UploadTaskParams(
      filePath: file.path,
      fileSize: size,
      fileId: fileId,
      masterKey: Uint8List.fromList(masterKey),
      chunkSize: chunkSize,
      uploadedChunks: uploadedMap,
      accessToken: SecureState.accessToken!,
    );

    _transitionTo(UploadState.uploading);

    await Isolate.spawn(
      uploadWorkerEntry,
      [params, _progressPort.sendPort],
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Upload interrupted"),
        content: const Text(
          "Connection was lost.\n\nRetry from where it stopped?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              UploadRetryStore.clear();
              _transitionTo(UploadState.idle);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _transitionTo(UploadState.fileSelected);
              _upload();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploading =
        _state == UploadState.uploading || _state == UploadState.finishing;

    return Scaffold(
      appBar: AppBar(title: const Text("Secure Upload")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _filePickerCard(),
            const SizedBox(height: 16),
            _encryptionCard(),
            const SizedBox(height: 24),

            if (uploading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text("${(_progress * 100).toStringAsFixed(0)}%"),
              const SizedBox(height: 24),
              const Expanded(child: CalmOrbGame()),
            ] else ...[
              const Spacer(),
              _uploadButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filePickerCard() => Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_upload),
          title: Text(_file == null
              ? "Choose file"
              : _file!.uri.pathSegments.last),
          onTap: _pickFile,
        ),
      );

  Widget _encryptionCard() => SwitchListTile(
        title: const Text("Zero-knowledge encryption"),
        value: _zeroKnowledge,
        onChanged: _state == UploadState.idle
            ? (v) => setState(() => _zeroKnowledge = v)
            : null,
      );

  Widget _uploadButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _upload,
          child: const Text("Upload securely"),
        ),
      );
}

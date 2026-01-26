// import 'dart:convert';
// import 'dart:typed_data';

// import '../../crypto/file_key.dart';
// import '../../crypto/chunk_crypto.dart';
// import '../../state/secure_state.dart';
// import '../../services/api_services.dart';

// class PreviewService {
//   static Future<Uint8List> loadAndDecrypt(String fileId) async {
//     final manifest = await ApiService.fetchManifest(fileId);
//     final encrypted = await ApiService.fetchEncryptedData(fileId);

//     final masterKey = SecureState.requireMasterKey();
//     final fileKey = await deriveFileKey(
//       masterKey: masterKey,
//       fileId: fileId,
//     );

//     final out = BytesBuilder();

//     for (final c in manifest.chunks) {
//       final cipher = encrypted.sublist(
//         c.offset,
//         c.offset + c.ciphertextSize,
//       );

//       final plain = await decryptChunk(
//         key: fileKey,
//         cipher: cipher,
//         nonce: base64Decode(c.nonceB64),
//         mac: base64Decode(c.macB64),
//       );

//       out.add(plain);
//     }

//     return out.toBytes();
//   }
// }



// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';

// import '../../crypto/xchacha.dart';
// import '../../crypto/hkdf.dart';
// import '../../services/api_services.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   Uint8List? _plainBytes;
//   bool _loading = true;
//   String? _error;

//   final _crypto = XChaCha();

//   @override
//   void initState() {
//     super.initState();
//     _loadAndDecrypt();
//   }

//   Future<void> _loadAndDecrypt() async {
//     try {
//       // 1️⃣ Fetch manifest
//       final Map<String, dynamic> manifest =
//           await ApiService.fetchManifest(widget.fileId);

//       final List<dynamic> chunks =
//           List<Map<String, dynamic>>.from(manifest['chunks']);

//       // 2️⃣ Fetch encrypted blob (final.bin)
//       final Uint8List encrypted =
//           await ApiService.fetchEncryptedData(widget.fileId);

//       // 3️⃣ Get master key (memory only)
//       final Uint8List masterKey = SecureState.requireMasterKey();

//       final BytesBuilder output = BytesBuilder();

//       // 4️⃣ Decrypt chunk-by-chunk using offsets
//       for (final c in chunks) {
//         final int index = c['index'];
//         final int offset = c['offset'];
//         final int size = c['ciphertext_size'];

//         debugPrint(
//           'Decrypt chunk $index offset=$offset size=$size',
//         );

//         final Uint8List cipherChunk =
//             encrypted.sublist(offset, offset + size);

//         final Uint8List nonce =
//             base64Decode(c['nonce_b64']);
//         final Uint8List mac =
//             base64Decode(c['mac_b64']);

//         // Derive per-chunk key
//         final Uint8List chunkKey = await hkdfSha256(
//           ikm: masterKey,
//           info: utf8.encode('silvora-chunk-$index'),
//         );

//         final Uint8List plain = await _crypto.decrypt(
//           ciphertext: cipherChunk,
//           nonce: nonce,
//           mac: mac,
//           key: chunkKey,
//         );

//         output.add(plain);
//       }

//       final Uint8List result = output.toBytes();

//       // 5️⃣ Hard invariant check (CRITICAL)
//       if (result.length != manifest['file_size']) {
//         throw StateError(
//           'Size mismatch: decrypted=${result.length} '
//           'expected=${manifest['file_size']}',
//         );
//       }

//       if (!mounted) return;

//       setState(() {
//         _plainBytes = result;
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = e.toString();
//         _loading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     // 🔐 Zero memory
//     _plainBytes?.fillRange(0, _plainBytes!.length, 0);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Center(
//           child: Text(
//             _error!,
//             textAlign: TextAlign.center,
//           ),
//         ),
//       );
//     }

//     // PDF preview
//     if (widget.filename.toLowerCase().endsWith('.pdf')) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: PDFView(
//           pdfData: _plainBytes!,
//         ),
//       );
//     }

//     // Image preview
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.filename)),
//       body: InteractiveViewer(
//         child: Image.memory(_plainBytes!),
//       ),
//     );
//   }
// }


// ======================================================================================================
// import 'dart:typed_data';
// import 'package:flutter/material.dart';

// import '../../services/download_service.dart';
// import '../../crypto/file_decryptor.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   bool _loading = true;
//   String? _error;
//   Uint8List? _plaintext;

//   @override
//   void initState() {
//     super.initState();
//     _loadAndDecrypt();
//   }

//   Future<void> _loadAndDecrypt() async {
//     try {
//       // 1️⃣ Ensure vault is unlocked
//       final masterKey = SecureState.requireMasterKey();

//       // 2️⃣ Fetch manifest
//       final manifest =
//           await DownloadService.fetchManifest(widget.fileId);

//       // 3️⃣ Fetch encrypted file
//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);

//       // 4️⃣ Decrypt file
//       final decryptor = FileDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );

//       final plain = await decryptor.decrypt(encrypted);

//       setState(() {
//         _plaintext = plain;
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.filename)),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//               ? Center(child: Text("Preview failed:\n$_error"))
//               : _buildPreview(),
//     );
//   }

//   Widget _buildPreview() {
//     // TEMP: raw bytes preview confirmation
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Text(
//         "Decrypted ${_plaintext!.length} bytes successfully",
//         style: const TextStyle(fontSize: 16),
//       ),
//     );
//   }
// }
// =========================================================================
// lib/screens/files/file_preview_screen.dart
// lib/screens/files/file_preview_screen.dart
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';

// import '../../crypto/file_decryptor.dart';
// import '../../services/download_service.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   Uint8List? _plain;
//   bool _loading = true;
//   String? _error;
//   String _phase = "init";

//   @override
//   void initState() {
//     super.initState();
//     debugPrint("🟢 PREVIEW INIT for ${widget.filename}");
//     _load();
//   }

//   Future<void> _load() async {
//     try {
//       // ===============================
//       // Phase 1 — Master key check
//       // ===============================
//       _phase = "vault";
//       final masterKey = SecureState.requireMasterKey();
//       debugPrint("🔑 Master key OK (len=${masterKey.length})");

//       // ===============================
//       // Phase 2 — Fetch manifest
//       // ===============================
//       _phase = "manifest";
//       debugPrint("📄 Fetching manifest for ${widget.fileId}");
//       final manifest =
//       await DownloadService.fetchManifest(widget.fileId);

//       final chunks = (manifest["chunks"] as List?) ?? [];
//       debugPrint("📄 Manifest loaded: chunks=${chunks.length}");

//       // ===============================
//       // Phase 3 — Fetch encrypted data
//       // ===============================
//       _phase = "download";
//       debugPrint("📦 Fetching encrypted data");
//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);
//       debugPrint("📦 Encrypted bytes: ${encrypted.length}");

//       if (encrypted.isEmpty) {
//         throw StateError("Encrypted payload is empty");
//       }

//       // ===============================
//       // Phase 4 — Decrypt
//       // ===============================
//       _phase = "decrypt";
//       debugPrint("🔓 Starting decryption");

//       final decryptor = FileDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );

//       final plain = await decryptor.decrypt(encrypted);
//       debugPrint("🔓 Decryption complete");

//       if (plain.isEmpty) {
//         throw StateError("Decrypted payload is empty");
//       }

//       // ===============================
//       // Phase 5 — Validate magic header
//       // ===============================
//       _phase = "validate";
//       final headerLen = plain.length >= 8 ? 8 : plain.length;
//       final header = plain.sublist(0, headerLen);
//       debugPrint("🔎 Header bytes: $header");

//       final name = widget.filename.toLowerCase();
//       if (name.endsWith(".pdf") && !(String.fromCharCodes(header).startsWith("%PDF"))) {
//         debugPrint("⚠️ PDF header mismatch");
//       }
//       if ((name.endsWith(".jpg") || name.endsWith(".jpeg")) &&
//           !(header[0] == 0xFF && header[1] == 0xD8)) {
//         debugPrint("⚠️ JPEG header mismatch");
//       }
//       if (name.endsWith(".png") &&
//           !(header[0] == 0x89 && header[1] == 0x50)) {
//         debugPrint("⚠️ PNG header mismatch");
//       }

//       // ===============================
//       // Phase 6 — Commit to UI
//       // ===============================
//       if (!mounted) return;
//       setState(() {
//         _plain = plain;
//         _loading = false;
//         _phase = "done";
//       });

//       debugPrint("✅ PREVIEW READY");

//     } catch (e, st) {
//       debugPrint("❌ PREVIEW FAILED at phase=$_phase");
//       debugPrint("❌ Error: $e");
//       debugPrintStack(stackTrace: st);

//       if (!mounted) return;
//       setState(() {
//         _error = "Preview failed at phase: $_phase\n$e";
//         _loading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     if (_plain != null) {
//       _plain!.fillRange(0, _plain!.length, 0);
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 12),
//               Text("Phase: $_phase"),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             _error!,
//             style: const TextStyle(color: Colors.red),
//           ),
//         ),
//       );
//     }

//     final name = widget.filename.toLowerCase();

//     // ===============================
//     // PDF
//     // ===============================
//     if (name.endsWith(".pdf")) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: PDFView(
//           pdfData: _plain!,
//           enableSwipe: true,
//           swipeHorizontal: false,
//         ),
//       );
//     }

//     // ===============================
//     // Image
//     // ===============================
//     if (name.endsWith(".jpg") ||
//         name.endsWith(".jpeg") ||
//         name.endsWith(".png")) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: InteractiveViewer(
//           child: Image.memory(_plain!),
//         ),
//       );
//     }

//     // ===============================
//     // Unsupported
//     // ===============================
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.filename)),
//       body: const Center(
//         child: Text("Unsupported file type"),
//       ),
//     );
//   }
// }


// ===============================================new arcitecture ================================================
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:path_provider/path_provider.dart';

// import 'hkdf.dart';

// class FileStreamDecryptor {
//   final Uint8List masterKey;
//   final Map<String, dynamic> manifest;

//   final Xchacha20 _algo = Xchacha20.poly1305Aead();

//   FileStreamDecryptor({
//     required this.masterKey,
//     required this.manifest,
//   });

//   Future<File> decryptToTempFile(Uint8List encryptedData) async {
//     final tmpDir = await getTemporaryDirectory();
//     final outFile = File(
//       "${tmpDir.path}/${manifest['filename']}",
//     );

//     final raf = outFile.openSync(mode: FileMode.write);

//     try {
//       final chunks = List<Map<String, dynamic>>.from(
//         manifest['chunks'],
//       );

//       for (final chunk in chunks) {
//         final index = chunk['index'] as int;
//         final offset = chunk['offset'] as int;
//         final size = chunk['ciphertext_size'] as int;

//         final nonce = Uint8List.fromList(
//           Uri.decodeComponent(chunk['nonce_b64'])
//               .codeUnits,
//         );

//         final mac = Uint8List.fromList(
//           Uri.decodeComponent(chunk['mac_b64'])
//               .codeUnits,
//         );

//         final cipherSlice = encryptedData.sublist(
//           offset,
//           offset + size,
//         );

//         final derivedKey = await hkdfSha256(
//           ikm: masterKey,
//           info: "silvora-chunk-$index".codeUnits,
//         );

//         final box = SecretBox(
//           cipherSlice,
//           nonce: nonce,
//           mac: Mac(mac),
//         );

//         final plain = await _algo.decrypt(
//           box,
//           secretKey: SecretKey(derivedKey),
//         );

//         raf.writeFromSync(plain);
//       }
//     } finally {
//       raf.closeSync();
//     }

//     return outFile;
//   }
// }
// =================================================================================================================

// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';
// import 'package:path_provider/path_provider.dart';

// import '../../crypto/hkdf.dart';

// class FileStreamDecryptor {
//   final Uint8List masterKey;
//   final Map<String, dynamic> manifest;

//   final Xchacha20 _algo = Xchacha20.poly1305Aead();

//   FileStreamDecryptor({
//     required this.masterKey,
//     required this.manifest,
//   });

//   Future<File> decryptToTempFile(Uint8List encryptedData) async {
//     final tmpDir = await getTemporaryDirectory();
//     final outFile = File("${tmpDir.path}/${manifest['filename']}");

//     final raf = outFile.openSync(mode: FileMode.write);

//     try {
//       final chunks = List<Map<String, dynamic>>.from(
//         manifest['chunks'],
//       );

//       for (final chunk in chunks) {
//         final int index = chunk['index'];
//         final int offset = chunk['offset'];
//         final int size = chunk['ciphertext_size'];

//         // ✅ CORRECT Base64 decoding
//         final nonce = base64Decode(chunk['nonce_b64']);
//         final mac = base64Decode(chunk['mac_b64']);

//         final cipherSlice = encryptedData.sublist(
//           offset,
//           offset + size,
//         );

//         // 🔑 Same HKDF as upload
//         final derivedKey = await hkdfSha256(
//           ikm: masterKey,
//           info: utf8.encode("silvora-chunk-$index"),
//         );

//         final box = SecretBox(
//           cipherSlice,
//           nonce: nonce,
//           mac: Mac(mac),
//         );

//         final plain = await _algo.decrypt(
//           box,
//           secretKey: SecretKey(derivedKey),
//         );

//         raf.writeFromSync(plain);
//       }
//     } finally {
//       raf.closeSync();
//     }

//     return outFile;
//   }
// }
// =========================================================================
// lib/crypto/file_stream_decryptor.dart

// import 'dart:io';

// import 'package:flutter/material.dart';

// import '../../crypto/file_stream_decryptor.dart';
// import '../../services/download_service.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   bool _loading = true;
//   String? _error;
//   File? _previewFile;

//   @override
//   void initState() {
//     super.initState();
//     _loadPreview();
//   }

//   Future<void> _loadPreview() async {
//     try {
//       debugPrint("🟢 PREVIEW INIT for ${widget.filename}");

//       final masterKey = SecureState.requireMasterKey();
//       debugPrint("🔑 Master key OK (len=${masterKey.length})");

//       final manifest =
//           await DownloadService.fetchManifest(widget.fileId);
//       debugPrint("📄 Manifest loaded: chunks=${manifest['chunks'].length}");

//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);
//       debugPrint("📦 Encrypted bytes: ${encrypted.length}");

//       final decryptor = FileStreamDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );
//       // debugPrint("nonce.len=${nonce.length} mac.len=${mac.length}");

//       final file = await decryptor.decryptToTempFile(encrypted);
//       debugPrint("🔓 Decryption complete → ${file.path}");

//       if (!mounted) return;
//       setState(() {
//         _previewFile = file;
//         _loading = false;
//       });
//     } catch (e, st) {
//       debugPrint("❌ PREVIEW FAILED");
//       debugPrint(e.toString());
//       debugPrint(st.toString());

//       if (!mounted) return;
//       setState(() {
//         _error = "Preview failed";
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Center(child: Text(_error!)),
//       );
//     }

//     // 🔥 SIMPLE FILE-BASED PREVIEW (image / pdf later)
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.filename)),
//       body : widget.filename.toLowerCase().endsWith(".png") ||
//         widget.filename.toLowerCase().endsWith(".jpg") ||
//         widget.filename.toLowerCase().endsWith(".jpeg")
//     ? Image.file(_previewFile!): Center(
//         child: Text(
//           "Decrypted to:\n${_previewFile!.path}",
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }


// import 'dart:io';

// import 'package:flutter/material.dart';

// import '../../crypto/file_stream_decryptor.dart';
// import '../../services/download_service.dart';
// import '../../state/secure_state.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';  

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   bool _loading = true;
//   String? _error;
//   File? _previewFile;

//   // ─────────────────────────────────────────────
//   // LIFECYCLE
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("📂 FilePreviewScreen mounted");
//     debugPrint("📄 fileId   = ${widget.fileId}");
//     debugPrint("📄 filename = ${widget.filename}");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     _loadPreview();
//   }

//   @override
//   void dispose() {
//     debugPrint("🧹 FilePreviewScreen dispose()");
//     if (_previewFile != null && _previewFile!.existsSync()) {
//       debugPrint("🧹 Deleting temp file: ${_previewFile!.path}");
//       _previewFile!.deleteSync();
//     }
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // PREVIEW PIPELINE
//   // ─────────────────────────────────────────────

//   Future<void> _loadPreview() async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       // ───── Phase 1: Key availability ─────
//       debugPrint("🟢 [1/5] PREVIEW INIT");

//       final masterKey = SecureState.requireMasterKey();
//       debugPrint("🔑 Master key OK");
//       debugPrint("🔑 key.length = ${masterKey.length}");

//       // ───── Phase 2: Manifest fetch ─────
//       debugPrint("🟢 [2/5] Fetching manifest");
//       final manifest =
//           await DownloadService.fetchManifest(widget.fileId);

//       debugPrint("📄 Manifest loaded");
//       debugPrint("📄 chunks     = ${manifest['chunks']?.length}");
//       debugPrint("📄 file_size  = ${manifest['file_size']}");
//       debugPrint("📄 algorithm  = ${manifest['aead_algorithm']}");

//       // ───── Phase 3: Encrypted payload ─────
//       debugPrint("🟢 [3/5] Fetching encrypted data");
//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);

//       debugPrint("📦 Encrypted bytes received = ${encrypted.length}");

//       if (encrypted.isEmpty) {
//         throw StateError("Encrypted payload is empty");
//       }

//       // ───── Phase 4: Decryption ─────
//       debugPrint("🟢 [4/5] Starting file-stream decryption");

//       final decryptor = FileStreamDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );

//       final file = await decryptor.decryptToTempFile(encrypted);

//       debugPrint("🔓 Decryption completed");
//       debugPrint("📁 Temp file path = ${file.path}");
//       debugPrint("📁 File exists   = ${file.existsSync()}");
//       debugPrint("📁 File size     = ${file.lengthSync()} bytes");

//       if (!file.existsSync()) {
//         throw StateError("Decrypted file does not exist on disk");
//       }

//       // ───── Phase 5: UI ready ─────
//       debugPrint("🟢 [5/5] Preview ready");
//       debugPrint("⏱ Total time = ${stopwatch.elapsedMilliseconds} ms");

//       if (!mounted) return;
//       setState(() {
//         _previewFile = file;
//         _loading = false;
//       });
//     } catch (e, st) {
//       debugPrint("❌ PREVIEW FAILED");
//       debugPrint("❌ Error: $e");
//       debugPrint("❌ Stacktrace:");
//       debugPrint(st.toString());

//       if (!mounted) return;
//       setState(() {
//         _error = "Preview failed";
//         _loading = false;
//       });
//     }
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────


//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       debugPrint("⏳ UI: loading state");
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_error != null) {
//       debugPrint("⚠️ UI: error state → $_error");
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Center(child: Text(_error!)),
//       );
//     }

//     debugPrint("🖼 UI: rendering preview");

//     final lower = widget.filename.toLowerCase();

//     return Scaffold(
//       appBar: AppBar(title: Text(widget.filename)),
//       body: lower.endsWith(".png") ||
//               lower.endsWith(".jpg") ||
//               lower.endsWith(".jpeg")
//           ? Image.file(
//               _previewFile!,
//               fit: BoxFit.contain,
//               errorBuilder: (_, __, ___) {
//                 debugPrint("❌ Image widget failed to render");
//                 return const Center(child: Text("Image render failed"));
//               },
//             )
//           : Center(
//               child: Text(
//                 "Decrypted to:\n${_previewFile!.path}",
//                 textAlign: TextAlign.center,
//               ),
//             ),
//     );
//   }
// }
// =============================================================================
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';

// import '../../crypto/file_stream_decryptor.dart';
// import '../../services/download_service.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   bool _loading = true;
//   String? _error;
//   File? _previewFile;

//   // ─────────────────────────────────────────────
//   // LIFECYCLE
//   // ─────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("📂 FilePreviewScreen mounted");
//     debugPrint("📄 fileId   = ${widget.fileId}");
//     debugPrint("📄 filename = ${widget.filename}");
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

//     _loadPreview();
//   }

//   @override
//   void dispose() {
//     debugPrint("🧹 FilePreviewScreen dispose()");

//     if (_previewFile != null && _previewFile!.existsSync()) {
//       debugPrint("🧹 Deleting temp file: ${_previewFile!.path}");
//       try {
//         _previewFile!.deleteSync();
//       } catch (e) {
//         debugPrint("⚠️ Temp file delete failed: $e");
//       }
//     }

//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // PREVIEW PIPELINE
//   // ─────────────────────────────────────────────

//   Future<void> _loadPreview() async {
//     final stopwatch = Stopwatch()..start();

//     try {
//       // ───── Phase 1: Master key ─────
//       debugPrint("🟢 [1/5] PREVIEW INIT");

//       final masterKey = SecureState.requireMasterKey();
//       debugPrint("🔑 Master key OK");
//       debugPrint("🔑 key.length = ${masterKey.length}");

//       // ───── Phase 2: Manifest ─────
//       debugPrint("🟢 [2/5] Fetching manifest");

//       final manifest =
//           await DownloadService.fetchManifest(widget.fileId);

//       debugPrint("📄 Manifest loaded");
//       debugPrint("📄 chunks     = ${manifest['chunks']?.length}");
//       debugPrint("📄 file_size  = ${manifest['file_size']}");
//       debugPrint("📄 algorithm  = ${manifest['aead_algorithm']}");

//       if (manifest['chunks'] == null || manifest['chunks'].isEmpty) {
//         throw StateError("Manifest has no chunks");
//       }

//       // ───── Phase 3: Encrypted data ─────
//       debugPrint("🟢 [3/5] Fetching encrypted data");

//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);

//       debugPrint("📦 Encrypted bytes received = ${encrypted.length}");

//       if (encrypted.isEmpty) {
//         throw StateError("Encrypted payload is empty");
//       }

//       // ───── Phase 4: Decryption ─────
//       debugPrint("🟢 [4/5] Starting file-stream decryption");

//       final decryptor = FileStreamDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );

//       final file = await decryptor.decryptToTempFile(encrypted);

//       debugPrint("🔓 Decryption completed");
//       debugPrint("📁 Temp file path = ${file.path}");
//       debugPrint("📁 File exists   = ${file.existsSync()}");
//       debugPrint("📁 File size     = ${file.lengthSync()} bytes");

//       if (!file.existsSync()) {
//         throw StateError("Decrypted file missing on disk");
//       }

//       // ───── Phase 5: UI ready ─────
//       debugPrint("🟢 [5/5] Preview ready");
//       debugPrint("⏱ Total time = ${stopwatch.elapsedMilliseconds} ms");

//       if (!mounted) return;
//       setState(() {
//         _previewFile = file;
//         _loading = false;
//       });
//     } catch (e, st) {
//       debugPrint("❌ PREVIEW FAILED");
//       debugPrint("❌ Error: $e");
//       debugPrint("❌ Stacktrace:");
//       debugPrint(st.toString());

//       if (!mounted) return;
//       setState(() {
//         _error = "Preview failed";
//         _loading = false;
//       });
//     }
//   }

//   // ─────────────────────────────────────────────
//   // PDF VIEW
//   // ─────────────────────────────────────────────

//   Widget _buildPdfPreview(File file) {
//     debugPrint("📄 UI: rendering PDF");

//     return PDFView(
//       filePath: file.path,
//       enableSwipe: true,
//       swipeHorizontal: false,
//       autoSpacing: true,
//       pageFling: true,
//       onRender: (pages) {
//         debugPrint("📄 PDF rendered, pages = $pages");
//       },
//       onError: (error) {
//         debugPrint("❌ PDFView error: $error");
//       },
//       onPageError: (page, error) {
//         debugPrint("❌ PDF page error (page=$page): $error");
//       },
//     );
//   }

//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       debugPrint("⏳ UI: loading state");
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_error != null) {
//       debugPrint("⚠️ UI: error state → $_error");
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Center(child: Text(_error!)),
//       );
//     }

//     debugPrint("🖼 UI: rendering preview");

//     final lower = widget.filename.toLowerCase();

//     return Scaffold(
//       appBar: AppBar(title: Text(widget.filename)),
//       body: Builder(
//         builder: (_) {
//           if (lower.endsWith(".png") ||
//               lower.endsWith(".jpg") ||
//               lower.endsWith(".jpeg")) {
//             return Image.file(
//               _previewFile!,
//               fit: BoxFit.contain,
//               errorBuilder: (_, __, ___) {
//                 debugPrint("❌ Image render failed");
//                 return const Center(
//                   child: Text("Image render failed"),
//                 );
//               },
//             );
//           }

//           if (lower.endsWith(".pdf")) {
//             return _buildPdfPreview(_previewFile!);
//           }

//           debugPrint("⚠️ Unsupported preview type");
//           return Center(
//             child: Text(
//               "Preview not supported for this file type",
//               textAlign: TextAlign.center,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
// ====================================================================================================
// import 'dart:io';
// import 'package:flutter/material.dart';

// import '../../crypto/file_stream_decryptor.dart';
// import '../../services/download_and_decrypt_service.dart';
// import '../../services/download_service.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   bool _loading = true;
//   String? _error;
//   File? _previewFile;

//   @override
//   void initState() {
//     super.initState();
//     _loadPreview();
//   }

//   @override
//   void dispose() {
//     if (_previewFile != null && _previewFile!.existsSync()) {
//       _previewFile!.deleteSync();
//     }
//     super.dispose();
//   }

//   Future<void> _download() async {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Downloading…")),
//     );

//     try {
//       await DownloadAndDecryptService.downloadFile(
        
//         fileId: widget.fileId,
//         filename: widget.filename,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Saved to Downloads")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Download failed: $e")),
//       );
//     }
//   }

//   Future<void> _loadPreview() async {
//     try {
//       final masterKey = SecureState.requireMasterKey();
//       final manifest =
//           await DownloadService.fetchManifest(widget.fileId);
//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);

//       final decryptor = FileStreamDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );

//       final file = await decryptor.decryptToTempFile(encrypted);

//       if (!mounted) return;
//       setState(() {
//         _previewFile = file;
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = "Preview failed";
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final lower = widget.filename.toLowerCase();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.filename),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: _download,
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//               ? Center(child: Text(_error!))
//               : lower.endsWith(".png") ||
//                       lower.endsWith(".jpg") ||
//                       lower.endsWith(".jpeg")
//                   ? Image.file(
//                       _previewFile!,
//                       fit: BoxFit.contain,
//                     )
//                   : Center(
//                       child: Text(
//                         "Decrypted to:\n${_previewFile!.path}",
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//     );
//   }
// }
// =========================================
// lib/screens/files/file_preview_screen.dart

// import 'dart:io';

// import 'package:flutter/material.dart';

// import '../../crypto/file_stream_decryptor.dart';
// import '../../services/download_service.dart';
// import '../../services/download_and_decrypt_service.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   bool _loading = true;
//   String? _error;
//   File? _previewFile;

//   @override
//   void initState() {
//     super.initState();
//     _loadPreview();
//   }

//   @override
//   void dispose() {
//     if (_previewFile != null && _previewFile!.existsSync()) {
//       _previewFile!.deleteSync();
//     }
//     super.dispose();
//   }

//   Future<void> _loadPreview() async {
//     try {
//       final masterKey = SecureState.requireMasterKey();

//       final manifest =
//           await DownloadService.fetchManifest(widget.fileId);

//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);

//       final decryptor = FileStreamDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );

//       final file =
//           await decryptor.decryptToTempFile(encrypted);

//       if (!mounted) return;
//       setState(() {
//         _previewFile = file;
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = "Preview failed";
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Center(child: Text(_error!)),
//       );
//     }

//     final lower = widget.filename.toLowerCase();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.filename),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: () async {
//               await DownloadAndDecryptService.downloadAndDecrypt(
//                 fileId: widget.fileId,
//                 filename: widget.filename,
//               );

//               if (!mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("File downloaded")),
//               );
//             },
//           ),
//         ],
//       ),
//       body: lower.endsWith(".png") ||
//               lower.endsWith(".jpg") ||
//               lower.endsWith(".jpeg")
//           ? Image.file(
//               _previewFile!,
//               fit: BoxFit.contain,
//             )
//           : Center(
//               child: Text(
//                 "Preview not available.\nYou can download the file.",
//                 textAlign: TextAlign.center,
//               ),
//             ),
//     );
//   }
// }
//==============================================================================
// lib/screens/files/file_preview_screen.dart
/// pdf going to external like drive etc 
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:open_filex/open_filex.dart';

// import '../../crypto/file_stream_decryptor.dart';
// import '../../services/download_service.dart';
// import '../../services/download_and_decrypt_service.dart';
// import '../../state/secure_state.dart';

// class FilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const FilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<FilePreviewScreen> createState() => _FilePreviewScreenState();
// }

// class _FilePreviewScreenState extends State<FilePreviewScreen> {
//   bool _loading = true;
//   String? _error;
//   File? _previewFile;

//   @override
//   void initState() {
//     super.initState();
//     _loadPreview();
//   }

//   @override
//   void dispose() {
//     if (_previewFile != null && _previewFile!.existsSync()) {
//       debugPrint("🧹 Deleting temp preview file");
//       _previewFile!.deleteSync();
//     }
//     super.dispose();
//   }

//   Future<void> _loadPreview() async {
//     debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//     debugPrint("👁 PREVIEW INIT");
//     debugPrint("📄 fileId   = ${widget.fileId}");
//     debugPrint("📄 filename = ${widget.filename}");

//     try {
//       final masterKey = SecureState.requireMasterKey();
//       debugPrint("🔑 Master key OK");

//       debugPrint("🟢 Fetching manifest");
//       final manifest =
//           await DownloadService.fetchManifest(widget.fileId);

//       debugPrint("🟢 Fetching encrypted data");
//       final encrypted =
//           await DownloadService.fetchEncryptedData(widget.fileId);

//       debugPrint("📦 Encrypted bytes = ${encrypted.length}");

//       final decryptor = FileStreamDecryptor(
//         masterKey: masterKey,
//         manifest: manifest,
//       );

//       debugPrint("🟢 Decrypting to temp file");
//       final file =
//           await decryptor.decryptToTempFile(encrypted);

//       debugPrint("🔓 Decryption complete");
//       debugPrint("📁 Temp path = ${file.path}");
//       debugPrint("📁 Temp size = ${file.lengthSync()} bytes");

//       if (!mounted) return;
//       setState(() {
//         _previewFile = file;
//         _loading = false;
//       });
//     } catch (e, st) {
//       debugPrint("❌ PREVIEW ERROR: $e");
//       debugPrint("$st");

//       if (!mounted) return;
//       setState(() {
//         _error = "Preview failed";
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: Center(child: Text(_error!)),
//       );
//     }

//     final lower = widget.filename.toLowerCase();
//     final isImage = lower.endsWith(".png") ||
//         lower.endsWith(".jpg") ||
//         lower.endsWith(".jpeg");
//     final isPdf = lower.endsWith(".pdf");

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.filename,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: () async {
//               debugPrint("⬇️ Download pressed from preview");

//               await DownloadAndDecryptService.downloadAndDecrypt(
//                 fileId: widget.fileId,
//                 filename: widget.filename,
//               );

//               if (!mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("File downloaded")),
//               );
//             },
//           ),
//         ],
//       ),
//       body: isImage
//           ? Center(
//               child: Image.file(
//                 _previewFile!,
//                 fit: BoxFit.contain,
//               ),
//             )
//           : isPdf
//               ? Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.picture_as_pdf_rounded,
//                         size: 80,
//                         color: Colors.redAccent,
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         "PDF Preview",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       ElevatedButton.icon(
//                         icon: const Icon(Icons.open_in_new),
//                         label: const Text("Open PDF"),
//                         onPressed: () {
//                           debugPrint("📄 Opening PDF via system viewer");
//                           OpenFilex.open(_previewFile!.path);
//                         },
//                       ),
//                     ],
//                   ),
//                 )
//               : Center(
//                   child: Text(
//                     "Preview not available.\nYou can download the file.",
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//     );
//   }
// }
///============================================================================
// lib/screens/files/file_preview_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:silvora_app/crypto/preview_decrypt_test.dart';

import '../../crypto/file_stream_decryptor.dart';
import '../../services/download_service.dart';
import '../../services/download_and_decrypt_service.dart';
import '../../state/secure_state.dart';

class FilePreviewScreen extends StatefulWidget {
  final String fileId;
  final String filename;

  const FilePreviewScreen({
    super.key,
    required this.fileId,
    required this.filename,
  });

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  bool _loading = true;
  String? _error;
  File? _previewFile;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    if (_previewFile != null && _previewFile!.existsSync()) {
      debugPrint("🧹 Deleting temp preview file");
      _previewFile!.deleteSync();
    }
    super.dispose();
  }

  Future<void> _loadPreview() async {
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("👁 PREVIEW INIT");
    debugPrint("📄 fileId   = ${widget.fileId}");
    debugPrint("📄 filename = ${widget.filename}");

    try {
      await runPreviewDecryptTest(fileId: widget.fileId);


      final masterKey = SecureState.requireMasterKey();



      final manifest =
          await DownloadService.fetchManifest(widget.fileId);

      final encrypted =
          await DownloadService.fetchEncryptedData(widget.fileId);
      

      final decryptor = FileStreamDecryptor(
        masterKey: masterKey,
        manifest: manifest,
      );

      

      final file =
          await decryptor.decryptToTempFile(encrypted);

      debugPrint("🔓 Preview decrypted");

      debugPrint("📁 Temp preview = ${file.path}");

      if (!mounted) return;
      setState(() {
        _previewFile = file;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint("❌ PREVIEW ERROR: $e");
      debugPrint("$st");
      if (!mounted) return;
      setState(() {
        _error = "Preview failed";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.filename)),
        body: Center(child: Text(_error!)),
      );
    }

    final lower = widget.filename.toLowerCase();
    final isImage = lower.endsWith(".png") ||
        lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg");
    final isPdf = lower.endsWith(".pdf");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              await DownloadAndDecryptService.downloadAndDecrypt(
                fileId: widget.fileId,
                filename: widget.filename,
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("File downloaded")),
              );
            },
          ),
        ],
      ),
      body: isImage
          ? Center(
              child: Image.file(
                _previewFile!,
                fit: BoxFit.contain,
              ),
            )
          : isPdf
              ? PDFView(
                  filePath: _previewFile!.path,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageSnap: true,
                  onError: (e) {
                    debugPrint("❌ PDF error: $e");
                  },
                )
              : const Center(
                  child: Text(
                    "Preview not available for this file type",
                    textAlign: TextAlign.center,
                  ),
                ),
    );
  }
}

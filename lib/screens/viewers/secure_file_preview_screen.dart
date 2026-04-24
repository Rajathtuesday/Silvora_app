// // lib/screens/viewers/secure_file_preview_screen.dart
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

// class SecureFilePreviewScreen extends StatefulWidget {
//   final Uint8List bytes;
//   final String filename;
//   final String mimeType;

//   const SecureFilePreviewScreen({
//     super.key,
//     required this.bytes,
//     required this.filename,
//     required this.mimeType,
//   });

//   @override
//   State<SecureFilePreviewScreen> createState() =>
//       _SecureFilePreviewScreenState();
// }

// class _SecureFilePreviewScreenState extends State<SecureFilePreviewScreen> {
//   bool _exporting = false;

//   @override
//   void dispose() {
//     // 🧨 Ensure decrypted bytes are wiped from memory on exit
//     widget.bytes.fillRange(0, widget.bytes.length, 0);
//     super.dispose();
//   }

//   Future<void> _showExportWarning() async {
//     showModalBottomSheet(
//       context: context,
//       isDismissible: true,
//       showDragHandle: true,
//       backgroundColor: Colors.red.shade50,
//       builder: (_) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.warning_amber_rounded,
//                 size: 48, color: Colors.red),
//             const SizedBox(height: 12),
//             const Padding(
//               padding: EdgeInsets.all(12),
//               child: Text(
//                 "Exporting decrypted files is unsafe.\n"
//                 "Silvora cannot protect any copy saved outside the vault.\n\n"
//                 "You take full responsibility for its security.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.red,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _exportToDevice();
//               },
//               icon: const Icon(Icons.download),
//               label: const Text("Export anyway"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//               ),
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _exportToDevice() async {
//     if (_exporting) return;
//     setState(() => _exporting = true);

//     final dir = await getApplicationDocumentsDirectory();
//     final path = "${dir.path}/${widget.filename}";
//     final file = File(path);
//     await file.writeAsBytes(widget.bytes, flush: true);

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content:
//               Text("Exported insecure copy:\n$path\n(you must protect it)"),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }

//     setState(() => _exporting = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isImage = widget.mimeType.startsWith("image/");
//     final isPdf = widget.mimeType == "application/pdf";

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.filename),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download_for_offline_rounded),
//             onPressed: _showExportWarning,
//             tooltip: "Export to device (unsafe)",
//             color: Colors.red,
//           ),
//         ],
//       ),
//       body: Center(
//         child: isImage
//             ? Image.memory(widget.bytes)
//             : isPdf
//                 ? Text("PDF preview coming soon")
//                 : const Text("Unable to preview this file type"),
//       ),
//     );
//   }
// }


// =============================================================
//disable for a while 
// lib/screens/viewers/secure_file_preview_screen.dart

// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';

// import '../../crypto/file_decryptor.dart';
// import '../../services/api_services.dart';
// import '../../state/secure_state.dart';

// class SecureFilePreviewScreen extends StatefulWidget {
//   final String fileId;
//   final String filename;

//   const SecureFilePreviewScreen({
//     super.key,
//     required this.fileId,
//     required this.filename,
//   });

//   @override
//   State<SecureFilePreviewScreen> createState() =>
//       _SecureFilePreviewScreenState();
// }

// class _SecureFilePreviewScreenState
//     extends State<SecureFilePreviewScreen> {
//   Uint8List? _plainBytes;
//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _loadAndDecrypt();
//   }

//   Future<void> _loadAndDecrypt() async {
//     try {
//       // 1️⃣ Fetch manifest
//       final manifest =
//           await ApiService.fetchManifest(widget.fileId);

//       // 2️⃣ Fetch encrypted blob
//       final encrypted =
//           await ApiService.fetchEncryptedData(widget.fileId);

//       // 3️⃣ Ensure master key exists
//       final masterKey = SecureState.masterKey;
//       if (masterKey == null) {
//         throw Exception("Master key not unlocked");
//       }

//       // 4️⃣ Decrypt
//       final plain = await FileDecryptor.decryptFromManifest(
//         manifest: manifest,
//         encryptedBlob: encrypted,
//         masterKey: masterKey,
//       );

//       if (!mounted) return;

//       setState(() {
//         _plainBytes = plain;
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
//   void dispose() {
//     // 🔐 wipe decrypted memory
//     if (_plainBytes != null) {
//       _plainBytes!.fillRange(0, _plainBytes!.length, 0);
//     }
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
//         body: Center(child: Text(_error!)),
//       );
//     }

//     final lower = widget.filename.toLowerCase();

//     if (lower.endsWith(".pdf")) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: PDFView(pdfData: _plainBytes!),
//       );
//     }

//     if (lower.endsWith(".png") ||
//         lower.endsWith(".jpg") ||
//         lower.endsWith(".jpeg")) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.filename)),
//         body: InteractiveViewer(
//           child: Image.memory(_plainBytes!),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text(widget.filename)),
//       body: const Center(
//         child: Text("Preview not supported for this file type"),
//       ),
//     );
//   }
// }

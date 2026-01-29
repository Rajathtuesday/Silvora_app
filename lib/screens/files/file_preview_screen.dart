
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

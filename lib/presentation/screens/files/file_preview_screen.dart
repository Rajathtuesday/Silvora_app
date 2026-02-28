// ============================================================================
// lib/screens/files/file_preview_screen.dart
//
// Production preview screen
// - Streams decrypt to temp file
// - No memory buffering
// - Auto cleanup
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../infrastructure/services/download_and_decrypt_service.dart';
import '../../../state/secure_state.dart';

import '../viewers/pdf_view_screen.dart';
import '../viewers/image_view_screen.dart';

class FilePreviewScreen extends StatefulWidget {
  final String fileId;
  final String filename;

  const FilePreviewScreen({
    super.key,
    required this.fileId,
    required this.filename,
  });

  @override
  State<FilePreviewScreen> createState() =>
      _FilePreviewScreenState();
}

class _FilePreviewScreenState
    extends State<FilePreviewScreen> {
  File? _tempFile;
  bool _loading = true;
  String? _error;

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _startPreview();
  }

  // ─────────────────────────────────────────
  // Download + Decrypt (to temp file)
  // ─────────────────────────────────────────
  Future<void> _startPreview() async {
    try {
      SecureState.requireMasterKey();

      final file =
          await DownloadAndDecryptService
              .downloadAndDecryptToTempFile(
                  fileId: widget.fileId);

      if (!mounted) return;

      if (_isVideo(widget.filename)) {
        _videoController =
            VideoPlayerController.file(file);
        await _videoController!.initialize();
      }

      setState(() {
        _tempFile = file;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────

  bool _isVideo(String name) {
    final n = name.toLowerCase();
    return n.endsWith(".mp4") ||
        n.endsWith(".mov") ||
        n.endsWith(".mkv") ||
        n.endsWith(".webm");
  }

  bool _isImage(String name) {
    final n = name.toLowerCase();
    return n.endsWith(".png") ||
        n.endsWith(".jpg") ||
        n.endsWith(".jpeg") ||
        n.endsWith(".webp");
  }

  bool _isPdf(String name) {
    return name.toLowerCase().endsWith(".pdf");
  }

  // ─────────────────────────────────────────
  // Cleanup temp file
  // ─────────────────────────────────────────
  @override
  void dispose() {
    _videoController?.dispose();

    if (_tempFile != null &&
        _tempFile!.existsSync()) {
      _tempFile!.delete().catchError((_) {});
    }

    super.dispose();
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D12),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D12),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Preview failed\n\n$_error",
              style: const TextStyle(
                  color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final file = _tempFile!;
    final name = widget.filename;

    // ───────────── VIDEO ─────────────

    if (_isVideo(name)) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(name),
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio:
                _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              if (_videoController!
                  .value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Icon(
            _videoController!.value.isPlaying
                ? Icons.pause
                : Icons.play_arrow,
          ),
        ),
      );
    }

    // ───────────── IMAGE ─────────────

    if (_isImage(name)) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D12),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(name),
        ),
        body: Center(
          child: Image.file(file),
        ),
      );
    }

    // ───────────── PDF ─────────────

    if (_isPdf(name)) {
      return PdfViewScreen(
        file: file,
        filename: name,
      );
    }

    // ───────────── FALLBACK ─────────────

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(name),
      ),
      body: const Center(
        child: Text(
          "Preview not supported",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}


//-----------------------------------------------ui updation -----------------------------------------
// lib/screens/upload/upload_screen.dart
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/upload_service.dart';
import '../../services/upload_worker.dart';
import '../../state/secure_state.dart';
import '../../state/upload_retry_state.dart';
import '../files/file_list_screen.dart';
import '../login/login_screen.dart';
import 'focus_ring_game.dart';
import 'calm_orb_game.dart';
import 'reflex_game.dart';

/// ─────────────────────────────────────────────
/// UPLOAD STATE
/// ─────────────────────────────────────────────
enum UploadState {
  idle,
  fileSelected,
  starting,
  uploading,
  finishing,
  error,
}

/// ─────────────────────────────────────────────
/// GAME ROTATOR (FRESH UPLOAD ONLY)
/// ─────────────────────────────────────────────
class UploadGameRotator {
  static int _index = 0;

  static Widget next() {
    final games = [
      const CalmOrbGame(),
      const FocusRingGame(),
      const ReflexGame(),
    ];
    final game = games[_index % games.length];
    _index++;
    return game;
  }
}
// ─────────────────────────────────────────────
/// Color class
/// ─────────────────────────────────────────────
class SilvoraColors {
  static const Color accent = Color(0xFF9255E8);
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF121212);
  static const Color textPrimary = Colors.white;
  static const Color textMuted = Colors.white60;
}




/// ─────────────────────────────────────────────
/// UPLOAD SCREEN
/// ─────────────────────────────────────────────
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

  // ETA
  double _avgSpeedBytesPerSec = 0;
  DateTime? _lastTick;
  String _etaText = "Calculating…";

  // Game (ONLY for fresh upload)
  Widget? _game;

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

  // ───────────────── ETA LOGIC ─────────────────

  void _updateEta(int bytesJustUploaded) {
    final now = DateTime.now();

    if (_lastTick != null) {
      final seconds =
          now.difference(_lastTick!).inMilliseconds / 1000;
      if (seconds > 0) {
        final instantSpeed = bytesJustUploaded / seconds;
        _avgSpeedBytesPerSec = _avgSpeedBytesPerSec == 0
            ? instantSpeed
            : (_avgSpeedBytesPerSec * 0.7) + (instantSpeed * 0.3);

        final remainingBytes = _totalBytes - _uploadedBytes;
        final remainingSeconds =
            remainingBytes / _avgSpeedBytesPerSec;

        _etaText = _formatDuration(remainingSeconds);
      }
    }

    _lastTick = now;
  }

  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) {
      return "Calculating…";
    }
    if (seconds < 60) {
      return "${seconds.round()} sec remaining";
    }
    final m = (seconds / 60).floor();
    final s = (seconds % 60).round();
    return "$m min $s sec remaining";
  }

  // ───────────────── WORKER MESSAGES ─────────────────

  Future<void> _handleWorkerMessage(dynamic msg) async {
    if (!mounted) return;

    if (msg is int && _state == UploadState.uploading) {
      _uploadedBytes += msg;
      _updateEta(msg);

      setState(() {
        _progress = _uploadedBytes / _totalBytes;
      });
      return;
    }

    if (msg == "DONE") {
      HapticFeedback.heavyImpact();
      setState(() => _state = UploadState.finishing);

      await UploadService.finishUpload(_activeFileId!);
      await UploadRetryStore.clear();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FileListScreen()),
      );
    }
  }

  // ───────────────── FILE PICK ─────────────────

  Future<void> _pickFile() async {
    if (_state != UploadState.idle) return;

    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path == null) return;

    final file = File(result!.files.single.path!);
    final size = await file.length();

    setState(() {
      _file = file;
      _totalBytes = size;
      _uploadedBytes = 0;
      _progress = 0;
      _etaText = "Preparing…";
      _avgSpeedBytesPerSec = 0;
      _lastTick = null;

      // 🔑 game ONLY for fresh upload
      _game = UploadGameRotator.next();
      _state = UploadState.fileSelected;
    });

    HapticFeedback.selectionClick();
  }

  // ───────────────── START UPLOAD ─────────────────

  Future<void> _upload() async {
    if (_file == null || _state != UploadState.fileSelected) return;

    if (SecureState.accessToken == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    setState(() => _state = UploadState.starting);

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

    // Resume → NO GAME
    if (uploadedSet.isNotEmpty) {
      _game = null;
    }

    await UploadRetryStore.save({
      "fileId": fileId,
      "filePath": file.path,
      "fileSize": size,
      "chunkSize": chunkSize,
      "uploadedChunks": uploadedMap,
    });

    setState(() => _state = UploadState.uploading);

    await Isolate.spawn(
      uploadWorkerEntry,
      [
        UploadTaskParams(
          serverBaseUrl: SecureState.serverBaseUrl,
          filePath: file.path,
          fileSize: size,
          fileId: fileId,
          masterKey: Uint8List.fromList(masterKey),
          chunkSize: chunkSize,
          uploadedChunks: uploadedMap,
          accessToken: SecureState.accessToken!,
        ),
        _progressPort.sendPort,
      ],
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    final uploading =
        _state == UploadState.uploading ||
        _state == UploadState.finishing;

    return Scaffold(
      backgroundColor: SilvoraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Secure Upload",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _filePickerCard(),
            const SizedBox(height: 16),
            _encryptionCard(),
            const SizedBox(height: 24),
            if (uploading) ...[
              LinearProgressIndicator(
                value: _progress,
                color: SilvoraColors.accent,
                backgroundColor: Colors.white12,
              ),
              const SizedBox(height: 8),
              Text(
                "${(_progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: SilvoraColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _etaText,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              if (_game != null) Expanded(child: _game!),
            ] else ...[
              const Spacer(),
              _uploadButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────── UI PARTS ─────────────────

  Widget _filePickerCard() => Card(
        color: SilvoraColors.surface,
        child: ListTile(
          leading: const Icon(Icons.lock_outline,
              color: SilvoraColors.accent),
          title: Text(
            _file == null ? "Choose a file" : _file!.path.split('/').last,
            style: const TextStyle(color: Colors.white),
          ),
          onTap: _pickFile,
        ),
      );

  Widget _encryptionCard() => SwitchListTile(
        title: const Text(
          "Zero-knowledge encryption",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: const Text(
          "Only you can decrypt this file",
          style: TextStyle(color: Colors.white54),
        ),
        value: _zeroKnowledge,
        activeThumbColor: SilvoraColors.accent,
        onChanged: _state == UploadState.idle
            ? (v) => setState(() => _zeroKnowledge = v)
            : null,
      );

  Widget _uploadButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SilvoraColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _upload,
          child: const Text("Upload securely"),
        ),
      );
}

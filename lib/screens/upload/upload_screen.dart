import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/upload_service.dart';
import '../files/file_list_screen.dart';
import '../../state/secure_state.dart';
import '../../crypto/hkdf.dart';
import '../../theme/silvora_theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  double _progress = 0.0;

  static const int chunkSize = 2 * 1024 * 1024; // 2MB chunks
  final Xchacha20 _algorithm = Xchacha20.poly1305Aead();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForPendingUpload());
  }

  Future<void> _checkForPendingUpload() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId   = prefs.getString("active_upload_id");
    final activePath = prefs.getString("active_upload_path");

    if (activeId != null && activePath != null && mounted) {
      final file = File(activePath);
      if (!file.existsSync()) {
        await prefs.remove("active_upload_id");
        await prefs.remove("active_upload_path");
        _showSnack("Pending file no longer exists locally. Discarding.", isError: true);
        return;
      }

      final resume = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: SilvoraColors.card2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Pending Upload", style: TextStyle(color: SilvoraColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Text(
            "An interrupted upload was detected:\n${file.path.split(Platform.pathSeparator).last}\n\nWould you like to resume securely?",
            style: const TextStyle(color: SilvoraColors.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                prefs.remove("active_upload_id");
                prefs.remove("active_upload_path");
                Navigator.pop(ctx, false);
              },
              child: const Text("Discard", style: TextStyle(color: SilvoraColors.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Resume", style: TextStyle(color: SilvoraColors.primaryLight, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (resume == true && mounted) {
        setState(() => _selectedFile = file);
        await _startEncryptionAndUpload(activeId);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? SilvoraColors.error : SilvoraColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path == null) return;

    setState(() {
      _selectedFile = File(result!.files.single.path!);
      _progress = 0.0;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d > 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return "${d.toStringAsFixed(2)} ${suffixes[i]}";
  }

  Future<void> _startEncryptionAndUpload([String? existingUploadId]) async {
    if (_selectedFile == null || _isUploading) return;

    final file    = _selectedFile!;
    final fileLen = await file.length();
    final filename = file.path.split(Platform.pathSeparator).last;

    setState(() {
      _isUploading = true;
      _progress = 0.01;
    });

    String? uploadId = existingUploadId;

    if (uploadId == null) {
      uploadId = await UploadService.startUpload(
        filename:     filename,
        fileSize:     fileLen,
        chunkSize:    chunkSize,
        securityMode: "zero_knowledge",
      );

      if (uploadId == null) {
        _showSnack("Upload creation failed. Quota limit reached?", isError: true);
        setState(() => _isUploading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("active_upload_id", uploadId);
      await prefs.setString("active_upload_path", file.path);
    }

    final uploadedChunks = await UploadService.resumeUpload(uploadId) ?? {};
    final totalChunks    = (fileLen / chunkSize).ceil();
    final raf = await file.open();

    // Derive secure HKDF per-file key
    final fileKeyBytes = await hkdfSha256(
      ikm:  SecureState.masterKey,
      info: utf8.encode("silvora_file_$uploadId"),
    );
    final secretKey = SecretKey(fileKeyBytes);

    try {
      for (int i = 0; i < totalChunks; i++) {
        if (uploadedChunks.contains(i)) {
          setState(() => _progress = (i + 1) / totalChunks);
          continue;
        }

        await raf.setPosition(i * chunkSize);
        final plain = await raf.read(
          ((i + 1) * chunkSize > fileLen) ? fileLen - i * chunkSize : chunkSize,
        );

        final nonce = await _algorithm.newNonce();
        final box = await _algorithm.encrypt(
          plain,
          secretKey: secretKey,
          nonce:     nonce,
        );

        final ok = await UploadService.uploadChunk(
          uploadId:   uploadId,
          chunkIndex: i,
          cipherChunk: Uint8List.fromList(box.cipherText),
          nonce:       Uint8List.fromList(nonce),
          mac:         Uint8List.fromList(box.mac.bytes),
        );

        if (!ok) throw Exception("Network error on chunk $i");

        setState(() => _progress = (i + 1) / totalChunks);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnack("Connection dropped. Upload paused — will auto-resume next time.", isError: true);
      await raf.close();
      return;
    }

    await raf.close();
    await UploadService.finishUpload(uploadId: uploadId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("active_upload_id");
    await prefs.remove("active_upload_path");

    if (!mounted) return;
    _showSnack("Vault encrypted and synchronized!");
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FileListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final filePreview = _selectedFile;
    final fileSize    = filePreview != null ? filePreview.lengthSync() : 0;
    final fileName    = filePreview != null
        ? filePreview.path.split(Platform.pathSeparator).last
        : 'No file selected';

    return Scaffold(
      backgroundColor: SilvoraColors.bg,
      appBar: AppBar(
        title: const Text("Secure Upload"),
        leading: const BackButton(color: SilvoraColors.textSecondary),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Pick Area ──────────────────────────────
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: SilvoraColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: filePreview == null
                            ? SilvoraColors.border
                            : SilvoraColors.primary.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          filePreview == null ? Icons.folder_open_outlined : Icons.insert_drive_file_rounded,
                          size: 64,
                          color: filePreview == null ? SilvoraColors.textMuted : SilvoraColors.primaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fileName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: filePreview == null ? FontWeight.normal : FontWeight.w600,
                            color: filePreview == null ? SilvoraColors.textMuted : SilvoraColors.textPrimary,
                          ),
                        ),
                        if (filePreview != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _formatBytes(fileSize),
                            style: const TextStyle(color: SilvoraColors.textSecondary, fontSize: 13),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          const Text(
                            "Tap to browse files",
                            style: TextStyle(color: SilvoraColors.primaryLight, fontWeight: FontWeight.w500),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Security Badge ─────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: SilvoraColors.primaryGlow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SilvoraColors.borderFocus),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: SilvoraColors.primaryLight, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Zero-Knowledge · XChaCha20 · HKDF-SHA256",
                          style: TextStyle(
                            color: SilvoraColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Progress / Button ─────────────────────
                if (_isUploading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: SilvoraColors.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(SilvoraColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${(_progress * 100).toStringAsFixed(1)}%  —  Encrypting & Transmitting",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SilvoraColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: filePreview == null ? null : _startEncryptionAndUpload,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text("Encrypt & Upload to Vault"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

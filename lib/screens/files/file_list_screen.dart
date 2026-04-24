import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/download_service.dart';
import '../upload/upload_screen.dart';
import '../trash/trash_screen.dart';
import '../../theme/silvora_theme.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  late Future<List<dynamic>> _filesFuture;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _reloadFiles();
  }

  void _reloadFiles() {
    _filesFuture = ApiService.listFiles();
  }

  Future<void> _goToUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
    setState(_reloadFiles);
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

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp': return Icons.image_outlined;
      case 'mp4':
      case 'avi':
      case 'mov': return Icons.movie_outlined;
      case 'zip':
      case 'rar': return Icons.folder_zip_outlined;
      case 'txt':
      case 'md': return Icons.article_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  // ─── Action Sheet ─────────────────────────────────────────────
  void _handleAction(BuildContext context, Map<String, dynamic> f) {
    final filename = f["filename"] ?? "Unknown.enc";
    final mimeType = DownloadService.guessMimeType(filename);

    showModalBottomSheet(
      context: context,
      backgroundColor: SilvoraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: SilvoraColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Filename
              Text(
                filename,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SilvoraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatBytes(f["size"] ?? 0),
                style: const TextStyle(color: SilvoraColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Preview — only for previewable types
              if (DownloadService.isPreviewable(mimeType))
                ListTile(
                  leading: const Icon(Icons.remove_red_eye_outlined, color: SilvoraColors.primaryLight),
                  title: const Text("Preview", style: TextStyle(color: SilvoraColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _downloadAndExecute(context, f, previewOnly: true);
                  },
                ),

              ListTile(
                leading: const Icon(Icons.download_outlined, color: SilvoraColors.primaryLight),
                title: const Text("Download to Device", style: TextStyle(color: SilvoraColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadAndExecute(context, f, previewOnly: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: SilvoraColors.error),
                title: const Text("Move to Trash", style: TextStyle(color: SilvoraColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _moveToTrash(f["file_id"] as String);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ─── Trash ────────────────────────────────────────────────────
  Future<void> _moveToTrash(String fileId) async {
    try {
      await ApiService.deleteFile(fileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Moved to Trash (auto-purges in 30 days)")),
      );
      setState(_reloadFiles);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Trash failed: $e"),
          backgroundColor: SilvoraColors.error,
        ),
      );
    }
  }

  // ─── Download / Preview ───────────────────────────────────────
  Future<void> _downloadAndExecute(
    BuildContext context,
    Map<String, dynamic> f, {
    required bool previewOnly,
  }) async {
    setState(() => _isDownloading = true);

    try {
      final String fileId   = f["file_id"] as String;
      final String filename = (f["filename"] as String?) ?? "encrypted.enc";

      final result = await DownloadService.downloadAndDecrypt(
        fileId:   fileId,
        filename: filename,
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);

      if (result == null) throw Exception("Decryption returned an empty result.");

      if (previewOnly) {
        if (result.mimeType.startsWith('image/')) {
          // ── Image preview ──
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: SilvoraColors.card,
              contentPadding: const EdgeInsets.all(8),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(result.bytes, fit: BoxFit.contain),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("Close", style: TextStyle(color: SilvoraColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(c);
                    final path = await DownloadService.saveToDevice(result);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Saved to: $path")),
                      );
                    }
                  },
                  child: const Text("Save to Device", style: TextStyle(color: SilvoraColors.gold)),
                ),
              ],
            ),
          );
        } else if (result.mimeType == "text/plain") {
          // ── Text preview ──
          final text = String.fromCharCodes(result.bytes);
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: SilvoraColors.card,
              title: Text(
                filename,
                style: const TextStyle(color: SilvoraColors.textPrimary, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              content: SingleChildScrollView(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: SilvoraColors.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("Close", style: TextStyle(color: SilvoraColors.primaryLight)),
                ),
              ],
            ),
          );
        } else {
          // Not previewable — auto-save instead
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Preview not available for this file type. Saving to device..."),
            ),
          );
          final path = await DownloadService.saveToDevice(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Saved to: $path")),
            );
          }
        }
      } else {
        // ── Save to device ──
        final path = await DownloadService.saveToDevice(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Saved: $path"),
              action: SnackBarAction(label: "OK", onPressed: () {}),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: SilvoraColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Vault"),
        leading: const Icon(Icons.shield_outlined, color: SilvoraColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: SilvoraColors.textSecondary),
            tooltip: "Trash",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
              setState(_reloadFiles); // Refresh vault after returning from trash
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh",
            onPressed: () => setState(_reloadFiles),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDownloading ? null : _goToUpload,
        backgroundColor: SilvoraColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<dynamic>>(
            future: _filesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      const Text("Sync failed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SilvoraColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text("Check connection.", style: TextStyle(color: SilvoraColors.textMuted)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => setState(_reloadFiles),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }

              final files = snapshot.data!;
              if (files.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 72, color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 20),
                      const Text("Your vault is empty", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: SilvoraColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text(
                        "Files you upload appear here,\nsecurely encrypted end-to-end.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: SilvoraColors.textMuted, height: 1.5),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final f = files[index] as Map<String, dynamic>;
                  final filename = (f["filename"] as String?) ?? "Encrypted File";
                  return Card(
                    color: SilvoraColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: SilvoraColors.border),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SilvoraColors.primaryGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getFileIcon(filename),
                          color: SilvoraColors.primaryLight,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: SilvoraColors.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _formatBytes(f["size"] as int? ?? 0),
                          style: const TextStyle(color: SilvoraColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: SilvoraColors.textMuted),
                        onPressed: () => _handleAction(context, f),
                      ),
                      onTap: () => _handleAction(context, f),
                    ),
                  );
                },
              );
            },
          ),

          // ── Decrypt overlay ──────────────────────────────────
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: SilvoraColors.card2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SilvoraColors.borderFocus),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: SilvoraColors.primary),
                      SizedBox(height: 24),
                      Text(
                        "Decrypting via XChaCha20…",
                        style: TextStyle(
                          color: SilvoraColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Verifying integrity…",
                        style: TextStyle(color: SilvoraColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

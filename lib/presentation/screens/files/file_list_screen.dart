//------------------------------------------------------------------------------------------------
// File: lib/screens/files/file_list_screen.dart
//------------------------------------------------------------------------------------------------
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:silvora_app/presentation/screens/files/trash_screen.dart';
import 'package:silvora_app/infrastructure/services/quota_service.dart';
import 'package:silvora_app/presentation/widgets/brand_logo.dart';
import '../../../infrastructure/services/api_services.dart';
import '../../../state/secure_state.dart';
import '../../../state/filename_cache.dart';
import '../../widgets/storage_usage_card.dart';
import '../../../crypto/filename_resolver.dart';
import '../../../crypto/filename_crypto.dart';
import '../../../crypto/file_key.dart';

import '../login/login_screen.dart';
import '../upload/upload_screen.dart';
import 'file_preview_screen.dart';
import '../../../domain/models/quota.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen>
    with WidgetsBindingObserver {
  late Future<void> _loadFuture;

  final List<Map<String, dynamic>> _files = [];

  int _usedBytes = 0;
  int _limitBytes = 0;
  bool _quotaAvailable = false;

  Timer? _idleTimer;
  static const Duration _idleTimeout = Duration(minutes: 3);

  // ───────────────── INIT / DISPOSE ─────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetIdleTimer();
    _loadFuture = _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  // ───────────────── IDLE SECURITY ─────────────────

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _autoLogout);
  }

  Future<void> _autoLogout() async {
    await SecureState.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _autoLogout();
    }
  }

  // ───────────────── DATA LOAD ─────────────────

  Future<void> _loadAll() async {
    try {
      final files = await ApiService.listFiles();
      final  Quota? quota = await QuotaService.fetchQuota();


      await Future.wait(files.map((f) async {
        final String? cipher = f['filename_ciphertext'];
        final String? nonce = f['filename_nonce'];
        final String? mac = f['filename_mac'];

        if (cipher == null || nonce == null || mac == null) {
          f['filename_dec'] = "Unknown file";
          return;
        }

        try {
          f['filename_dec'] = await FilenameResolver.resolve(
            fileId: f['file_id'],
            ciphertextHex: cipher,
            nonceHex: nonce,
            macHex: mac,
          );
        } catch (_) {
          f['filename_dec'] = "Unreadable name";
          f['filename_error'] = true;
        }
      }));

      if (!mounted) return;

          setState(() {
            _files
              ..clear()
              ..addAll(files);

            if (quota != null) {
              _usedBytes = quota.usedBytes;
              _limitBytes = quota.limitBytes;
              _quotaAvailable = true;
            } else {
              _usedBytes = 0;
              _limitBytes = 0;
              _quotaAvailable = false;
            }
          });


    } catch (_) {
      await _autoLogout();
    }
  }

  Future<void> _refresh() async => _loadAll();

  // ───────────────── ACTIONS ─────────────────

  Future<void> _openUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
    if (mounted) await _refresh();
  }

  // ───────────────── RENAME ─────────────────

  Future<void> _showRenameDialog(Map<String, dynamic> file) async {
    final controller =
        TextEditingController(text: file['filename_dec']);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename file"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: "New filename"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text("Rename"),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final String fileId = file['file_id'];
    final masterKey = SecureState.requireMasterKey();
    final fileKey =
        await deriveFileKey(masterKey: masterKey, fileId: fileId);

    final encrypted = await FilenameCrypto.encrypt(
      filename: result,
      fileKey: fileKey,
    );

    // final api = UploadApi(accessToken: SecureState.accessToken!);
    // await api.renameFile(
    //   fileId: fileId,
    //   encHex: encrypted.encHex,
    //   nonceHex: encrypted.nonceHex,
    //   hashHex: encrypted.hashHex,
    // );

    FilenameCache.put(fileId, result);

    setState(() {
      file['filename_dec'] = result;
      file.remove('filename_error');
    });
  }

  // ───────────────── HELPERS ─────────────────

  IconData _iconFor(String name) {
    final f = name.toLowerCase();
    if (f.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (f.endsWith('.jpg') || f.endsWith('.png')) {
      return Icons.image_rounded;
    }
    if (f.endsWith('.zip')) return Icons.folder_zip_rounded;
    if (f.endsWith('.mp4')) return Icons.movie_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return mb < 1
        ? "${(bytes / 1024).toStringAsFixed(1)} KB"
        : "${mb.toStringAsFixed(2)} MB";
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const SilvoraLogo(fontSize: 20),
          actions: [
            IconButton(
              tooltip: "Trash",
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
              },
            ),
            IconButton(
              tooltip: "Logout",
              icon: const Icon(Icons.logout),
              onPressed: _autoLogout,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openUpload,
          icon: const Icon(Icons.upload_file),
          label: const Text("Upload"),
        ),
        body: FutureBuilder<void>(
          future: _loadFuture,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loadingSkeleton();
            }

            if (_files.isEmpty) {
              return _emptyState();
            }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _quotaAvailable
                  ? _files.length + 1
                  : _files.length,
              itemBuilder: (_, i) {
                // If quota card exists, shift index
                if (_quotaAvailable && i == 0) {
                  return StorageUsageCard(
                    usedBytes: _usedBytes,
                    limitBytes: _limitBytes,
                  );
                }

                final fileIndex = _quotaAvailable ? i - 1 : i;
                final f = _files[fileIndex];

                  final bool error = f['filename_error'] == true;
                  final String fileId = f['file_id'];

                  return Dismissible(
                    key: ValueKey(fileId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      await ApiService.softDeleteFile(fileId);

                      setState(() {
                        _files.removeAt(i - 1);
                      });

                      ScaffoldMessenger.of(context)
                          .clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: const Text("Moved to Trash"),
                          action: SnackBarAction(
                            label: "Undo",
                            onPressed: () async {
                              await ApiService.restoreFile(fileId);
                              await _refresh();
                            },
                          ),
                        ),
                      );

                      return true;
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        onLongPress: () => _showRenameDialog(f),
                        leading: CircleAvatar(
                          backgroundColor: error
                              ? Colors.redAccent.withOpacity(0.15)
                              : Colors.deepPurple.withOpacity(0.15),
                          child: Icon(
                            _iconFor(f['filename_dec']),
                            color: error
                                ? Colors.redAccent
                                : Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          f['filename_dec'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatSize(f['size']),
                        ),
                        onTap: error
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FilePreviewScreen(
                                      fileId: fileId,
                                      filename: f['filename_dec'],
                                    ),
                                  ),
                                );
                              },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────── STATES ─────────────────

  Widget _loadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => const Card(
        child: ListTile(
          leading: CircleAvatar(),
          title: SizedBox(height: 14),
          subtitle: SizedBox(height: 10),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No files yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            "Upload files to store them securely",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

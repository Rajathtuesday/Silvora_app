
//------------------------------------------------------------------------------------------------
// File: lib/screens/files/file_list_screen.dart
//------------------------------------------------------------------------------------------------
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:silvora_app/screens/files/trash_screen.dart';
import 'package:silvora_app/services/quota_service.dart';
import 'package:silvora_app/widgets/brand_logo.dart';

import '../../services/api_services.dart';
import '../../state/secure_state.dart';
import '../../widgets/storage_usage_card.dart';
import '../login/login_screen.dart';
import '../upload/upload_screen.dart';
import 'file_preview_screen.dart';

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

  bool _showSwipeHint = true;

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
    // ⚠️ file picker triggers paused → DO NOT logout
    if (state == AppLifecycleState.detached) {
      _autoLogout();
    }
  }

  // ───────────────── DATA ─────────────────

  Future<void> _loadAll() async {
    final files = await ApiService.listFiles();
    _files
      ..clear()
      ..addAll(files);

    try {
      final quota = await QuotaService.fetchQuota();
      _usedBytes = quota.used;
      _limitBytes = quota.limit;
      _quotaAvailable = true;
    } catch (_) {
      _quotaAvailable = false;
    }
  }

  Future<void> _refresh() async {
    final future = _loadAll();
    setState(() => _loadFuture = future);
    await future;
  }

  // ───────────────── ACTIONS ─────────────────

  Future<void> _openUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
    if (mounted) await _refresh();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Log out"),
            content: const Text("Your vault will be locked on this device."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Log out"),
              ),
            ],
          ),
        ) ??
        false;

    if (ok) await _autoLogout();
  }

  // ───────────────── FILE ICON LOGIC ─────────────────

  IconData _iconFor(String name) {
    final f = name.toLowerCase();
    if (f.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.png')) {
      return Icons.image_rounded;
    }
    if (f.endsWith('.doc') || f.endsWith('.docx')) {
      return Icons.article_rounded;
    }
    if (f.endsWith('.txt') || f.endsWith('.md')) {
      return Icons.description_rounded;
    }
    if (f.endsWith('.xls') || f.endsWith('.xlsx') || f.endsWith('.csv')) {
      return Icons.table_chart_rounded;
    }
    if (f.endsWith('.ppt') || f.endsWith('.pptx')) {
      return Icons.slideshow_rounded;
    }
    if (f.endsWith('.zip') || f.endsWith('.rar') || f.endsWith('.7z')) {
      return Icons.folder_zip_rounded;
    }
    if (f.endsWith('.mp3') || f.endsWith('.wav')) {
      return Icons.music_note_rounded;
    }
    if (f.endsWith('.mp4') || f.endsWith('.mkv') || f.endsWith('.mov')) {
      return Icons.movie_rounded;
    }
    if (f.endsWith('.js') ||
        f.endsWith('.py') ||
        f.endsWith('.dart') ||
        f.endsWith('.java')) {
      return Icons.code_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _iconColor(String name) {
    final f = name.toLowerCase();
    if (f.endsWith('.pdf')) return Colors.redAccent;
    if (f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.png')) {
      return Colors.blueAccent;
    }
    if (f.endsWith('.doc') || f.endsWith('.docx')) {
      return Colors.indigo;
    }
    if (f.endsWith('.txt') || f.endsWith('.md')) {
      return Colors.green;
    }
    if (f.endsWith('.xls') || f.endsWith('.xlsx') || f.endsWith('.csv')) {
      return Colors.teal;
    }
    if (f.endsWith('.ppt') || f.endsWith('.pptx')) {
      return Colors.orange;
    }
    if (f.endsWith('.zip') || f.endsWith('.rar') || f.endsWith('.7z')) {
      return Colors.brown;
    }
    if (f.endsWith('.mp3') || f.endsWith('.wav')) {
      return Colors.deepPurple;
    }
    if (f.endsWith('.mp4') || f.endsWith('.mkv') || f.endsWith('.mov')) {
      return Colors.cyan;
    }
    if (f.endsWith('.js') ||
        f.endsWith('.py') ||
        f.endsWith('.dart') ||
        f.endsWith('.java')) {
      return Colors.amber;
    }
    return Colors.grey;
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
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetIdleTimer(),
      child: Scaffold(
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
              tooltip: "Log out",
              icon: const Icon(Icons.logout_rounded),
              onPressed: _confirmLogout,
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

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _files.length + 2,
                itemBuilder: (_, i) {
                  if (i == 0 && _quotaAvailable) {
                    return StorageUsageCard(
                      usedBytes: _usedBytes,
                      limitBytes: _limitBytes,
                    );
                  }

                  if (i == 1 && _showSwipeHint) {
                    return Card(
                      color: Colors.blueGrey.withOpacity(0.12),
                      child: ListTile(
                        leading:
                            const Icon(Icons.swipe, color: Colors.white70),
                        title: const Text("Swipe to delete"),
                        subtitle: const Text(
                          "Swipe a file left to remove it from your vault",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _showSwipeHint = false),
                        ),
                      ),
                    );
                  }

                  final index = i - 2;
                  if (index < 0 || index >= _files.length) {
                    return const SizedBox.shrink();
                  }

                  final f = _files[index];
                  final name = f['filename'] as String;
                  final size = (f['size'] as num).toInt();
                  final color = _iconColor(name);

                  return Dismissible(
                    key: ValueKey(f['file_id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      final removed = _files.removeAt(index);
                      setState(() {});
                      await ApiService.deleteFile(removed['file_id']);
                    },
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(_iconFor(name), color: color),
                        ),
                        title: Text(name, maxLines: 1),
                        subtitle: Text(_formatSize(size)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FilePreviewScreen(
                                fileId: f['file_id'],
                                filename: name,
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

  Widget _loadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, __) => const Card(
        margin: EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(),
          title: SizedBox(height: 14),
          subtitle: SizedBox(height: 10),
        ),
      ),
    );
  }
}

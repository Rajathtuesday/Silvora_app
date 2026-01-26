// ==============================================================
// lib/screens/files/file_list_screen.dart
import 'package:flutter/material.dart';
import 'package:silvora_app/screens/files/trash_screen.dart';
import 'package:silvora_app/services/quota_service.dart';
import 'package:silvora_app/widgets/brand_logo.dart';

import '../../services/api_services.dart';
import '../../services/download_and_decrypt_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFuture = _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // SECURITY: AUTO-LOCK ON BACKGROUND
  // ─────────────────────────────────────────────

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.detached) {
  //     SecureState.lock();
  //   }
  // }
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused ||
  //       state == AppLifecycleState.detached) {
  //     _handleAutoLogout();
  //   }
  // }

  // void _handleAutoLogout() {
  //   SecureState.fullLogout().then((_) {
  //     if (!mounted) return;

  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (_) => const LoginScreen()),
  //       (_) => false,
  //     );
  //   });
  // }
  


  // ─────────────────────────────────────────────
  // DATA LOADING
  // ─────────────────────────────────────────────
 
 Future<void> _loadAll() async {
    print("🔄 [FILES] Loading file list and quota");
    final files = await ApiService.listFiles();
    print("📁 [FILES] Fetched ${files.length} files");
    _files
      ..clear()
      ..addAll(files);
    try{
      print("🔄 [QUOTA] Loading quota");
    final quota = await QuotaService.fetchQuota();
    print("📊 [QUOTA] Used: ${quota.used} / Limit: ${quota.limit}");
    _usedBytes = quota.used;
    _limitBytes = quota.limit;
    _quotaAvailable=true;
  } catch (e){
    //non-faital :show files 
    print("⚠️ [QUOTA] Failed to fetch quota: $e");
    _usedBytes=0;
    _limitBytes=0;
    
  }
}

  Future<void> _refresh() async {
    setState(() {
      _loadFuture = _loadAll();
    });
    await _loadFuture;
  }

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

  void _openUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
    if (mounted) _refresh();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Log out?"),
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

    if (!ok) return;

    // await SecureState.fullLogout();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return mb < 1
        ? "${(bytes / 1024).toStringAsFixed(1)} KB"
        : "${mb.toStringAsFixed(2)} MB";
  }

  IconData _iconFor(String name) {
    final f = name.toLowerCase();
    if (f.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (f.endsWith('.jpg') || f.endsWith('.png')) return Icons.image_rounded;
    if (f.endsWith('.doc') || f.endsWith('.docx')) return Icons.article_rounded;
    if (f.endsWith('.txt')) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _iconColor(String name) {
    final f = name.toLowerCase();
    if (f.endsWith('.pdf')) return Colors.redAccent;
    if (f.endsWith('.jpg') || f.endsWith('.png')) return Colors.blueAccent;
    if (f.endsWith('.doc') || f.endsWith('.docx')) return Colors.indigo;
    return Colors.grey;
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const SilvoraLogo(fontSize: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Trash",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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

          if (snap.hasError) {
            return const Center(
              child: Text(
                "Failed to load files",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          if (_files.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      "No files yet.\nUpload your first file.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _files.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _quotaAvailable ?                  
                   StorageUsageCard(
                    usedBytes: _usedBytes,
                    limitBytes: _limitBytes,
                  )
                  : const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: Text(
                        "Storage quota unavailable",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                final f = _files[i - 1];
                final name = f['filename'] as String;
                final size = (f['size'] as num).toInt();

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
                    _files.removeAt(i - 1);
                    setState(() {});

                    await ApiService.deleteFile(f['file_id']);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
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
                      leading: CircleAvatar(
                        backgroundColor:
                            _iconColor(name).withValues(alpha: 0.12),
                        child:
                            Icon(_iconFor(name), color: _iconColor(name)),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatSize(size)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'download') {
                            await DownloadAndDecryptService
                                .downloadAndDecrypt(
                              fileId: f['file_id'],
                              filename: name,
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'download',
                            child: Text("Download"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
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

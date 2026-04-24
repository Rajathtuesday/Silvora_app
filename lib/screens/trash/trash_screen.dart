import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../theme/silvora_theme.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late Future<List<dynamic>> _trashFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _trashFuture = ApiService.listTrash();
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

  String _daysLeft(dynamic deletedAt) {
    if (deletedAt == null) return "Unknown";
    try {
      final dt = DateTime.parse(deletedAt.toString());
      final purge = dt.add(const Duration(days: 30));
      final diff = purge.difference(DateTime.now()).inDays;
      if (diff <= 0) return "Expires soon";
      return "$diff days left";
    } catch (_) {
      return "30 days";
    }
  }

  Future<void> _restore(String fileId) async {
    try {
      await ApiService.restoreFile(fileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ File restored to your Vault"),
        ),
      );
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Restore failed: $e"),
          backgroundColor: SilvoraColors.error,
        ),
      );
    }
  }

  Future<void> _confirmPermanentDelete(String fileId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilvoraColors.card2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Permanently Delete?",
          style: TextStyle(color: SilvoraColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "\"$label\" will be permanently erased and cannot be recovered.",
          style: const TextStyle(color: SilvoraColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: SilvoraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete Forever", style: TextStyle(color: SilvoraColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.permanentlyDeleteFile(fileId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File permanently erased.")),
        );
        setState(_reload);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Delete failed: $e"),
            backgroundColor: SilvoraColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash Can"),
        leading: const BackButton(color: SilvoraColors.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_reload),
            tooltip: "Refresh",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _trashFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: SilvoraColors.error),
                  const SizedBox(height: 12),
                  Text(
                    "Failed to load Trash",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => setState(_reload),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 72, color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 20),
                  const Text(
                    "Trash is empty",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: SilvoraColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Deleted files appear here for 30 days\nbefore being permanently erased.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SilvoraColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Warning banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: SilvoraColors.warn.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: SilvoraColors.warn, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Files are automatically purged after 30 days. Restore to keep them.",
                        style: TextStyle(color: SilvoraColors.warn.withOpacity(0.9), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final f = items[i] as Map<String, dynamic>;
                    final fileId  = f["file_id"] as String;
                    final label   = (f["filename"] as String?) ?? "Encrypted File";
                    final size    = f["size"] as int? ?? 0;
                    final deletedAt = f["deleted_at"];

                    return Card(
                      color: SilvoraColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: SilvoraColors.error.withOpacity(0.2),
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SilvoraColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: SilvoraColors.error,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: SilvoraColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _formatBytes(size),
                                        style: const TextStyle(color: SilvoraColors.textMuted, fontSize: 12),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.timer_outlined, size: 11, color: SilvoraColors.warn),
                                      const SizedBox(width: 4),
                                      Text(
                                        _daysLeft(deletedAt),
                                        style: const TextStyle(color: SilvoraColors.warn, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            IconButton(
                              icon: const Icon(Icons.restore, color: SilvoraColors.success),
                              tooltip: "Restore",
                              onPressed: () => _restore(fileId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: SilvoraColors.error),
                              tooltip: "Delete Forever",
                              onPressed: () => _confirmPermanentDelete(fileId, label),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

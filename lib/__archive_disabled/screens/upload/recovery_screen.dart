import 'package:flutter/material.dart';

/// Model passed to this screen (keep it simple)
class RecoveryInfo {
  final String fileName;
  final int fileSizeBytes;
  final double progress; // 0.0 → 1.0
  final DateTime startedAt;

  const RecoveryInfo({
    required this.fileName,
    required this.fileSizeBytes,
    required this.progress,
    required this.startedAt,
  });
}

class RecoveryScreen extends StatelessWidget {
  final RecoveryInfo info;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const RecoveryScreen({
    super.key,
    required this.info,
    required this.onResume,
    required this.onDiscard,
  });

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return "${mb.toStringAsFixed(1)} MB";
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} minutes ago";
    return "${diff.inHours} hours ago";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Unfinished Upload"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────
            // Explanation
            // ─────────────────────────────
            Text(
              "Your last upload didn’t finish.",
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "This can happen if the app was closed or the network changed. "
              "You can safely continue from where it stopped.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 32),

            // ─────────────────────────────
            // File summary card
            // ─────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            info.fileName,
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _formatSize(info.fileSizeBytes),
                      style: theme.textTheme.bodySmall,
                    ),

                    const SizedBox(height: 12),

                    LinearProgressIndicator(value: info.progress),

                    const SizedBox(height: 8),

                    Text(
                      "≈ ${(info.progress * 100).toStringAsFixed(0)}% uploaded",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Started ${_formatTimeAgo(info.startedAt)}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),

            const Spacer(),

            // ─────────────────────────────
            // Primary action
            // ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Resume upload",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ─────────────────────────────
            // Secondary action
            // ─────────────────────────────
            Center(
              child: TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Discard upload?"),
                      content: const Text(
                        "This will remove the unfinished upload from this device.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Discard"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    onDiscard();
                  }
                },
                child: const Text("Cancel & discard"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

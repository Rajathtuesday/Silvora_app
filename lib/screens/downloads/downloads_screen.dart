import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import '../../services/downloads_store.dart';
import '../../theme/silvora_theme.dart';

/// The in-app "Downloads" library — files the user has pulled out of the vault.
/// Tap to open, long-press (or the menu) to Share, Save to phone, or Delete.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<DownloadedItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = DownloadsStore.list();

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d > 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return "${d.toStringAsFixed(1)} ${suffixes[i]}";
  }

  IconData _iconFor(String mime) {
    if (mime.startsWith("image/")) return Icons.image_outlined;
    if (mime.startsWith("video/")) return Icons.movie_outlined;
    if (mime == "application/pdf") return Icons.picture_as_pdf_outlined;
    if (mime.startsWith("text/")) return Icons.article_outlined;
    if (mime.contains("zip") || mime.contains("rar")) return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _open(DownloadedItem item) async {
    final res = await DownloadsStore.open(item);
    if (!mounted) return;
    if (res.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't open this file: ${res.message}"),
          backgroundColor: SilvoraColors.error,
        ),
      );
    }
  }

  Future<void> _saveToPhone(DownloadedItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final where = await DownloadsStore.saveToPhone(item);
      messenger.showSnackBar(SnackBar(content: Text("Saved to $where")));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Save to phone failed: ${e.toString().replaceFirst('PlatformException', '').trim()}"),
          backgroundColor: SilvoraColors.error,
        ),
      );
    }
  }

  Future<void> _delete(DownloadedItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilvoraColors.card2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Remove download?", style: TextStyle(color: SilvoraColors.textPrimary)),
        content: Text(
          "\"${item.filename}\" will be removed from this device. It stays safe in your vault.",
          style: const TextStyle(color: SilvoraColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: SilvoraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove", style: TextStyle(color: SilvoraColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DownloadsStore.delete(item);
      if (mounted) setState(_reload);
    }
  }

  void _showActions(DownloadedItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SilvoraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: SilvoraColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: SilvoraColors.primaryLight),
              title: const Text("Open", style: TextStyle(color: SilvoraColors.textPrimary)),
              onTap: () { Navigator.pop(ctx); _open(item); },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share, color: SilvoraColors.primaryLight),
              title: const Text("Share", style: TextStyle(color: SilvoraColors.textPrimary)),
              onTap: () { Navigator.pop(ctx); DownloadsStore.share(item); },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt, color: SilvoraColors.primaryLight),
              title: const Text("Save to phone", style: TextStyle(color: SilvoraColors.textPrimary)),
              subtitle: const Text("Copy to your public Downloads/Silvora folder",
                  style: TextStyle(color: SilvoraColors.textMuted, fontSize: 12)),
              onTap: () { Navigator.pop(ctx); _saveToPhone(item); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: SilvoraColors.error),
              title: const Text("Remove from device", style: TextStyle(color: SilvoraColors.error)),
              onTap: () { Navigator.pop(ctx); _delete(item); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _leading(DownloadedItem item) {
    if (item.mime.startsWith("image/")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(item.path),
          width: 46, height: 46, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconBadge(item.mime),
        ),
      );
    }
    return _iconBadge(item.mime);
  }

  Widget _iconBadge(String mime) => Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: SilvoraColors.primaryGlow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_iconFor(mime), color: SilvoraColors.primaryLight, size: 22),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SilvoraColors.bg,
      appBar: AppBar(
        leading: const BackButton(color: SilvoraColors.textSecondary),
        title: Text("Downloads", style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh",
            onPressed: () => setState(_reload),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<DownloadedItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_done_outlined, size: 72, color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 20),
                  const Text("No downloads yet",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: SilvoraColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text(
                    "Files you download from your vault\nappear here, ready to open or share.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SilvoraColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              return Card(
                color: SilvoraColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: _leading(item),
                  title: Text(item.filename,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: SilvoraColors.textPrimary)),
                  subtitle: Text(_formatBytes(item.size),
                      style: const TextStyle(color: SilvoraColors.textMuted, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, color: SilvoraColors.textSecondary),
                    onPressed: () => _showActions(item),
                  ),
                  onTap: () => _open(item),
                  onLongPress: () => _showActions(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

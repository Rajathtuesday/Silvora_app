import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/download_service.dart';
import '../../services/downloads_store.dart';
import '../../state/secure_state.dart';
import '../../storage/jwt_store.dart';
import '../upload/upload_screen.dart';
import '../downloads/downloads_screen.dart';
import '../trash/trash_screen.dart';
import '../login/login_screen.dart';
import '../settings/change_password_screen.dart';
import '../settings/delete_account_screen.dart';
import '../billing/billing_screen.dart';
import '../../theme/silvora_theme.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> with WidgetsBindingObserver {
  late Future<List<dynamic>> _filesFuture;
  Future<Map<String, dynamic>>? _quotaFuture;
  bool _isDownloading = false;

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Verification is non-blocking — dismissing just hides the banner for this
  // session. Deliberately not persisted: still-unverified is worth
  // resurfacing on the next cold start, not nagged away permanently.
  bool _emailBannerDismissed = false;
  bool _resendingVerification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reloadFiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The most common path to verifying email is: tap the link in the
    // email app, then switch back here. Re-check on resume so the banner
    // clears itself instead of needing a fresh login to notice.
    if (state == AppLifecycleState.resumed && !SecureState.emailVerified) {
      ApiService.fetchCurrentUser().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {
        // Offline or a transient network hiccup on resume — harmless, the
        // banner just stays as-is until the next successful check.
      });
    }
  }

  void _reloadFiles() {
    _filesFuture = ApiService.listFiles();
    _quotaFuture = ApiService.getQuota();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilvoraColors.card2,
        title: const Text("Lock & sign out?", style: TextStyle(color: SilvoraColors.textPrimary)),
        content: const Text(
          "Your vault will be locked and you'll need your master password to get back in.",
          style: TextStyle(color: SilvoraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: SilvoraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sign out", style: TextStyle(color: SilvoraColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    SecureState.logout();
    await JwtStore().clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
                leading: const Icon(Icons.edit_outlined, color: SilvoraColors.primaryLight),
                title: const Text("Rename", style: TextStyle(color: SilvoraColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(f);
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

  // ─── Rename ───────────────────────────────────────────────────
  // The extension is locked deliberately — it's what tells the app (and
  // the OS, on download) how to handle the file; letting someone rename
  // "photo.jpg" to "photo.pdf" wouldn't convert anything, just mislabel it.
  Future<void> _showRenameDialog(Map<String, dynamic> f) async {
    final currentName = (f["filename"] as String?) ?? "Encrypted File";
    final dotIndex = currentName.lastIndexOf(".");
    final hasExtension = dotIndex > 0 && dotIndex < currentName.length - 1;
    final baseName = hasExtension ? currentName.substring(0, dotIndex) : currentName;
    final extension = hasExtension ? currentName.substring(dotIndex) : "";

    final controller = TextEditingController(text: baseName);
    final newBase = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilvoraColors.card2,
        title: const Text("Rename file", style: TextStyle(color: SilvoraColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: SilvoraColors.textPrimary),
          decoration: InputDecoration(
            suffixText: extension,
            suffixStyle: const TextStyle(color: SilvoraColors.textMuted),
            helperText: extension.isEmpty ? null : "Extension can't be changed",
            helperStyle: const TextStyle(color: SilvoraColors.textMuted, fontSize: 11),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: SilvoraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text("Rename", style: TextStyle(color: SilvoraColors.primaryLight)),
          ),
        ],
      ),
    );

    if (newBase == null || newBase.trim().isEmpty || newBase.trim() == baseName) return;

    final newFilename = "${newBase.trim()}$extension";
    try {
      await ApiService.renameFile(f["file_id"] as String, newFilename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Renamed to $newFilename")),
      );
      setState(_reloadFiles);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rename failed: $e"), backgroundColor: SilvoraColors.error),
      );
    }
  }

  // ─── Trash ────────────────────────────────────────────────────
  Future<void> _moveToTrash(String fileId) async {
    try {
      await ApiService.deleteFile(fileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Moved to Trash (auto-purges in 7 days)")),
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

    DecryptedFileResult? result;
    try {
      final String fileId   = f["file_id"] as String;
      final String filename = (f["filename"] as String?) ?? "encrypted.enc";

      result = await DownloadService.downloadAndDecrypt(
        fileId:   fileId,
        filename: filename,
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);

      if (result == null) throw Exception("Decryption returned an empty result.");

      if (previewOnly) {
        if (result.mimeType.startsWith('image/')) {
          // ── Image preview ── (awaited so the temp file lives until closed)
          await showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: SilvoraColors.card,
              contentPadding: const EdgeInsets.all(8),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(result!.file, fit: BoxFit.contain),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("Close", style: TextStyle(color: SilvoraColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () async {
                    final nav = Navigator.of(c);
                    await _saveToLibrary(result!, filename);
                    nav.pop();
                  },
                  child: const Text("Save", style: TextStyle(color: SilvoraColors.primaryLight)),
                ),
              ],
            ),
          );
        } else if (result.mimeType == "text/plain") {
          // ── Text preview ──
          final text = await result.file.readAsString();
          if (!mounted) return;
          await showDialog(
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
          // Not previewable — add it to the Downloads library instead.
          await _saveToLibrary(result, filename);
        }
      } else {
        // ── Add to the in-app Downloads library ──
        await _saveToLibrary(result, filename);
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
    } finally {
      // Wipe the decrypted plaintext from temp storage (zero-knowledge at rest).
      if (result != null) {
        try {
          if (await result.file.exists()) await result.file.delete();
        } catch (_) {}
      }
    }
  }

  // Copy a freshly decrypted file into the in-app Downloads library and offer
  // to open it immediately (WhatsApp-style). The library keeps a persistent
  // copy, so it survives the temp-file wipe in the caller's finally block.
  Future<void> _saveToLibrary(DecryptedFileResult result, String filename) async {
    final item = await DownloadsStore.add(
      source: result.file,
      filename: filename,
      mime: result.mimeType,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Saved to Downloads — ${item.filename}"),
        action: SnackBarAction(label: "OPEN", onPressed: () => DownloadsStore.open(item)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _resendVerification() async {
    setState(() => _resendingVerification = true);
    final message = await ApiService.resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resendingVerification = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Non-blocking reminder, not a gate — recovery already works without
  // email, so this is purely a "please verify when convenient" nudge.
  Widget _buildVerificationBanner() {
    if (SecureState.emailVerified || _emailBannerDismissed) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SilvoraColors.warn.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SilvoraColors.warn.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: SilvoraColors.warn, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Please verify your email. Your vault works fine either way.",
              style: TextStyle(color: SilvoraColors.warn, fontSize: 13),
            ),
          ),
          _resendingVerification
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: SilvoraColors.warn),
                )
              : TextButton(
                  onPressed: _resendVerification,
                  child: const Text("Resend", style: TextStyle(color: SilvoraColors.warn, fontWeight: FontWeight.w700)),
                ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: SilvoraColors.warn),
            onPressed: () => setState(() => _emailBannerDismissed = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Persistent (not dismissible) — real consequences on a real clock, unlike
  // the email-verification nudge. Two phases, told apart by which field the
  // server still has set: graceEndsAt present = still on the paid limit,
  // about to downgrade; purgeAt present (graceEndsAt already cleared) =
  // already downgraded, files beyond 1GB get deleted when purgeAt arrives.
  Widget _buildGracePeriodBanner() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _quotaFuture,
      builder: (ctx, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final graceEndsAt = data["graceEndsAt"] as DateTime?;
        final purgeAt = data["purgeAt"] as DateTime?;
        if (graceEndsAt == null && purgeAt == null) return const SizedBox.shrink();

        final now = DateTime.now();
        String message;
        Color color;
        if (graceEndsAt != null) {
          final days = graceEndsAt.difference(now).inDays.clamp(0, 99);
          message = "Your subscription ended. You'll keep your current storage limit for "
              "$days more day${days == 1 ? '' : 's'}, then move to the free 1GB tier. "
              "Resubscribe any time to keep everything as-is.";
          color = SilvoraColors.warn;
        } else {
          final days = purgeAt!.difference(now).inDays.clamp(0, 99);
          message = "You're over the free 1GB limit. Free up space or resubscribe within "
              "$days day${days == 1 ? '' : 's'}, or your oldest files beyond 1GB will be "
              "permanently deleted.";
          color = SilvoraColors.error;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: TextStyle(color: color, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }

  // A slim storage-usage bar at the top of the vault: "X of Y used".
  Widget _buildUsageCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _quotaFuture,
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final used = snap.data!["used"] as int? ?? 0;
        final limit = snap.data!["limit"] as int? ?? 0;
        final frac = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
        final color = frac < 0.75
            ? SilvoraColors.primary
            : (frac < 0.9 ? SilvoraColors.warn : SilvoraColors.error);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: SilvoraColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SilvoraColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_outlined, size: 18, color: SilvoraColors.primaryLight),
                  const SizedBox(width: 8),
                  const Text("Storage",
                      style: TextStyle(color: SilvoraColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  Text("${(frac * 100).toStringAsFixed(0)}%",
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 8,
                  backgroundColor: SilvoraColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Text("${_formatBytes(used)} of ${_formatBytes(limit)} used",
                  style: const TextStyle(color: SilvoraColors.textMuted, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {bool danger = false}) {
    final color = danger ? SilvoraColors.error : SilvoraColors.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: danger ? SilvoraColors.error : SilvoraColors.textSecondary),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: SilvoraColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Search files…",
                  hintStyle: TextStyle(color: SilvoraColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text("My Vault"),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: SilvoraColors.textSecondary),
                onPressed: () => setState(() {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                }),
              )
            : const Icon(Icons.shield_outlined, color: SilvoraColors.primary),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: SilvoraColors.textSecondary),
              tooltip: "Search",
              onPressed: () => setState(() => _isSearching = true),
            ),
          IconButton(
            icon: const Icon(Icons.download_done_outlined, color: SilvoraColors.textSecondary),
            tooltip: "Downloads",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadsScreen()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: SilvoraColors.textSecondary),
            color: SilvoraColors.card2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) async {
              switch (value) {
                case "trash":
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  );
                  setState(_reloadFiles);
                  break;
                case "refresh":
                  setState(_reloadFiles);
                  break;
                case "password":
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                  break;
                case "billing":
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BillingScreen()),
                  ).then((_) => setState(_reloadFiles)); // tier may have changed
                  break;
                case "delete_account":
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                  );
                  break;
                case "logout":
                  _logout();
                  break;
              }
            },
            itemBuilder: (_) => [
              _menuItem("trash", Icons.delete_outline, "Trash"),
              _menuItem("refresh", Icons.refresh_rounded, "Refresh"),
              _menuItem("password", Icons.key_outlined, "Change password"),
              _menuItem("billing", Icons.workspace_premium_outlined, "Manage subscription"),
              const PopupMenuDivider(),
              _menuItem("delete_account", Icons.delete_forever_outlined, "Delete account", danger: true),
              _menuItem("logout", Icons.lock_outline, "Lock & sign out", danger: true),
            ],
          ),
          const SizedBox(width: 4),
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
          Column(
            children: [
              _buildGracePeriodBanner(),
              _buildVerificationBanner(),
              _buildUsageCard(),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
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

              final allFiles = snapshot.data!;
              if (allFiles.isEmpty) {
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

              final query = _searchQuery.trim().toLowerCase();
              final files = query.isEmpty
                  ? allFiles
                  : allFiles.where((f) {
                      final name = ((f as Map<String, dynamic>)["filename"] as String? ?? "").toLowerCase();
                      return name.contains(query);
                    }).toList();

              if (files.isEmpty) {
                return Center(
                  child: Text(
                    'No files matching "$_searchQuery"',
                    style: const TextStyle(color: SilvoraColors.textMuted),
                  ),
                );
              }

              return RefreshIndicator(
                color: SilvoraColors.primary,
                backgroundColor: SilvoraColors.card2,
                onRefresh: () async {
                  setState(_reloadFiles);
                  await _filesFuture;
                },
                child: ListView.builder(
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
                ),
              );
            },
                ),
              ),
            ],
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

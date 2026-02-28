// ========================================================================
// lib/screens/files/trash_screen.dart
import 'package:flutter/material.dart';
import 'package:silvora_app/__archive_disabled/services/api_services.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late Future<List<dynamic>> _trashFuture;

  static const int retentionDays = 7; // MUST match backend

  @override
  void initState() {
    super.initState();
    _trashFuture = ApiService.listTrash();
  }

  int _daysLeft(String deletedAt) {
    final deleted = DateTime.parse(deletedAt).toLocal();
    final diff = DateTime.now().difference(deleted).inDays;
    return (retentionDays - diff).clamp(0, retentionDays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "Files are permanently deleted after 7 days",
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _trashFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(
              child: Text(
                "Trash is empty",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final trash = snap.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trash.length,
            itemBuilder: (_, i) {
              final f = trash[i];
              final daysLeft = _daysLeft(f['deleted_at']);

              return Card(
                color: Colors.white.withValues(alpha: 0.04),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    f['filename'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "$daysLeft days left",
                    style: TextStyle(
                      color: daysLeft <= 1
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                    ),
                  ),
                  trailing: TextButton(
                    child: const Text("Restore"),
                    onPressed: () async {
                      await ApiService.restoreFile(f['file_id']);
                      setState(() => trash.removeAt(i));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );

  }
}

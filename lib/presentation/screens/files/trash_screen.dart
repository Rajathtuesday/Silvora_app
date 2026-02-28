// import 'package:flutter/material.dart';
// import 'package:silvora_app/services/api_services.dart';

// class TrashScreen extends StatefulWidget {
//   const TrashScreen({super.key});

//   @override
//   State<TrashScreen> createState() => _TrashScreenState();
// }

// class _TrashScreenState extends State<TrashScreen> {
//   late Future<List<dynamic>> _trashFuture;

//   static const int retentionDays = 7; // MUST match backend

//   @override
//   void initState() {
//     super.initState();
//     _trashFuture = ApiService.listTrash();
//   }

//   int _daysLeft(String deletedAt) {
//     final deleted = DateTime.parse(deletedAt).toLocal();
//     final diff = DateTime.now().difference(deleted).inDays;
//     return (retentionDays - diff).clamp(0, retentionDays);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Trash"),
//         bottom: const PreferredSize(
//           preferredSize: Size.fromHeight(20),
//           child: Padding(
//             padding: EdgeInsets.only(bottom: 8),
//             child: Text(
//               "Files are permanently deleted after 7 days",
//               style: TextStyle(fontSize: 12, color: Colors.white60),
//             ),
//           ),
//         ),
//       ),
//       body: FutureBuilder<List<dynamic>>(
//         future: _trashFuture,
//         builder: (_, snap) {
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snap.hasData || snap.data!.isEmpty) {
//             return const Center(
//               child: Text(
//                 "Trash is empty",
//                 style: TextStyle(color: Colors.white70),
//               ),
//             );
//           }

//           final trash = snap.data!;

//           return ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: trash.length,
//             itemBuilder: (_, i) {
//               final f = trash[i];
//               final daysLeft = _daysLeft(f['deleted_at']);

//               return Card(
//                 color: Colors.white.withValues(alpha: 0.04),
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   leading: const Icon(
//                     Icons.delete_outline,
//                     color: Colors.redAccent,
//                   ),
//                   title: Text(
//                     f['filename'],
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(
//                     "$daysLeft days left",
//                     style: TextStyle(
//                       color: daysLeft <= 1
//                           ? Colors.redAccent
//                           : Colors.orangeAccent,
//                     ),
//                   ),
//                   trailing: TextButton(
//                     child: const Text("Restore"),
//                     onPressed: () async {
//                       await ApiService.restoreFile(f['file_id']);
//                       setState(() => trash.removeAt(i));
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );

//   }
// }
//=================================v2=====================================
//------------------------------------------------------------------------------------------------
// File: lib/screens/files/trash_screen.dart
//------------------------------------------------------------------------------------------------
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../../../infrastructure/services/api_services.dart';
// import '../../../crypto/filename_resolver.dart';
// import '../../../state/secure_state.dart';

// class TrashScreen extends StatefulWidget {
//   const TrashScreen({super.key});

//   @override
//   State<TrashScreen> createState() => _TrashScreenState();
// }

// class _TrashScreenState extends State<TrashScreen> {
//   late Future<List<Map<String, dynamic>>> _future;

//   static const int _retentionDays = 7; // must match backend

//   @override
//   void initState() {
//     super.initState();
//     _future = ApiService.listTrash();
//   }

//   // ───────────────── RESTORE ─────────────────

//   Future<void> _restore(Map<String, dynamic> file) async {
//     await ApiService.restoreFile(file['file_id']);
//     setState(() {
//       _future = ApiService.listTrash();
//     });

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("File restored")),
//     );
//   }

//   // ───────────────── HELP DIALOG ─────────────────

//   void _showInfo() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("About Trash"),
//         content: const Text(
//           "Files in Trash are kept temporarily for recovery.\n\n"
//           "They are automatically and permanently deleted after the retention period. "
//           "This process happens securely on the server and cannot be reversed.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Got it"),
//           ),
//         ],
//       ),
//     );
//   }

//   // ───────────────── UI ─────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Trash"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: _showInfo,
//           ),
//         ],
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _future,
//         builder: (_, snap) {
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final files = snap.data ?? [];

//           if (files.isEmpty) {
//             return const Center(
//               child: Text(
//                 "Trash is empty",
//                 style: TextStyle(color: Colors.white54),
//               ),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: files.length,
//             itemBuilder: (_, i) {
//               final f = files[i];
//               final deletedAt =
//                   DateTime.parse(f['deleted_at']).toLocal();
//               final purgeAt =
//                   deletedAt.add(const Duration(days: _retentionDays));
//               final remaining =
//                   purgeAt.difference(DateTime.now()).inDays;

//               return Dismissible(
//                 key: ValueKey(f['file_id']),
//                 direction: DismissDirection.startToEnd,
//                 background: Container(
//                   alignment: Alignment.centerLeft,
//                   padding: const EdgeInsets.only(left: 20),
//                   color: Colors.green,
//                   child: const Icon(Icons.restore, color: Colors.white),
//                 ),
//                 confirmDismiss: (_) async {
//                   await _restore(f);
//                   return false; // prevent auto-removal animation
//                 },
//                 child: Card(
//                   child: ListTile(
//                     leading: const Icon(Icons.delete_outline),
//                     title: FutureBuilder<String>(
//                       future: FilenameResolver.resolve(
//                         fileId: f['file_id'],
//                         ciphertextHex: f['filename_enc'],
//                         nonceHex: f['filename_nonce'],
//                         macHex: f['filename_hash'],
//                       ),
//                       builder: (_, snap) =>
//                           Text(snap.data ?? "Encrypted file"),
//                     ),
//                     subtitle: Text(
//                       remaining > 0
//                           ? "Deletes in $remaining days"
//                           : "Pending deletion",
//                       style: TextStyle(
//                         color: remaining <= 1
//                             ? Colors.redAccent
//                             : Colors.orangeAccent,
//                       ),
//                     ),
//                     trailing: Text(
//                       DateFormat.yMMMd().format(deletedAt),
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
// ============================v3================================================
// lib/presentation/screens/files/trash_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../infrastructure/services/api_services.dart';
import '../../../crypto/filename_resolver.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  static const int _retentionDays = 7;

  @override
  void initState() {
    super.initState();
    _future = ApiService.listTrash();
  }

  Future<void> _restore(Map<String, dynamic> file) async {
    await ApiService.restoreFile(file['file_id']);
    setState(() => _future = ApiService.listTrash());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File restored")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trash")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final files = snap.data!;
          if (files.isEmpty) {
            return const Center(
              child: Text(
                "Trash is empty",
                style: TextStyle(color: Color(0xFFB8B8C7)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (_, i) {
              final f = files[i];
              final deletedAt =
                  DateTime.parse(f['deleted_at']).toLocal();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: FutureBuilder<String>(
                    future: FilenameResolver.resolve(
                      fileId: f['file_id'],
                      ciphertextHex: f['filename_enc'],
                      nonceHex: f['filename_nonce'],
                      macHex: f['filename_hash'],
                    ),
                    builder: (_, snap) =>
                        Text(snap.data ?? "Encrypted file"),
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd().format(deletedAt),
                    style: const TextStyle(
                      color: Color(0xFFB8B8C7),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore),
                    onPressed: () => _restore(f),
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
  // import 'package:flutter/material.dart';
  // import '../services/vault_service.dart';

  // class VaultUnlockDialog {
  //   static Future<void> requireUnlock(BuildContext context) async {
  //     final controller = TextEditingController();

  //     final password = await showDialog<String>(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => AlertDialog(
  //         title: const Text("Unlock vault"),
  //         content: TextField(
  //           controller: controller,
  //           obscureText: true,
  //           autofocus: true,
  //           decoration: const InputDecoration(
  //             labelText: "Account password",
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.pop(context, controller.text),
  //             child: const Text("Unlock"),
  //           ),
  //         ],
  //       ),
  //     );

  //     if (password == null || password.isEmpty) {
  //       throw StateError("Vault unlock cancelled");
  //     }

  //     await VaultService.unlockWithPassword(password);
  //   }
  // }

import 'package:flutter/material.dart';

class VaultUnlockedScreen extends StatelessWidget {
  const VaultUnlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "🔓 Vault Unlocked",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

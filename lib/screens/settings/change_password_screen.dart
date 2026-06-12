import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../crypto/argon2.dart';
import '../../crypto/xchacha.dart';
import '../../crypto/recovery_crypto.dart';
import '../../services/auth_client.dart';
import '../../state/secure_state.dart';
import '../../theme/silvora_theme.dart';

/// Logged-in password change. The master key is already unlocked in memory, so
/// we just re-wrap it under the new password (the recovery phrase stays valid).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _hex(Uint8List b) => RecoveryCrypto.toHex(b);

  Future<void> _change() async {
    final pw = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pw.length < 12) {
      setState(() => _error = "Password must be at least 12 characters.");
      return;
    }
    if (pw != confirm) {
      setState(() => _error = "Passwords do not match.");
      return;
    }
    if (!SecureState.isUnlocked) {
      setState(() => _error = "Vault is locked. Unlock it first.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final masterKey = SecureState.masterKey;
      final rand = Random.secure();
      final salt = Uint8List.fromList(List.generate(16, (_) => rand.nextInt(256)));
      final kek = await Argon2Kdf.deriveKey(
        password: pw, salt: salt, iterations: 3, memoryKb: 65536, parallelism: 1,
      );
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);
      final envelope = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);

      final res = await AuthClient.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/master-key/change-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "new_password": pw,
          "enc_master_key": _hex(envelope),
          "enc_master_key_nonce": _hex(Uint8List.fromList(nonce)),
          "kdf_salt": _hex(salt),
          "kdf_iterations": 3,
          "kdf_memory_kb": 65536,
          "kdf_parallelism": 1,
        }),
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed.")),
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = "Couldn't change password. Try again.");
      }
    } catch (_) {
      setState(() => _error = "Connection error. Check your network.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SilvoraColors.bg,
      appBar: AppBar(
        leading: const BackButton(color: SilvoraColors.textSecondary),
        title: Text("Change Password", style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Your files stay safe — only the password that unlocks them changes. "
                "Your recovery phrase keeps working.",
                style: TextStyle(color: SilvoraColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New password (min 12)", prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _change(),
                decoration: const InputDecoration(labelText: "Confirm new password", prefixIcon: Icon(Icons.lock_outline)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: SilvoraColors.error)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _change,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Change password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

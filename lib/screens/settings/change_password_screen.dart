import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../crypto/argon2.dart';
import '../../crypto/xchacha.dart';
import '../../crypto/recovery_crypto.dart';
import '../../crypto/login_auth.dart';
import '../../crypto/password_strength.dart';
import '../../crypto/zeroize.dart';
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
  final _currentPasswordCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _hex(Uint8List b) => RecoveryCrypto.toHex(b);

  Future<void> _change() async {
    final pw = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    final strengthError = PasswordStrength.validate(pw);
    if (strengthError != null) {
      setState(() => _error = strengthError);
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
    if (_currentPasswordCtrl.text.isEmpty) {
      setState(() => _error = "Enter your current password.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      // Prove we actually know the current password before proceeding --
      // same requirement delete_account_screen.dart already enforces.
      // Fetched fresh (not assumed) since this account's real KDF params
      // may differ from the fixed constants used for the NEW password below.
      final metaRes = await AuthClient.get(
        Uri.parse("${SecureState.serverUrl}/api/auth/master-key/"),
      );
      if (metaRes.statusCode != 200) {
        setState(() => _error = "Could not verify your current password. Try again.");
        return; // `finally` below resets _isLoading
      }
      final meta = jsonDecode(metaRes.body) as Map<String, dynamic>;
      final currentKek = await Argon2Kdf.deriveKey(
        password: _currentPasswordCtrl.text,
        salt: RecoveryCrypto.fromHex(meta["kdf_salt_hex"] as String),
        iterations: (meta["kdf_iterations"] ?? 3) as int,
        memoryKb: (meta["kdf_memory_kb"] ?? 65536) as int,
        parallelism: (meta["kdf_parallelism"] ?? 1) as int,
      );
      final currentLoginAuthKey = await LoginAuthCrypto.deriveLoginAuthKey(currentKek);
      zeroize(currentKek); // last use -- same pattern as every other transient KEK here

      final masterKey = SecureState.masterKey;
      final rand = Random.secure();
      final salt = Uint8List.fromList(List.generate(16, (_) => rand.nextInt(256)));
      final kek = await Argon2Kdf.deriveKey(
        password: pw, salt: salt, iterations: 3, memoryKb: 65536, parallelism: 1,
      );
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);
      final envelope = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
      // The new password never reaches the server -- only a one-way
      // HKDF-derived proof of possession does, same as login/register.
      final loginAuthKey = await LoginAuthCrypto.deriveLoginAuthKey(kek);
      zeroize(kek); // last use above -- NOT masterKey, which is the live
      // SecureState.masterKey by reference (line 61), still needed for the
      // rest of this unlocked session.

      final res = await AuthClient.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/master-key/change-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "current_password": _hex(currentLoginAuthKey),
          "new_password": _hex(loginAuthKey),
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
      } else if (res.statusCode == 403) {
        setState(() => _error = "Current password is incorrect.");
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
                controller: _currentPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current password", prefixIcon: Icon(Icons.lock_person_outlined)),
              ),
              const SizedBox(height: 16),
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

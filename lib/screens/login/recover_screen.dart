import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../crypto/argon2.dart';
import '../../crypto/xchacha.dart';
import '../../crypto/recovery_crypto.dart';
import '../../state/secure_state.dart';
import '../../theme/silvora_theme.dart';

/// Logged-out password reset using the 24-word recovery phrase.
class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _emailCtrl = TextEditingController();
  final _phraseCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _ok;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phraseCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _hex(Uint8List b) => RecoveryCrypto.toHex(b);

  Future<void> _recover() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final phrase = _phraseCtrl.text.trim();
    final pw = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || phrase.isEmpty || pw.isEmpty) {
      setState(() => _error = "All fields are required.");
      return;
    }
    if (!RecoveryCrypto.isValidPhrase(phrase)) {
      setState(() => _error = "That doesn't look like a valid 24-word recovery phrase.");
      return;
    }
    if (pw.length < 12) {
      setState(() => _error = "New password must be at least 12 characters.");
      return;
    }
    if (pw != confirm) {
      setState(() => _error = "Passwords do not match.");
      return;
    }

    setState(() { _isLoading = true; _error = null; _ok = null; });

    try {
      // 1) Fetch the recovery envelope for this email.
      final startRes = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/recover/start/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      if (startRes.statusCode == 404) {
        setState(() => _error = "No recovery is set up for this account.");
        return;
      }
      if (startRes.statusCode != 200) {
        setState(() => _error = "Couldn't start recovery. Try again.");
        return;
      }
      final meta = jsonDecode(startRes.body);

      // 2) Re-derive the Recovery-KEK and decrypt the master key.
      final rSalt = RecoveryCrypto.fromHex(meta["recovery_kdf_salt_hex"]);
      final rNonce = RecoveryCrypto.fromHex(meta["recovery_nonce_hex"]);
      final rEnc = RecoveryCrypto.fromHex(meta["recovery_encrypted_master_key_hex"]);
      final rKek = await RecoveryCrypto.deriveKek(
        phrase, rSalt,
        iterations: (meta["recovery_kdf_iterations"] ?? 3) as int,
        memoryKb: (meta["recovery_kdf_memory_kb"] ?? 65536) as int,
        parallelism: (meta["recovery_kdf_parallelism"] ?? 1) as int,
      );

      Uint8List masterKey;
      try {
        masterKey = await XChaCha.decrypt(
          ciphertext: rEnc.sublist(0, rEnc.length - 16),
          key: rKek,
          nonce: rNonce,
          mac: rEnc.sublist(rEnc.length - 16),
        );
      } catch (_) {
        setState(() => _error = "Wrong recovery phrase for this account.");
        return;
      }

      // 3) Re-wrap the master key under the NEW password.
      final rand = Random.secure();
      final salt = Uint8List.fromList(List.generate(16, (_) => rand.nextInt(256)));
      final kek = await Argon2Kdf.deriveKey(
        password: pw, salt: salt, iterations: 3, memoryKb: 65536, parallelism: 1,
      );
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);
      final envelope = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
      final authKey = await RecoveryCrypto.deriveAuthKey(rKek);

      // 4) Submit the reset (server verifies the auth-key, sets the new password).
      final res = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/recover/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "recovery_auth_key": _hex(authKey),
          "new_password": pw,
          "enc_master_key": _hex(envelope),
          "enc_master_key_nonce": _hex(Uint8List.fromList(nonce)),
          "kdf_salt": _hex(salt),
          "kdf_iterations": 3,
          "kdf_memory_kb": 65536,
          "kdf_parallelism": 1,
        }),
      );

      if (res.statusCode == 200) {
        setState(() => _ok = "Password reset. You can sign in with your new password.");
      } else if (res.statusCode == 403) {
        setState(() => _error = "Recovery verification failed.");
      } else {
        setState(() => _error = "Reset failed. Please try again.");
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
        title: Text("Reset Password", style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Enter your email, your 24-word recovery phrase, and a new password.",
                style: TextStyle(color: SilvoraColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phraseCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Recovery phrase (24 words)",
                  alignLabelWithHint: true,
                ),
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
                onSubmitted: (_) => _recover(),
                decoration: const InputDecoration(labelText: "Confirm new password", prefixIcon: Icon(Icons.lock_outline)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: SilvoraColors.error)),
              ],
              if (_ok != null) ...[
                const SizedBox(height: 16),
                Text(_ok!, style: const TextStyle(color: SilvoraColors.success)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading || _ok != null ? null : _recover,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Reset password"),
              ),
              if (_ok != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to sign in", style: TextStyle(color: SilvoraColors.primaryLight)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

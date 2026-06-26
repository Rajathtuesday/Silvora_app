import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../crypto/argon2.dart';
import '../../crypto/master_key.dart';
import '../../crypto/xchacha.dart';
import '../../crypto/recovery_crypto.dart';
import '../../state/secure_state.dart';
import '../../theme/silvora_theme.dart';
import 'recovery_phrase_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _acceptedPrivacyPolicy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _hex(Uint8List b) => RecoveryCrypto.toHex(b);

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "All fields are required.");
      return;
    }
    if (password.length < 12) {
      setState(() => _errorMessage = "Password must be at least 12 characters.");
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }
    if (!_acceptedPrivacyPolicy) {
      setState(() => _errorMessage = "You must accept the Privacy Policy to continue.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/register/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "accepted_privacy_policy": _acceptedPrivacyPolicy,
        }),
      );

      if (res.statusCode != 201) {
        final body = jsonDecode(res.body);
        String msg = "Registration failed.";
        if (body is Map && body.isNotEmpty) {
          final firstVal = body[body.keys.first];
          msg = firstVal is List ? firstVal.first.toString() : firstVal.toString();
        }
        setState(() => _errorMessage = msg);
        return;
      }

      // Authenticate so we can store the envelope.
      final authResp = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/token/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": email, "password": password}),
      );
      if (authResp.statusCode != 200) {
        setState(() => _errorMessage = "Account made, but sign-in failed. Try logging in.");
        return;
      }
      SecureState.accessToken = jsonDecode(authResp.body)["access"];

      // ── The master key, wrapped two ways ───────────────────────────
      final masterKey = MasterKey.generate();

      // 1) Password-wrapped envelope
      final random = Random.secure();
      final salt = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
      final kek = await Argon2Kdf.deriveKey(
        password: password, salt: salt,
        iterations: 3, memoryKb: 65536, parallelism: 1,
      );
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);
      final envelope = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);

      // 2) Recovery-phrase-wrapped envelope
      final phrase = RecoveryCrypto.generatePhrase();
      final rSalt = RecoveryCrypto.newSalt();
      final rKek = await RecoveryCrypto.deriveKek(phrase, rSalt);
      final rNonce = await XChaCha.randomNonce();
      final rBox = await XChaCha.encrypt(plaintext: masterKey, key: rKek, nonce: rNonce);
      final rEnvelope = Uint8List.fromList([...rBox.cipherText, ...rBox.mac.bytes]);
      final authKey = await RecoveryCrypto.deriveAuthKey(rKek);

      final setupResp = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/master-key/setup/"),
        headers: SecureState.authHeader(),
        body: jsonEncode({
          "kdf_salt": _hex(salt),
          "kdf_iterations": 3,
          "kdf_memory_kb": 65536,
          "kdf_parallelism": 1,
          "enc_master_key": _hex(envelope),
          "enc_master_key_nonce": _hex(Uint8List.fromList(nonce)),
          // recovery
          "enc_master_key_recovery": _hex(rEnvelope),
          "enc_master_key_recovery_nonce": _hex(Uint8List.fromList(rNonce)),
          "recovery_kdf_salt": _hex(rSalt),
          "recovery_kdf_iterations": 3,
          "recovery_kdf_memory_kb": 65536,
          "recovery_kdf_parallelism": 1,
          "recovery_auth_key": _hex(authKey),
        }),
      );

      if (setupResp.statusCode != 201) {
        setState(() => _errorMessage = "Failed to secure vault. Please try again.");
        return;
      }

      if (!mounted) return;
      // Show the recovery phrase before sending them to log in.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RecoveryPhraseScreen(phrase: phrase)),
      );
    } catch (e) {
      setState(() => _errorMessage = "Connection failed. Check your network.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SilvoraColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: SilvoraColors.textSecondary),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_person_rounded, size: 64, color: SilvoraColors.primaryLight),
                const SizedBox(height: 24),
                Text(
                  "Join Silvora",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    color: SilvoraColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Zero-Knowledge from day one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SilvoraColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Password (min 12 chars)",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                  decoration: const InputDecoration(
                    labelText: "Confirm password",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _acceptedPrivacyPolicy,
                      activeColor: SilvoraColors.primary,
                      onChanged: (v) => setState(() => _acceptedPrivacyPolicy = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _acceptedPrivacyPolicy = !_acceptedPrivacyPolicy),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: SilvoraColors.textSecondary, fontSize: 13),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: const TextStyle(color: SilvoraColors.primaryLight, fontWeight: FontWeight.w600),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => launchUrl(
                                        Uri.parse("${SecureState.serverUrl}/privacy/"),
                                        mode: LaunchMode.externalApplication,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SilvoraColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SilvoraColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: SilvoraColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: SilvoraColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SilvoraColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Create Secure Vault"),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Your password never leaves your device.\nSilvora uses zero-knowledge encryption.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SilvoraColors.textMuted, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../crypto/argon2.dart';
import '../../crypto/master_key.dart';
import '../../crypto/xchacha.dart';
import '../../state/secure_state.dart';
import '../../theme/silvora_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _passwordCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "All fields are required.");
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = "Password must be at least 8 characters.");
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
          "email":    email,
          "password": password,
        }),
      );

      if (res.statusCode == 201) {
        // --- MASTER KEY SETUP ---
        final authResp = await http.post(
          Uri.parse("${SecureState.serverUrl}/api/auth/token/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": email, "password": password}),
        );
        
        if (authResp.statusCode == 200) {
          final authData = jsonDecode(authResp.body);
          SecureState.accessToken = authData["access"];
          
          final masterKey = MasterKey.generate();
          
          final random = Random.secure();
          final salt = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
          final kek = await Argon2Kdf.deriveKey(password: password, salt: salt, iterations: 3);
          
          final nonce = await XChaCha.randomNonce();
          final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);
          
          final envelopeBytes = Uint8List.fromList([...box.cipherText, ...box.mac.macBytes]);
          
          String bytesToHex(Uint8List bytes) {
            return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
          }

          await http.post(
            Uri.parse("${SecureState.serverUrl}/api/auth/master-key/setup/"),
            headers: SecureState.authHeader(),
            body: jsonEncode({
              "kdf_salt": bytesToHex(salt),
              "kdf_iterations": 3,
              "enc_master_key": bytesToHex(envelopeBytes),
              "enc_master_key_nonce": bytesToHex(nonce),
              "key_version": 1
            }),
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Vault created! Please sign in."),
          ),
        );
        Navigator.pop(context);
      } else {
        final body = jsonDecode(res.body);
        // Extract first field error message if available
        String msg = "Registration failed.";
        if (body is Map) {
          final firstKey = body.keys.first;
          final firstVal = body[firstKey];
          if (firstVal is List) {
            msg = "${firstKey}: ${firstVal.first}";
          } else {
            msg = firstVal.toString();
          }
        }
        setState(() => _errorMessage = msg);
      }
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
                // ── Header ──────────────────────────
                const Icon(
                  Icons.lock_person_rounded,
                  size: 64,
                  color: SilvoraColors.gold,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Join Silvora",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SilvoraColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Zero-Knowledge from day one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SilvoraColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Fields ──────────────────────────
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                // ── Error ───────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SilvoraColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SilvoraColors.error.withOpacity(0.4)),
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

                // ── Submit ──────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SilvoraColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text("Create Secure Vault"),
                ),

                const SizedBox(height: 32),

                // ── Compliance note ─────────────────
                const Text(
                  "Your password never leaves your device.\nSilvora uses zero-knowledge encryption.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SilvoraColors.textMuted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/vault_service.dart';
import '../../state/secure_state.dart';
import '../../storage/jwt_store.dart';
import '../files/file_list_screen.dart';
import 'login_screen.dart';
import '../../theme/silvora_theme.dart';

/// Shown on app restart when a saved session exists. The user only needs to
/// re-enter their master password to unlock the vault (no full login).
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await VaultService.unlock(password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FileListScreen()),
      );
    } on VaultAuthException {
      // Session no longer valid; send them to a full login.
      await _signOut();
    } catch (_) {
      setState(() => _errorMessage = "Wrong password, or vault unavailable.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    SecureState.logout();
    await JwtStore().clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 72, color: SilvoraColors.primaryLight),
                const SizedBox(height: 20),
                Text(
                  "Welcome back",
                  style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w700, color: SilvoraColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your master password to unlock your vault.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SilvoraColors.textSecondary),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _unlock(),
                  decoration: const InputDecoration(labelText: "Master Password"),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: SilvoraColors.error),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _unlock,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Unlock Vault"),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _signOut,
                  child: const Text(
                    "Not you? Sign out",
                    style: TextStyle(color: SilvoraColors.textMuted),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_services.dart';
import '../../state/secure_state.dart';
import '../../storage/jwt_store.dart';
import '../../theme/silvora_theme.dart';
import '../login/login_screen.dart';

/// Permanently deletes the account: encrypted files, key envelopes, and the
/// account record. Requires the account password as a final confirmation.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmTextCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmTextCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _passwordCtrl.text.isNotEmpty &&
      _confirmTextCtrl.text.trim().toUpperCase() == "DELETE";

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilvoraColors.card2,
        title: const Text("Delete account permanently?",
            style: TextStyle(color: SilvoraColors.textPrimary)),
        content: const Text(
          "This will permanently delete all your files and your account. "
          "This cannot be undone.",
          style: TextStyle(color: SilvoraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: SilvoraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete everything", style: TextStyle(color: SilvoraColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      await ApiService.deleteAccount(_passwordCtrl.text);

      SecureState.logout();
      await JwtStore().clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
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
        title: Text("Delete Account", style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SilvoraColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SilvoraColors.error.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  "This permanently deletes all your files, your encryption keys, "
                  "and your account. There is no recovery — not even by us, since "
                  "we never have your keys.",
                  style: TextStyle(color: SilvoraColors.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: "Account password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmTextCtrl,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: SilvoraColors.error)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: SilvoraColors.error),
                onPressed: (_isLoading || !_canSubmit) ? null : _delete,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Permanently delete my account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

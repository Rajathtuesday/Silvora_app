import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../state/secure_state.dart';
import '../../storage/jwt_store.dart';
import '../../services/vault_service.dart';
import '../../services/api_services.dart';
import '../files/file_list_screen.dart';
import 'register_screen.dart';
import 'recover_screen.dart';
import '../../theme/silvora_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final server = SecureState.serverUrl;
      
      // 1. Authenticate and get JWT
      final authResp = await http.post(
        Uri.parse("$server/api/auth/token/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (authResp.statusCode != 200) {
        setState(() => _errorMessage = "Invalid credentials.");
        return;
      }

      final authData = jsonDecode(authResp.body);
      SecureState.accessToken = authData["access"];
      SecureState.refreshToken = authData["refresh"];

      // Persist the session so it survives an app restart.
      await JwtStore().saveTokens(authData["access"], authData["refresh"]);

      // Fetch the master-key envelope and unlock the vault locally.
      try {
        await VaultService.unlock(password);
      } catch (e) {
        setState(() => _errorMessage = "Failed to unlock vault. Check your password.");
        return;
      }

      // Best-effort — never blocks login if it fails (non-blocking design).
      await ApiService.fetchCurrentUser();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FileListScreen()),
      );
    } catch (e) {
      setState(() => _errorMessage = "Connection error. Is the server running?");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                const Icon(Icons.shield_outlined, size: 80, color: SilvoraColors.primaryLight),
                const SizedBox(height: 16),
                Text("Silvora Vault", style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w700, color: SilvoraColors.textPrimary)),
                const SizedBox(height: 48),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Email or Username"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Master Password"),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_errorMessage!, style: const TextStyle(color: SilvoraColors.error)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _doLogin,
                    child: _isLoading ? const CircularProgressIndicator() : const Text("Unlock Vault"),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text("Create a new private vault"),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoverScreen())),
                  child: const Text("Forgot password?", style: TextStyle(color: SilvoraColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

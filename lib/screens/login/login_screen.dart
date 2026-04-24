import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../state/secure_state.dart';
import '../files/file_list_screen.dart';
import 'register_screen.dart';
import '../../theme/silvora_theme.dart';
import '../../crypto/argon2.dart';
import '../../crypto/xchacha.dart';

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

      // 2. Fetch Master Key Envelope from Server
      final metaResp = await http.get(
        Uri.parse("$server/api/auth/masterkey/meta/"),
        headers: SecureState.authHeader(),
      );

      if (metaResp.statusCode == 200) {
        final meta = jsonDecode(metaResp.body);
        
        // 3. Decrypt Master Key locally using user password
        try {
          final decryptedKey = await _unlockVault(password, meta);
          SecureState.setMasterKey(decryptedKey);
        } catch (e) {
          setState(() => _errorMessage = "Failed to unlock vault. Security mismatch.");
          return;
        }
      } else {
        setState(() => _errorMessage = "Vault security record missing for this account.");
        return;
      }

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

  /// The core Zero-Knowledge unlock flow.
  /// KDF(password, salt) -> KEK
  /// Decrypt(envelope, KEK) -> Master Key
  Future<Uint8List> _unlockVault(String password, Map<String, dynamic> meta) async {
    final salt = _hexToBytes(meta["kdf_salt_hex"]);
    final nonce = _hexToBytes(meta["nonce_hex"]);
    final iterations = meta["kdf_iterations"] ?? 3; // match backend defaults
    
    // 1. Derive Key Encrypting Key (KEK) from user password
    final kek = await Argon2Kdf.deriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
    );

    // 2. Decrypt the Master Key
    final encryptedHex = meta["encrypted_master_key_hex"]; 
    final encryptedBytes = _hexToBytes(encryptedHex);
    
    // Our envelope format: ciphertext || mac (16 bytes)
    final mac = encryptedBytes.sublist(encryptedBytes.length - 16);
    final ciphertext = encryptedBytes.sublist(0, encryptedBytes.length - 16);

    return await XChaCha.decrypt(
      ciphertext: ciphertext,
      key: kek,
      nonce: nonce,
      mac: mac,
    );
  }

  Uint8List _hexToBytes(String hex) {
    final res = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      res.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(res);
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
                const Icon(Icons.shield_outlined, size: 80, color: SilvoraColors.gold),
                const SizedBox(height: 16),
                const Text("Silvora Vault", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

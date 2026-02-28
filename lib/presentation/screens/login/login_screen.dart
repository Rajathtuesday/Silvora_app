
// //===========================================================================
// lib/screens/login/login_screen.dart

// import 'dart:convert';
// import 'dart:math' as math;
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// // import 'package:silvora_app/crypto/master_key_crypto.dart';
// import 'package:silvora_app/crypto/master_key_provider.dart';
// import 'package:silvora_app/widgets/brand_logo.dart';
// import 'package:convert/convert.dart';
// import '../../crypto/master_key_crypto.dart';

// import '../../state/secure_state.dart';
// import 'register_screen.dart';
// import '../../storage/jwt_store.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _isLoading = false;
//   bool _showPassword = false;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // LOGIN LOGIC
//   // ─────────────────────────────────────────────

// //   Future<void> _doLogin() async {
// //   if (_isLoading) return;

// //   final email = _emailController.text.trim().toLowerCase();
// //   final password = _passwordController.text;

// //   if (email.isEmpty || password.isEmpty) {
// //     setState(() {
// //       _errorMessage = "Please enter both email and password.";
// //     });
// //     return;
// //   }

// //   setState(() {
// //     _isLoading = true;
// //     _errorMessage = null;
// //   });

// //   try {
// //     final resp = await http.post(
// //       Uri.parse("${SecureState.serverUrl}/api/auth/token/"),
// //       headers: const {"Content-Type": "application/json"},
// //       body: jsonEncode({
// //         "username": email,
// //         "password": password,
// //       }),
// //     );

// //     if (resp.statusCode != 200) {
// //       setState(() {
// //         _errorMessage = "Incorrect email or password.";
// //       });
// //       return;
// //     }

// //     final data = jsonDecode(resp.body);
// //     final access = data["access"];
// //     final refresh = data["refresh"];

// //     // ✅ SAVE TOKENS
// //     await JwtStore().saveTokens(access, refresh);

// //     // ✅ LOAD INTO MEMORY
// //     SecureState.accessToken = access;
// //     SecureState.refreshToken = refresh;

// //     // 🔐 Unlock vault
// //     // await VaultService.unlockWithPassword(password);

// //     if (!mounted) return;
// //     Navigator.pushReplacementNamed(context, '/files');
// //   } catch (_) {
// //     setState(() {
// //       _errorMessage = "Unable to connect. Check your internet.";
// //     });
// //   } finally {
// //     if (mounted) setState(() => _isLoading = false);
// //   }
// // }


//   Future<void> _initializeMasterKey(
//     String password,
//     String accessToken,
//   ) async {
//     // 1️⃣ Generate random master key (32 bytes)
//     final masterKey = MasterKeyCrypto.randomBytes(32);

//     // 2️⃣ Generate random salt (16 bytes)
//     final salt = MasterKeyCrypto.randomBytes(16);

//     // 3️⃣ Derive KEK from password + salt
//     final kek = await MasterKeyProvider.derive(
//       password: password,
//       salt: salt,
//     );

//     // 4️⃣ Encrypt master key
//     final encryptionResult = await MasterKeyCrypto.encrypt(
//       kek: kek,
//       masterKey: masterKey,
//     );

//     // 5️⃣ Send encrypted blob to server
//     final resp = await http.post(
//       Uri.parse("${SecureState.serverBaseUrl}/api/auth/master-key/setup/"),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $accessToken",
//       },
//       body: jsonEncode({
//         "encrypted_master_key_hex": encryptionResult.cipherHex,
//         "kdf_salt_b64": base64Encode(salt),
//         "kdf_algorithm": "argon2id",
//         "kdf_iterations": 4,
//         "aead_algorithm": "xchacha20-poly1305",
//         "nonce_b64": base64Encode(encryptionResult.nonce),
//       }),
//     );

//     if (resp.statusCode != 200) {
//       throw Exception("Failed to setup master key");
//     }

//     // 6️⃣ Unlock vault with generated master key
//     await SecureState.unlockWithMasterKey(masterKey);
//   }

//   Future<void> _doLogin() async {
//   if (_isLoading) return;

//   final email = _emailController.text.trim().toLowerCase();
//   final password = _passwordController.text;

//   if (email.isEmpty || password.isEmpty) {
//     setState(() {
//       _errorMessage = "Please enter both email and password.";
//     });
//     return;
//   }

//   setState(() {
//     _isLoading = true;
//     _errorMessage = null;
//   });

//   try {
//     // 1️⃣ LOGIN → GET JWT
//     final tokenResp = await http.post(
//       Uri.parse("${SecureState.serverBaseUrl}/api/auth/token/"),
//       headers: const {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "username": email,
//         "password": password,
//       }),
//     );

//     if (tokenResp.statusCode != 200) {
//       setState(() {
//         _errorMessage = "Incorrect email or password.";
//       });
//       return;
//     }

//     final tokenData = jsonDecode(tokenResp.body);
//     final access = tokenData["access"];
//     final refresh = tokenData["refresh"];

//     await JwtStore.instance.saveTokens(access, refresh);
//     SecureState.accessToken = access;
//     SecureState.refreshToken = refresh;

//     // 2️⃣ FETCH MASTER KEY META
//     final metaResp = await http.get(
//       Uri.parse("${SecureState.serverBaseUrl}/api/auth/master-key/meta/"),
//       headers: {
//         "Authorization": "Bearer $access",
//       },
//     );

//     if (metaResp.statusCode != 200) {
//       throw Exception("Failed to fetch master key metadata");
//     }

//     final meta = jsonDecode(metaResp.body);

//     final hasMasterKey = meta["has_master_key"] == true;

//     Future<void> _initializeMasterKey(
//   String password,
//   String accessToken,
// ) async {
//   // 1️⃣ Generate random master key (32 bytes)
//   final masterKey = MasterKeyCrypto.randomBytes(32);

//   // 2️⃣ Generate random salt (16 bytes)
//   final salt = MasterKeyCrypto.randomBytes(16);

//   // 3️⃣ Derive KEK from password + salt
//   final kek = await MasterKeyProvider.derive(
//     password: password,
//     salt: salt,
//   );

//   // 4️⃣ Encrypt master key
//   final encryptionResult = await MasterKeyCrypto.encrypt(
//     kek: kek,
//     masterKey: masterKey,
//   );

//   // 5️⃣ Send encrypted blob to server
//   final resp = await http.post(
//     Uri.parse("${SecureState.serverBaseUrl}/api/auth/master-key/setup/"),
//     headers: {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $accessToken",
//     },
//     body: jsonEncode({
//       "encrypted_master_key_hex": encryptionResult.cipherHex,
//       "kdf_salt_b64": base64Encode(salt),
//       "kdf_algorithm": "argon2id",
//       "kdf_iterations": 4,
//       "aead_algorithm": "xchacha20-poly1305",
//       "nonce_b64": base64Encode(encryptionResult.nonce),
//     }),
//   );

//     if (resp.statusCode != 200) {
//       throw Exception("Failed to setup master key");
//     }

//     // 6️⃣ Unlock vault with generated master key
//     await SecureState.unlockWithMasterKey(masterKey);
//   }


//     // 3️⃣ VALIDATE REQUIRED FIELDS
//     final encryptedHex = meta["encrypted_master_key_hex"];
//     final saltB64 = meta["kdf_salt_b64"];
//     final nonceB64 = meta["nonce_b64"];

//     if (encryptedHex == null || saltB64 == null || nonceB64 == null) {
//       throw Exception("Master key metadata incomplete.");
//     }

//     final salt = base64Decode(saltB64);
//     final nonce = base64Decode(nonceB64);
//     final encryptedBytes = Uint8List.fromList(hex.decode(encryptedHex));

//     // 4️⃣ Derive KEK
//   final kek = await MasterKeyProvider.derive(
//     password: password,
//     salt: salt,
//   );

//   // 5️⃣ Decrypt Master Key using libsodium
//   final cipherBytes = Uint8List.fromList(hex.decode(encryptedHex));

// final masterKey = await MasterKeyCrypto.decrypt(
//   cipherText: cipherBytes,
//   kek: kek,
//   nonce: nonce,
// );



//   // 6️⃣ Unlock vault
//   await SecureState.unlockWithMasterKey(masterKey);


//     if (!mounted) return;
//     Navigator.pushReplacementNamed(context, '/files');
//   } catch (e, st) {
//     print("Login error: $e");
//     print(st);
//     setState(() {
//       _errorMessage = "Login failed. Please try again.";
//     });
//   } finally {
//     if (mounted) setState(() => _isLoading = false);
//   }
// }



//   // ─────────────────────────────────────────────
//   // UI
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [
//           _buildBackground(),
//           _buildHexGrid(),
//           _buildLoginCard(context),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoginCard(BuildContext context) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.lock_outline_rounded,
//               color: Color(0xFF9255E8),
//               size: 68,
//             ),
//             const SizedBox(height: 12),
//             const SilvoraLogo(fontSize: 28),
//             const SizedBox(height: 6),
//             const Text(
//               "Zero-knowledge encrypted storage",
//               style: TextStyle(
//                 color: Color(0xFFB38CFF),
//                 fontSize: 13,
//               ),
//             ),
//             const SizedBox(height: 32),

//             _buildTextField(
//               controller: _emailController,
//               label: "Email",
//               icon: Icons.email_outlined,
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 16),

//             _buildTextField(
//               controller: _passwordController,
//               label: "Password",
//               icon: Icons.lock_outline,
//               obscure: !_showPassword,
//               suffix: IconButton(
//                 icon: Icon(
//                   _showPassword
//                       ? Icons.visibility_off
//                       : Icons.visibility,
//                   color: Colors.white54,
//                 ),
//                 onPressed: () {
//                   setState(() => _showPassword = !_showPassword);
//                 },
//               ),
//             ),

//             const SizedBox(height: 8),
//             const Text(
//               "Your password never leaves your device",
//               style: TextStyle(
//                 color: Colors.white54,
//                 fontSize: 12,
//               ),
//             ),

//             const SizedBox(height: 20),

//             if (_errorMessage != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Text(
//                   _errorMessage!,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: Colors.redAccent,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _doLogin,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF9255E8),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 6,
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                         height: 22,
//                         width: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.5,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Text(
//                         "Unlock Vault",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//               ),
//             ),

//             const SizedBox(height: 18),

//             TextButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const RegisterScreen()),
//                 );
//               },
//               child: const Text(
//                 "Create a new account",
//                 style: TextStyle(
//                   color: Color(0xFFB38CFF),
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//     );
//   }

//   Widget _buildHexGrid() {
//     return Positioned.fill(
//       child: IgnorePointer(
//         child: CustomPaint(
//           painter: _HexGridPainter(
//             color: Colors.white.withOpacity(0.05),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType? keyboardType,
//     bool obscure = false,
//     Widget? suffix,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       keyboardType: keyboardType,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF9255E8)),
//         suffixIcon: suffix,
//         labelText: label,
//         labelStyle: const TextStyle(color: Color(0xFFB38CFF)),
//         filled: true,
//         fillColor: const Color(0xFF16161F),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: Color(0xFF9255E8),
//             width: 1.4,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(
//             color: Colors.white.withOpacity(0.2),
//             width: 1.2,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// ─────────────────────────────────────────────
// /// Hex grid background
// /// ─────────────────────────────────────────────
// class _HexGridPainter extends CustomPainter {
//   final Color color;

//   _HexGridPainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.6;

//     const double r = 16;
//     final double h = 2 * r;
//     final double vert = 0.75 * h;
//     final double horiz = r * math.sqrt(3);

//     for (double y = -h; y < size.height + h; y += vert) {
//       final bool offsetRow = ((y / vert).round() % 2) == 1;
//       for (double x = offsetRow ? -horiz / 2 : 0;
//           x < size.width + horiz;
//           x += horiz) {
//         final center = Offset(x, y);
//         final path = Path();
//         for (int i = 0; i < 6; i++) {
//           final angle = (60 * i - 30) * math.pi / 180;
//           final px = center.dx + r * math.cos(angle);
//           final py = center.dy + r * math.sin(angle);
//           i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
//         }
//         path.close();
//         canvas.drawPath(path, paint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _HexGridPainter oldDelegate) =>
//       oldDelegate.color != color;
// }
// ==============================v5==========================================
// // lib/screens/login/login_screen.dart
// import 'dart:convert';
// import 'dart:math' as math;
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:convert/convert.dart';

// import '../../crypto/master_key_provider.dart';
// import '../../crypto/master_key_crypto.dart';
// import '../../state/secure_state.dart';
// import '../../storage/jwt_store.dart';
// import '../login/register_screen.dart';
// import '../../widgets/brand_logo.dart';
// import '../../services/auth_service.dart';


// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _isLoading = false;
//   bool _showPassword = false;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // ==========================================================
//   // LOGIN FLOW
//   // ==========================================================

//   Future<void> _doLogin() async {
//     if (_isLoading) return;

//     final email = _emailController.text.trim();
//     final password = _passwordController.text;

//     if (email.isEmpty || password.isEmpty) {
//       setState(() => _errorMessage = "Enter email and password");
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       await AuthService.login(
//         email: email,
//         password: password,
//       );

//       if (!mounted) return;

//       Navigator.pushReplacementNamed(context, '/files');

//     } catch (e) {
//       setState(() {
//         _errorMessage = "Login failed";
//       });
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   // ==========================================================
//   // UI
//   // ==========================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           _buildBackground(),
//           _buildLoginCard(context),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoginCard(BuildContext context) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.lock_outline_rounded,
//               color: Color(0xFF9255E8),
//               size: 68,
//             ),
//             const SizedBox(height: 12),
//             const SilvoraLogo(fontSize: 28),
//             const SizedBox(height: 32),

//             _buildTextField(
//               controller: _emailController,
//               label: "Email",
//               icon: Icons.email_outlined,
//             ),
//             const SizedBox(height: 16),

//             _buildTextField(
//               controller: _passwordController,
//               label: "Password",
//               icon: Icons.lock_outline,
//               obscure: !_showPassword,
//               suffix: IconButton(
//                 icon: Icon(
//                   _showPassword
//                       ? Icons.visibility_off
//                       : Icons.visibility,
//                 ),
//                 onPressed: () {
//                   setState(() => _showPassword = !_showPassword);
//                 },
//               ),
//             ),

//             const SizedBox(height: 20),

//             if (_errorMessage != null)
//               Text(
//                 _errorMessage!,
//                 style: const TextStyle(color: Colors.redAccent),
//               ),

//             const SizedBox(height: 16),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _doLogin,
//                 child: _isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text("Unlock Vault"),
//               ),
//             ),

//             const SizedBox(height: 12),

//             TextButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (_) => const RegisterScreen()),
//                 );
//               },
//               child: const Text("Create a new account"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     bool obscure = false,
//     Widget? suffix,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon),
//         suffixIcon: suffix,
//         labelText: label,
//         filled: true,
//       ),
//     );
//   }
// }

// =========================v6=================================

// lib/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import '../../../infrastructure/services/auth_service.dart';
import '../upload/upload_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const UploadScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),

            const Icon(
              Icons.lock_outline,
              size: 72,
              color: Color(0xFF7C5CFF),
            ),

            const SizedBox(height: 24),

            const Text(
              "Secure Cloud Vault",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "End-to-end encrypted storage",
              style: TextStyle(
                color: Color(0xFFB8B8C7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),

            const SizedBox(height: 24),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Unlock Vault"),
              ),
            ),

            const SizedBox(height: 18),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Create account"),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}
}
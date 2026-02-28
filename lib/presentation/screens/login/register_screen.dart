
// // ========================================================================
// lib/screens/login/register_screen.dart

// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import '../../state/secure_state.dart';
// import 'login_screen.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _emailCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();

//   String? _emailError;
//   String? _passwordError;
//   String? _serverError;

//   bool _loading = false;

//   // ─────────────────────────────────────────────
//   // VALIDATION
//   // ─────────────────────────────────────────────

//   bool _isValidEmail(String email) {
//     final emailRegex = RegExp(
//       r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
//     );
//     return emailRegex.hasMatch(email);
//   }

//   bool _isValidPassword(String password) {
//     final hasLetter = RegExp(r"[A-Za-z]").hasMatch(password);
//     final hasNumber = RegExp(r"\d").hasMatch(password);
//     return password.length >= 8 && hasLetter && hasNumber;
//   }

//   bool get _canSubmit =>
//       _emailError == null &&
//       _passwordError == null &&
//       _emailCtrl.text.isNotEmpty &&
//       _passwordCtrl.text.isNotEmpty &&
//       !_loading;

//   void _validateEmail(String value) {
//     if (value.isEmpty) {
//       _emailError = "Email is required";
//     } else if (!_isValidEmail(value)) {
//       _emailError = "Enter a valid email address";
//     } else {
//       _emailError = null;
//     }
//     setState(() {});
//   }

//   void _validatePassword(String value) {
//     if (value.isEmpty) {
//       _passwordError = "Password is required";
//     } else if (!_isValidPassword(value)) {
//       _passwordError =
//           "Min 8 chars, at least 1 letter and 1 number";
//     } else {
//       _passwordError = null;
//     }
//     setState(() {});
//   }

//   // ─────────────────────────────────────────────
//   // REGISTER
//   // ─────────────────────────────────────────────

//   Future<void> _register() async {
//     if (!_canSubmit) return;

//     setState(() {
//       _loading = true;
//       _serverError = null;
//     });

//     try {
//       final email = _emailCtrl.text.trim();
//       final password = _passwordCtrl.text;

//       final res = await http.post(
//         Uri.parse("${SecureState.serverBaseUrl}/api/auth/register/"),
//         headers: const {"Content-Type": "application/json"},
//         body: jsonEncode({
//           // username intentionally set = email
//           "username": email,
//           "email": email,
//           "password": password,
//         }),
//       );

//       if (res.statusCode != 200 && res.statusCode != 201) {
//         final body = res.body.toLowerCase();
//         if (body.contains("email")) {
//           _serverError = "Email already registered";
//         } else {
//           _serverError = "Registration failed";
//         }
//         setState(() {});
//         return;
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Account created. Please log in."),
//         ),
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//     } catch (e) {
//       setState(() {
//         _serverError = "Network error. Try again.";
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

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
//           _background(),
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(
//                     Icons.person_add_alt_1,
//                     color: Color(0xFF9255E8),
//                     size: 64,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     "Create your Silvora vault",
//                     style: TextStyle(
//                       color: Color(0xFFE7D8FF),
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 28),

//                   _field(
//                     controller: _emailCtrl,
//                     label: "Email",
//                     icon: Icons.email,
//                     error: _emailError,
//                     onChanged: _validateEmail,
//                   ),
//                   const SizedBox(height: 14),

//                   _field(
//                     controller: _passwordCtrl,
//                     label: "Password",
//                     icon: Icons.lock,
//                     obscure: true,
//                     error: _passwordError,
//                     onChanged: _validatePassword,
//                   ),

//                   const SizedBox(height: 12),
//                   const Text(
//                     "• Minimum 8 characters\n• At least 1 letter and 1 number",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 12,
//                     ),
//                   ),

//                   if (_serverError != null) ...[
//                     const SizedBox(height: 12),
//                     Text(
//                       _serverError!,
//                       style: const TextStyle(
//                         color: Colors.redAccent,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],

//                   const SizedBox(height: 24),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _canSubmit ? _register : null,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF9255E8),
//                         padding:
//                             const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: _loading
//                           ? const SizedBox(
//                               height: 22,
//                               width: 22,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2.5,
//                                 color: Colors.white,
//                               ),
//                             )
//                           : const Text(
//                               "Create account",
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const LoginScreen(),
//                         ),
//                       );
//                     },
//                     child: const Text(
//                       "Already have an account? Log in",
//                       style: TextStyle(color: Color(0xFFB38CFF)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _field({
//     required TextEditingController controller,
//     required String label,
//     IconData? icon,
//     bool obscure = false,
//     String? error,
//     required Function(String) onChanged,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       onChanged: onChanged,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF9255E8)),
//         labelText: label,
//         errorText: error,
//         filled: true,
//         fillColor: const Color(0xFF16161F),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//         ),
//       ),
//     );
//   }

//   Widget _background() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: CustomPaint(
//         painter: _HexGridPainter(
//           color: Colors.white.withOpacity(0.05),
//         ),
//       ),
//     );
//   }
// }

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
//           final angle =
//               (60 * i - 30) * math.pi / 180;
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
//   bool shouldRepaint(covariant _HexGridPainter old) =>
//       old.color != color;
// }
// ===============================v2=========================================

// // lib/screens/login/register_screen.dart
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:convert/convert.dart';

// import '../../../state/secure_state.dart';
// import '../../../crypto/master_key_provider.dart';
// import '../../../crypto/master_key_crypto.dart';
// import '../../../infrastructure/storage/jwt_store.dart';
// import '../../../infrastructure/api/master_key_api.dart';
// import 'login_screen.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _emailCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();

//   bool _loading = false;
//   String? _error;

//   Future<void> _register() async {
//     if (_loading) return;

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       final email = _emailCtrl.text.trim();
//       final password = _passwordCtrl.text;

//       // ------------------------------------------------
//       // 1️⃣ Register
//       // ------------------------------------------------
//       final regResp = await http.post(
//         Uri.parse("${SecureState.serverBaseUrl}/api/auth/register/"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": email,
//           "email": email,
//           "password": password,
//         }),
//       );

//       if (regResp.statusCode != 200 &&
//           regResp.statusCode != 201) {
//         throw Exception("Registration failed");
//       }

//       // ------------------------------------------------
//       // 2️⃣ Login
//       // ------------------------------------------------

//       final tokenResp = await http.post(
//         Uri.parse("${SecureState.serverBaseUrl}/api/auth/token/"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": email,
//           "password": password,
//         }),
//       );

//       if (tokenResp.statusCode != 200) {
//         throw Exception("Login after register failed");
//       }

//       final tokenData = jsonDecode(tokenResp.body);
//       final access = tokenData["access"];
//       final refresh = tokenData["refresh"];

//       await JwtStore.instance.saveTokens(access, refresh);
//       SecureState.accessToken = access;
//       SecureState.refreshToken = refresh;

//       // ------------------------------------------------
//       // 3️⃣ Generate master key + salt
//       // ------------------------------------------------
//       final Uint8List masterKey =
//           MasterKeyCrypto.randomBytes(32);

//       final Uint8List salt =
//           MasterKeyCrypto.randomBytes(16);

//       // ------------------------------------------------
//       // 4️⃣ Derive KEK
//       // ------------------------------------------------
//       final Uint8List kek =
//           await MasterKeyProvider.derive(
//         password: password,
//         salt: salt,
//       );

//       // ------------------------------------------------
//       // 5️⃣ Encrypt master key
//       // ------------------------------------------------
//       final encrypted =
//           await MasterKeyCrypto.encrypt(
//         masterKey: masterKey,
//         kek: kek,
//       );
//       // 🔍 DEBUG NONCE
//       print("RAW nonce length: ${encrypted.nonce.length}");
//       print("RAW nonce bytes: ${encrypted.nonce}");
//       print("HEX nonce length: ${hex.encode(encrypted.nonce).length}");
//       print("HEX nonce value: ${hex.encode(encrypted.nonce)}");

//       // ------------------------------------------------
//       // 6️⃣ Send envelope using MasterKeyApi
//       // ------------------------------------------------
//       final masterKeyApi =
//           MasterKeyApi(accessToken: access);

//       await masterKeyApi.setupMasterKey(
//         encMasterKeyHex: encrypted.cipherHex,
//         nonceHex: hex.encode(encrypted.nonce),
//         saltHex: hex.encode(salt),
//         memoryKb: 131072,
//         iterations: 4,
//         parallelism: 2,
//       );

//       // ------------------------------------------------
//       // 7️⃣ Force fresh login
//       // ------------------------------------------------
//       await SecureState.logout();

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Account created securely."),
//         ),
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const LoginScreen(),
//         ),
//       );
//     } catch (e) {
//       setState(() {
//         _error = e.toString().replaceAll("Exception: ", "");
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.person_add,
//                   size: 64, color: Colors.deepPurple),
//               const SizedBox(height: 20),

//               TextField(
//                 controller: _emailCtrl,
//                 decoration:
//                     const InputDecoration(labelText: "Email"),
//               ),
//               const SizedBox(height: 16),

//               TextField(
//                 controller: _passwordCtrl,
//                 obscureText: true,
//                 decoration:
//                     const InputDecoration(labelText: "Password"),
//               ),

//               const SizedBox(height: 20),

//               if (_error != null)
//                 Text(
//                   _error!,
//                   style:
//                       const TextStyle(color: Colors.red),
//                 ),

//               const SizedBox(height: 20),

//               ElevatedButton(
//                 onPressed:
//                     _loading ? null : _register,
//                 child: _loading
//                     ? const CircularProgressIndicator()
//                     : const Text("Create Secure Vault"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




// =================================v3============================================
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';

import '../../../state/secure_state.dart';
import '../../../crypto/master_key_provider.dart';
import '../../../crypto/master_key_crypto.dart';
import '../../../infrastructure/storage/jwt_store.dart';
import '../../../infrastructure/api/master_key_api.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      final regResp = await http.post(
        Uri.parse("${SecureState.serverBaseUrl}/api/auth/register/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": email,
          "email": email,
          "password": password,
        }),
      );

      if (regResp.statusCode != 200 && regResp.statusCode != 201) {
        throw Exception("Registration failed");
      }

      final tokenResp = await http.post(
        Uri.parse("${SecureState.serverBaseUrl}/api/auth/token/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": email,
          "password": password,
        }),
      );

      if (tokenResp.statusCode != 200) {
        throw Exception("Login after register failed");
      }

      final tokenData = jsonDecode(tokenResp.body);
      final access = tokenData["access"];
      final refresh = tokenData["refresh"];

      await JwtStore.instance.saveTokens(access, refresh);
      SecureState.accessToken = access;
      SecureState.refreshToken = refresh;

      final Uint8List masterKey = MasterKeyCrypto.randomBytes(32);
      final Uint8List salt = MasterKeyCrypto.randomBytes(16);

      final Uint8List kek =
          await MasterKeyProvider.derive(password: password, salt: salt);

      final encrypted =
          await MasterKeyCrypto.encrypt(masterKey: masterKey, kek: kek);

      final masterKeyApi = MasterKeyApi(accessToken: access);

      await masterKeyApi.setupMasterKey(
        encMasterKeyHex: encrypted.cipherHex,
        nonceHex: hex.encode(encrypted.nonce),
        saltHex: hex.encode(salt),
        memoryKb: 131072,
        iterations: 4,
        parallelism: 2,
      );

      await SecureState.logout();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Secure vault created successfully.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.person_add_alt_1,
                size: 72,
                color: Color(0xFF7C5CFF),
              ),
              const SizedBox(height: 24),
              const Text(
                "Create Secure Vault",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your master key never leaves your device.",
                style: TextStyle(color: Color(0xFFB8B8C7), fontSize: 14),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Create Vault"),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;

// // import '../../state/secure_state.dart';
// // import '../files/file_list_screen.dart';

// // class LoginScreen extends StatefulWidget {
// //   const LoginScreen({super.key});

// //   @override
// //   State<LoginScreen> createState() => _LoginScreenState();
// // }

// // class _LoginScreenState extends State<LoginScreen> {
// //   final _usernameController = TextEditingController();
// //   final _passwordController = TextEditingController();

// //   bool _isLoading = false;
// //   String? _error;

// //   @override
// //   void dispose() {
// //     _usernameController.dispose();
// //     _passwordController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _login() async {
// //     final username = _usernameController.text.trim();
// //     final password = _passwordController.text;

// //     if (username.isEmpty || password.isEmpty) {
// //       setState(() => _error = "Please enter username & password");
// //       return;
// //     }

// //     setState(() {
// //       _isLoading = true;
// //       _error = null;
// //     });

// //     SecureState.validateServerUrl(); // 🔒 sanity check

// //     try {
// //       final resp = await http.post(
// //         Uri.parse("${SecureState.serverUrl}/api/auth/token/"),
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode({"username": username, "password": password}),
// //       );

// //       if (resp.statusCode == 200) {
// //         final data = jsonDecode(resp.body);
// //         SecureState.accessToken = data["access"];
// //         SecureState.refreshToken = data["refresh"];

// //         if (!mounted) return;
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(builder: (_) => const FileListScreen()),
// //         );
// //       } else {
// //         setState(() => _error = "Invalid credentials");
// //       }
// //     } catch (e) {
// //       setState(() => _error = "Network error: $e");
// //     } finally {
// //       if (mounted) setState(() => _isLoading = false);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);

// //     return Scaffold(
// //       body: Center(
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.all(28),
// //           child: ConstrainedBox(
// //             constraints: const BoxConstraints(maxWidth: 420),
// //             child: Column(
// //               children: [
// //                 Icon(Icons.lock_rounded,
// //                     size: 68, color: theme.colorScheme.primary),
// //                 const SizedBox(height: 12),
// //                 Text(
// //                   "Silvora",
// //                   style: theme.textTheme.headlineMedium!.copyWith(
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 6),
// //                 Text(
// //                   "Secure. Private. Yours.",
// //                   style: theme.textTheme.bodyMedium!
// //                       .copyWith(color: theme.hintColor),
// //                 ),
// //                 const SizedBox(height: 36),

// //                 TextField(
// //                   controller: _usernameController,
// //                   decoration: const InputDecoration(
// //                     labelText: "Username",
// //                     prefixIcon: Icon(Icons.person_outline),
// //                   ),
// //                   enabled: !_isLoading,
// //                 ),
// //                 const SizedBox(height: 14),

// //                 TextField(
// //                   controller: _passwordController,
// //                   decoration: const InputDecoration(
// //                     labelText: "Password",
// //                     prefixIcon: Icon(Icons.lock_outline),
// //                   ),
// //                   obscureText: true,
// //                   enabled: !_isLoading,
// //                 ),
// //                 const SizedBox(height: 20),

// //                 if (_error != null)
// //                   Padding(
// //                     padding: const EdgeInsets.symmetric(vertical: 6),
// //                     child: Text(
// //                       _error!,
// //                       style: const TextStyle(color: Colors.red),
// //                     ),
// //                   ),

// //                 const SizedBox(height: 6),

// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: _isLoading ? null : _login,
// //                     style: ElevatedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 14),
// //                     ),
// //                     child: _isLoading
// //                         ? const SizedBox(
// //                             height: 20,
// //                             width: 20,
// //                             child: CircularProgressIndicator(
// //                               strokeWidth: 2.2,
// //                               color: Colors.white,
// //                             ))
// //                         : const Text("Login"),
// //                   ),
// //                 ),

// //                 const SizedBox(height: 20),

// //                 Text(
// //                   "🔐 End-to-End encrypted cloud storage",
// //                   style: theme.textTheme.bodySmall!
// //                       .copyWith(color: theme.hintColor),
// //                 )
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }




// // =======----------------------------------------------------------============
// import 'dart:convert';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();
//   bool loading = false;
//   String? errorMsg;

//   @override
//   void dispose() {
//     usernameController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     setState(() {
//       loading = true;
//       errorMsg = null;
//     });

//     final server = SecureState.serverUrl;
//     final url = Uri.parse("$server/api/auth/token/");

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": usernameController.text.trim(),
//           "password": passwordController.text,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         final access = data["access"];
//         final refresh = data["refresh"];

//         if (access == null) throw Exception("Missing access token");

//         SecureState.accessToken = access;
//         SecureState.refreshToken = refresh;

//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => FileListScreen(accessToken: access),
//           ),
//         );
//       } else {
//         setState(() =>
//             errorMsg = "Invalid credentials ❌ (code ${response.statusCode})");
//       }
//     } catch (_) {
//       setState(() => errorMsg = "Connection failed — check server URL or VPN");
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Background glow + gradient
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF0D0D12),
//                   Color(0xFF13131A),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),

//           // Floating blurred glass card
//           ClipRRect(
//             borderRadius: BorderRadius.circular(26),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//               child: AnimatedContainer(
//                 width: 340,
//                 duration: const Duration(milliseconds: 350),
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: const Color(0x0DFFFFFF),
//                   borderRadius: BorderRadius.circular(26),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.08),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       blurRadius: 40,
//                       spreadRadius: 0,
//                       offset: const Offset(0, 12),
//                       color: const Color(0xFF9255E8).withOpacity(0.35),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.shield_outlined,
//                       size: 56,
//                       color: Color(0xFF9255E8),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       "Silvora Vault",
//                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 0.8,
//                       ),
//                     ),
//                     const SizedBox(height: 28),

//                     // Username field
//                     TextField(
//                       controller: usernameController,
//                       decoration: const InputDecoration(
//                         labelText: "Username",
//                         prefixIcon: Icon(Icons.person_outline),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Password field
//                     TextField(
//                       controller: passwordController,
//                       obscureText: true,
//                       decoration: const InputDecoration(
//                         labelText: "Password",
//                         prefixIcon: Icon(Icons.lock_outline),
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     if (errorMsg != null)
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: Text(
//                           errorMsg!,
//                           style: const TextStyle(color: Colors.redAccent),
//                         ),
//                       ),

//                     const SizedBox(height: 10),

//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: loading ? null : _login,
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                         ),
//                         child: loading
//                             ? const SizedBox(
//                                 height: 18,
//                                 width: 18,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : const Text(
//                                 "Unlock Vault",
//                                 style: TextStyle(fontWeight: FontWeight.w600),
//                               ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// ************************************************************************************************************


// import 'dart:convert';
// import 'dart:math' as math;
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// // import 'package:silvora_app/crypto/file_decrypt_test.dart';
// import '../../services/vault_service.dart';

// import '../../state/secure_state.dart';
// import '../files/file_list_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool _isLoading = false;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _doLogin() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     final server = SecureState.serverUrl;
//     final url = Uri.parse("$server/api/auth/token/");
//     print("USING SERVER URL: '${SecureState.serverUrl}'");

// // ================================update this later =================================
//   //   try {
//   //     final resp = await http.post(
//   //       url,
//   //       headers: {"Content-Type": "application/json"},
//   //       body: jsonEncode({
//   //         "username": _usernameController.text.trim(),
//   //         "password": _passwordController.text,
//   //       }),
//   //     );

//   //     if (resp.statusCode == 200) {
//   //       final data = jsonDecode(resp.body);
//   //       SecureState.accessToken = data["access"];
//   //       SecureState.refreshToken = data["refresh"];

//   //       if (!mounted) return;
//   //       Navigator.pushReplacement(
//   //         context,
//   //         MaterialPageRoute(
//   //           // builder: (_) => FileListScreen(accessToken: data["access"]),
//   //           builder: (_) => const FileListScreen(),
//   //         ),
//   //       );
//   //     } else {
//   //       setState(() {
//   //         _errorMessage = "Invalid login — try again";
//   //       });
//   //     }
//   //   } catch (e) {
//   //     setState(() {
//   //       _errorMessage = "Connection failed: $e";
//   //     });
//   //   } finally {
//   //     if (mounted) {
//   //       setState(() => _isLoading = false);
//   //     }
//   //   }
//   // }
// // =====================update this later ==========================================


//   final resp = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": _usernameController.text.trim(),
//           "password": _passwordController.text,
//         }),
//       );
//     if (resp.statusCode == 200) {
//       final data = jsonDecode(resp.body);

//       SecureState.accessToken = data["access"];
//       SecureState.refreshToken = data["refresh"];

//       // 🔐 UNLOCK VAULT (MANDATORY)
//       await VaultService.unlockWithPassword(
//         _passwordController.text,
//       );

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const FileListScreen(),
//         ),
//       );
//     }





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
//           // Background
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           Positioned.fill(
//             child: IgnorePointer(
//               child: CustomPaint(
//                 painter: _HexGridPainter(
//                   color: Colors.white.withOpacity(0.05),
//                 ),
//               ),
//             ),
//           ),

//           // Form Centered
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.lock_outline_rounded,
//                       color: const Color(0xFF9255E8), size: 68),
//                   const SizedBox(height: 12),
//                   const Text(
//                     "Silvora Vault",
//                     style: TextStyle(
//                       color: Color(0xFFE7D8FF),
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   _buildTextField(
//                     controller: _usernameController,
//                     label: "Username",
//                     icon: Icons.person,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     controller: _passwordController,
//                     label: "Password",
//                     obscure: true,
//                     icon: Icons.lock,
//                   ),

//                   const SizedBox(height: 24),
//                   if (_errorMessage != null)
//                     Text(
//                       _errorMessage!,
//                       style:
//                           const TextStyle(color: Colors.redAccent, fontSize: 13),
//                     ),
//                   const SizedBox(height: 12),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _doLogin,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF9255E8),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 8,
//                         shadowColor:
//                             const Color(0xFF9255E8).withOpacity(0.5),
//                       ),
//                       child: _isLoading
//                           ? const CircularProgressIndicator(
//                               color: Colors.white, strokeWidth: 2.5)
//                           : const Text(
//                               "Login",
//                               style: TextStyle(
//                                   fontSize: 17, fontWeight: FontWeight.w600),
//                             ),
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

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     IconData? icon,
//     bool obscure = false,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF9255E8)),
//         labelText: label,
//         labelStyle: const TextStyle(color: Color(0xFFB38CFF)),
//         filled: true,
//         fillColor: const Color(0xFF16161F),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Color(0xFF9255E8), width: 1.4),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(
//             color: Colors.white.withOpacity(0.20),
//             width: 1.2,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Cyber hex-grid painter reused from file list screen
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
//           final angleRad = (60 * i - 30) * math.pi / 180;
//           final px = center.dx + r * math.cos(angleRad);
//           final py = center.dy + r * math.sin(angleRad);
//           if (i == 0) path.moveTo(px, py);
//           else path.lineTo(px, py);
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
// ================================================================


// lib/screens/login/login_screen.dart

// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import '../../state/secure_state.dart';
// import '../../services/vault_service.dart';
// import '../files/file_list_screen.dart';
// import 'register_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool _isLoading = false;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _doLogin() async {
//     if (_isLoading) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     final url = Uri.parse(
//       "${SecureState.serverUrl}/api/auth/token/",
//     );

//     try {
//       final resp = await http.post(
//         url,
//         headers: const {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": _usernameController.text.trim(),
//           "password": _passwordController.text,
//         }),
//       );

//       if (resp.statusCode != 200) {
//         setState(() {
//           _errorMessage = "Invalid username or password";
//         });
//         return;
//       }

//       final data = jsonDecode(resp.body);

//       // ----------------------------
//       // 1️⃣ Store tokens
//       // ----------------------------
//       SecureState.accessToken = data["access"];
//       SecureState.refreshToken = data["refresh"];

//       // ----------------------------
//       // 2️⃣ Unlock vault (MANDATORY)
//       // ----------------------------
//       await VaultService.unlockWithPassword(
//         _passwordController.text,
//       );

//       // ----------------------------
//       // 3️⃣ Navigate
//       // ----------------------------
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const FileListScreen(),
//         ),
//       );
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Login failed: $e";
//       });
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

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
//           // Background
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),

//           Positioned.fill(
//             child: IgnorePointer(
//               child: CustomPaint(
//                 painter: _HexGridPainter(
//                   color: Colors.white.withOpacity(0.05),
//                 ),
//               ),
//             ),
//           ),

//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(
//                     Icons.lock_outline_rounded,
//                     color: Color(0xFF9255E8),
//                     size: 68,
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     "Silvora Vault",
//                     style: TextStyle(
//                       color: Color(0xFFE7D8FF),
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   _buildTextField(
//                     controller: _usernameController,
//                     label: "Username",
//                     icon: Icons.person,
//                   ),
//                   const SizedBox(height: 16),

//                   _buildTextField(
//                     controller: _passwordController,
//                     label: "Password",
//                     obscure: true,
//                     icon: Icons.lock,
//                   ),

//                   const SizedBox(height: 24),

//                   if (_errorMessage != null)
//                     Text(
//                       _errorMessage!,
//                       style: const TextStyle(
//                         color: Colors.redAccent,
//                         fontSize: 13,
//                       ),
//                     ),

//                   const SizedBox(height: 12),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _doLogin,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF9255E8),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 8,
//                         shadowColor:
//                             const Color(0xFF9255E8).withOpacity(0.5),
//                       ),
//                       child: _isLoading
//                           ? const CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2.5,
//                             )
//                           : const Text(
//                               "Login",
//                               style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
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

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     IconData? icon,
//     bool obscure = false,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF9255E8)),
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
//             color: Colors.white.withOpacity(0.20),
//             width: 1.2,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Cyber hex-grid painter
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
//           final angleRad = (60 * i - 30) * math.pi / 180;
//           final px = center.dx + r * math.cos(angleRad);
//           final py = center.dy + r * math.sin(angleRad);
//           if (i == 0) {
//             path.moveTo(px, py);
//           } else {
//             path.lineTo(px, py);
//           }
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
// //===================================================================================
// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import '../../state/secure_state.dart';
// import '../../services/vault_service.dart';
// // import '../files/file_list_screen.dart';
// import 'register_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
  
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool _isLoading = false;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // LOGIN LOGIC
//   // ─────────────────────────────────────────────

//   Future<void> _doLogin() async {
//     if (_isLoading) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       debugPrint("🌐 LOGIN URL = ${SecureState.serverUrl}/api/auth/token/");
//       final resp = await http.post(
//         Uri.parse("${SecureState.serverUrl}/api/auth/token/"),
//         headers: const {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": _usernameController.text.trim(),
//           "password": _passwordController.text,
//         }),
//       );

//       if (resp.statusCode != 200) {
//         setState(() {
//           _errorMessage = "Invalid username or password";
//         });
//         return;
//       }

//       final data = jsonDecode(resp.body);

//       // 1️⃣ Store JWTs
//       SecureState.accessToken = data["access"];
//       SecureState.refreshToken = data["refresh"];

//       // 2️⃣ Unlock vault (ZERO-KNOWLEDGE STEP)
//       await VaultService.unlockWithPassword(
//         _passwordController.text,
//       );

//       // 3️⃣ Navigate
//       if (!mounted) return;
//       Navigator.pushReplacementNamed(
//         context,
//         '/files'  //edited,revert back if this does not works 
//         );
//     } catch (e,st) {
//       debugPrint("❌ LOGIN ERROR: $e\n$st");
//       setState(() {
//         _errorMessage = e.toString();
//       });
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
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
//           // ───── Background ─────
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),

//           // ───── Hex Grid ─────
//           Positioned.fill(
//             child: IgnorePointer(
//               child: CustomPaint(
//                 painter: _HexGridPainter(
//                   color: Colors.white.withOpacity(0.05),
//                 ),
//               ),
//             ),
//           ),

//           // ───── Login Card ─────
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(
//                     Icons.lock_outline_rounded,
//                     color: Color(0xFF9255E8),
//                     size: 68,
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     "Silvora Vault",
//                     style: TextStyle(
//                       color: Color(0xFFE7D8FF),
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   _buildTextField(
//                     controller: _usernameController,
//                     label: "Email",
//                     icon: Icons.person,
//                   ),
//                   const SizedBox(height: 16),

//                   _buildTextField(
//                     controller: _passwordController,
//                     label: "Password",
//                     obscure: true,
//                     icon: Icons.lock,
//                   ),

//                   const SizedBox(height: 24),

//                   if (_errorMessage != null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 12),
//                       child: Text(
//                         _errorMessage!,
//                         style: const TextStyle(
//                           color: Colors.redAccent,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _doLogin,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF9255E8),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 8,
//                         shadowColor:
//                             const Color(0xFF9255E8).withOpacity(0.5),
//                       ),
//                       child: _isLoading
//                           ? const SizedBox(
//                               height: 22,
//                               width: 22,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2.5,
//                               ),
//                             )
//                           : const Text(
//                               "Login",
//                               style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                     ),
//                   ),

//                   const SizedBox(height: 18),

//                   // ───── Register Link ─────
//                   TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const RegisterScreen(),
//                         ),
//                       );
//                     },
//                     child: const Text(
//                       "Create a new account",
//                       style: TextStyle(
//                         color: Color(0xFFB38CFF),
//                         fontSize: 14,
//                       ),
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

//   // ─────────────────────────────────────────────
//   // INPUT FIELD
//   // ─────────────────────────────────────────────

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     IconData? icon,
//     bool obscure = false,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: const Color(0xFF9255E8)),
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
//             color: Colors.white.withOpacity(0.20),
//             width: 1.2,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// ─────────────────────────────────────────────
// /// Cyber hex-grid painter
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
//           final angleRad = (60 * i - 30) * math.pi / 180;
//           final px = center.dx + r * math.cos(angleRad);
//           final py = center.dy + r * math.sin(angleRad);
//           if (i == 0) {
//             path.moveTo(px, py);
//           } else {
//             path.lineTo(px, py);
//           }
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
// //===========================================================================
// lib/screens/login/login_screen.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:silvora_app/widgets/brand_logo.dart';

import '../../services/vault_service.dart';
import '../../state/secure_state.dart';
import 'register_screen.dart';
import '../../storage/jwt_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LOGIN LOGIC
  // ─────────────────────────────────────────────

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
//     final resp = await http.post(
//       Uri.parse("${SecureState.serverUrl}/api/auth/token/"),
//       headers: const {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "username": email,
//         "password": password,
//       }),
//     );

//     if (resp.statusCode != 200) {
//       setState(() {
//         _errorMessage = "Incorrect email or password.";
//       });
//       return;
//     }

//     final data = jsonDecode(resp.body);
//     final access = data["access"];
//     final refresh = data["refresh"];

//     // ✅ SAVE TOKENS
//     await JwtStore().saveTokens(access, refresh);

//     // ✅ LOAD INTO MEMORY
//     SecureState.accessToken = access;
//     SecureState.refreshToken = refresh;

//     // 🔐 Unlock vault
//     // await VaultService.unlockWithPassword(password);

//     if (!mounted) return;
//     Navigator.pushReplacementNamed(context, '/files');
//   } catch (_) {
//     setState(() {
//       _errorMessage = "Unable to connect. Check your internet.";
//     });
//   } finally {
//     if (mounted) setState(() => _isLoading = false);
//   }
// }
  Future<void> _doLogin() async {
  if (_isLoading) return;

  final email = _emailController.text.trim().toLowerCase();
  final password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    setState(() {
      _errorMessage = "Please enter both email and password.";
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final resp = await http.post(
      Uri.parse("${SecureState.serverUrl}/api/auth/token/"),
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": email,
        "password": password,
      }),
    );

    if (resp.statusCode != 200) {
      setState(() {
        _errorMessage = "Incorrect email or password.";
      });
      return;
    }

    final data = jsonDecode(resp.body);
    final access = data["access"];
    final refresh = data["refresh"];

    // ✅ Save tokens
    await JwtStore().saveTokens(access, refresh);

    SecureState.accessToken = access;
    SecureState.refreshToken = refresh;

    // 🔐 THIS WAS MISSING
    await VaultService.unlockWithPassword(password);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/files');
  } catch (_) {
    setState(() {
      _errorMessage = "Unable to connect. Check your internet.";
    });
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}



  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackground(),
          _buildHexGrid(),
          _buildLoginCard(context),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF9255E8),
              size: 68,
            ),
            const SizedBox(height: 12),
            const SilvoraLogo(fontSize: 28),
            const SizedBox(height: 6),
            const Text(
              "Zero-knowledge encrypted storage",
              style: TextStyle(
                color: Color(0xFFB38CFF),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),

            _buildTextField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _passwordController,
              label: "Password",
              icon: Icons.lock_outline,
              obscure: !_showPassword,
              suffix: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              "Your password never leaves your device",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _doLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9255E8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Unlock Vault",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(
                "Create a new account",
                style: TextStyle(
                  color: Color(0xFFB38CFF),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildHexGrid() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _HexGridPainter(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF9255E8)),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB38CFF)),
        filled: true,
        fillColor: const Color(0xFF16161F),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF9255E8),
            width: 1.4,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Hex grid background
/// ─────────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final Color color;

  _HexGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const double r = 16;
    final double h = 2 * r;
    final double vert = 0.75 * h;
    final double horiz = r * math.sqrt(3);

    for (double y = -h; y < size.height + h; y += vert) {
      final bool offsetRow = ((y / vert).round() % 2) == 1;
      for (double x = offsetRow ? -horiz / 2 : 0;
          x < size.width + horiz;
          x += horiz) {
        final center = Offset(x, y);
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (60 * i - 30) * math.pi / 180;
          final px = center.dx + r * math.cos(angle);
          final py = center.dy + r * math.sin(angle);
          i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

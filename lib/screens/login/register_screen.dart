// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import '../../state/secure_state.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _username = TextEditingController();
//   final _password = TextEditingController();

//   bool _loading = false;
//   String? _error;

//   Future<void> _register() async {
//     if (_loading) return;

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       final res = await http.post(
//         Uri.parse("${SecureState.serverUrl}/api/auth/register/"),
//         headers: const {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": _username.text.trim(),
//           "password": _password.text,
//         }),
//       );

//       if (res.statusCode != 201 && res.statusCode != 200) {
//         throw Exception("Registration failed");
//       }

//       if (!mounted) return;
//       Navigator.pop(context); // back to login
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Create Account")),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             TextField(
//               controller: _username,
//               decoration: const InputDecoration(
//                 labelText: "Username",
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _password,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: "Password",
//               ),
//             ),
//             const SizedBox(height: 24),
//             if (_error != null)
//               Text(_error!, style: const TextStyle(color: Colors.red)),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _loading ? null : _register,
//                 child: _loading
//                     ? const CircularProgressIndicator()
//                     : const Text("Register"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// // ============================================================


// // lib/screens/login/register_screen.dart

// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;


// import '../../state/secure_state.dart';
// import 'login_screen.dart' show LoginScreen;


// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _usernameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();

//   bool _loading = false;
//   String? _error;

//   @override
//   void dispose() {
//     _usernameCtrl.dispose();
//     _emailCtrl.dispose();
//     _passwordCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _register() async {
//     if (_loading) return;

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       debugPrint("🌐 REGISTER URL = ${SecureState.serverUrl}/api/auth/register/");
//       final res = await http.post(
//         Uri.parse("${SecureState.serverUrl}/api/auth/register/"),
//         headers: const {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": _usernameCtrl.text.trim(),
//           "email": _emailCtrl.text.trim(),
//           "password": _passwordCtrl.text,
//         }),
//       );

//       if (res.statusCode != 201 && res.statusCode != 200) {
//         setState(() {
//           _error = "Registration failed,${res.statusCode}: ${res.body}";
//         });
//         return;
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Account created. Please login."),
//         ),
//       );

//       Navigator.pushReplacementNamed(context,'/files ');
//     } catch (e) {
//       setState(() {
//         _error = "Error: $e";
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
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
//           // Gradient background
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
//                     Icons.person_add_alt_1,
//                     color: Color(0xFF9255E8),
//                     size: 68,
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     "Create Silvora Account",
//                     style: TextStyle(
//                       color: Color(0xFFE7D8FF),
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   _field(
//                     controller: _usernameCtrl,
//                     label: "Username",
//                     icon: Icons.person,
//                   ),
//                   const SizedBox(height: 14),

//                   _field(
//                     controller: _emailCtrl,
//                     label: "Email",
//                     icon: Icons.email,
//                   ),
//                   const SizedBox(height: 14),

//                   _field(
//                     controller: _passwordCtrl,
//                     label: "Password",
//                     icon: Icons.lock,
//                     obscure: true,
//                   ),
//                   const SizedBox(height: 24),

//                   if (_error != null)
//                     Text(
//                       _error!,
//                       style: const TextStyle(
//                         color: Colors.redAccent,
//                         fontSize: 13,
//                       ),
//                     ),

//                   const SizedBox(height: 12),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _loading ? null : _register,
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
//                       child: _loading
//                           ? const CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2.5,
//                             )
//                           : const Text(
//                               "Register",
//                               style: TextStyle(
//                                 fontSize: 17,
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
//                       "Already have an account? Login",
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

// /// Same hex grid as login (brand consistency)
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
//   bool shouldRepaint(covariant _HexGridPainter old) =>
//       old.color != color;
// }
// // ========================================================================


// lib/screens/login/register_screen.dart

// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;


// import '../../state/secure_state.dart';
// import 'login_screen.dart' show LoginScreen;


// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _usernameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();

//   bool _loading = false;
//   String? _error;

//   @override
//   void dispose() {
//     _usernameCtrl.dispose();
//     _emailCtrl.dispose();
//     _passwordCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _register() async {
//     if (_loading) return;

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       debugPrint("🌐 REGISTER URL = ${SecureState.serverUrl}/api/auth/register/");
//       final res = await http.post(
//         Uri.parse("${SecureState.serverUrl}/api/auth/register/"),
//         headers: const {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": _usernameCtrl.text.trim(),
//           "email": _emailCtrl.text.trim(),
//           "password": _passwordCtrl.text,
//         }),
//       );

//       if (res.statusCode != 201 && res.statusCode != 200) {
//         setState(() {
//           _error = "Registration failed,${res.statusCode}: ${res.body}";
//         });
//         return;
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Account created. Please login."),
//         ),
//       );

//       Navigator.pushReplacementNamed(context,'/files ');
//     } catch (e) {
//       setState(() {
//         _error = "Error: $e";
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
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
//           // Gradient background
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
//                     Icons.person_add_alt_1,
//                     color: Color(0xFF9255E8),
//                     size: 68,
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     "Create Silvora Account",
//                     style: TextStyle(
//                       color: Color(0xFFE7D8FF),
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   _field(
//                     controller: _usernameCtrl,
//                     label: "Username",
//                     icon: Icons.person,
//                   ),
//                   const SizedBox(height: 14),

//                   _field(
//                     controller: _emailCtrl,
//                     label: "Email",
//                     icon: Icons.email,
//                   ),
//                   const SizedBox(height: 14),

//                   _field(
//                     controller: _passwordCtrl,
//                     label: "Password",
//                     icon: Icons.lock,
//                     obscure: true,
//                   ),
//                   const SizedBox(height: 24),

//                   if (_error != null)
//                     Text(
//                       _error!,
//                       style: const TextStyle(
//                         color: Colors.redAccent,
//                         fontSize: 13,
//                       ),
//                     ),

//                   const SizedBox(height: 12),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _loading ? null : _register,
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
//                       child: _loading
//                           ? const CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2.5,
//                             )
//                           : const Text(
//                               "Register",
//                               style: TextStyle(
//                                 fontSize: 17,
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
//                       "Already have an account? Login",
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

// /// Same hex grid as login (brand consistency)
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
//   bool shouldRepaint(covariant _HexGridPainter old) =>
//       old.color != color;
// }
// ========================================================================

// lib/screens/login/register_screen.dart

// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;


// import '../../state/secure_state.dart';
// import 'login_screen.dart' show LoginScreen;


// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _usernameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();

//   bool _loading = false;
//   String? _error;

//   @override
//   void dispose() {
//     _usernameCtrl.dispose();
//     _emailCtrl.dispose();
//     _passwordCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _register() async {
//     if (_loading) return;

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       debugPrint("🌐 REGISTER URL = ${SecureState.serverUrl}/api/auth/register/");
//       final res = await http.post(
//         Uri.parse("${SecureState.serverUrl}/api/auth/register/"),
//         headers: const {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "username": _usernameCtrl.text.trim(),
//           "email": _emailCtrl.text.trim(),
//           "password": _passwordCtrl.text,
//         }),
//       );

//       if (res.statusCode != 201 && res.statusCode != 200) {
//         setState(() {
//           _error = "Registration failed,${res.statusCode}: ${res.body}";
//         });
//         return;
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Account created. Please login."),
//         ),
//       );

//       Navigator.pushReplacementNamed(context,'/files');
//     } catch (e) {
//       setState(() {
//         _error = "Error: $e";
//       });
//     } finally {
//       if (mounted) setState(() => _loading = false);
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
//           // Gradient background
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
//                     Icons.person_add_alt_1,
//                     color: Color(0xFF9255E8),
//                     size: 68,
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     "Create Silvora Account",
//                     style: TextStyle(
//                       color: Color(0xFFE7D8FF),
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   _field(
//                     controller: _usernameCtrl,
//                     label: "Username",
//                     icon: Icons.person,
//                   ),
//                   const SizedBox(height: 14),

//                   _field(
//                     controller: _emailCtrl,
//                     label: "Email",
//                     icon: Icons.email,
//                   ),
//                   const SizedBox(height: 14),

//                   _field(
//                     controller: _passwordCtrl,
//                     label: "Password",
//                     icon: Icons.lock,
//                     obscure: true,
//                   ),
//                   const SizedBox(height: 24),

//                   if (_error != null)
//                     Text(
//                       _error!,
//                       style: const TextStyle(
//                         color: Colors.redAccent,
//                         fontSize: 13,
//                       ),
//                     ),

//                   const SizedBox(height: 12),

//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _loading ? null : _register,
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
//                       child: _loading
//                           ? const CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2.5,
//                             )
//                           : const Text(
//                               "Register",
//                               style: TextStyle(
//                                 fontSize: 17,
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
//                       "Already have an account? Login",
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

// /// Same hex grid as login (brand consistency)
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
//   bool shouldRepaint(covariant _HexGridPainter old) =>
//       old.color != color;
// }
// // ========================================================================
// lib/screens/login/register_screen.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../state/secure_state.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _serverError;

  bool _loading = false;

  // ─────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final hasLetter = RegExp(r"[A-Za-z]").hasMatch(password);
    final hasNumber = RegExp(r"\d").hasMatch(password);
    return password.length >= 8 && hasLetter && hasNumber;
  }

  bool get _canSubmit =>
      _emailError == null &&
      _passwordError == null &&
      _emailCtrl.text.isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      !_loading;

  void _validateEmail(String value) {
    if (value.isEmpty) {
      _emailError = "Email is required";
    } else if (!_isValidEmail(value)) {
      _emailError = "Enter a valid email address";
    } else {
      _emailError = null;
    }
    setState(() {});
  }

  void _validatePassword(String value) {
    if (value.isEmpty) {
      _passwordError = "Password is required";
    } else if (!_isValidPassword(value)) {
      _passwordError =
          "Min 8 chars, at least 1 letter and 1 number";
    } else {
      _passwordError = null;
    }
    setState(() {});
  }

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────

  Future<void> _register() async {
    if (!_canSubmit) return;

    setState(() {
      _loading = true;
      _serverError = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      final res = await http.post(
        Uri.parse("${SecureState.serverUrl}/api/auth/register/"),
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode({
          // username intentionally set = email
          "username": email,
          "email": email,
          "password": password,
        }),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        final body = res.body.toLowerCase();
        if (body.contains("email")) {
          _serverError = "Email already registered";
        } else {
          _serverError = "Registration failed";
        }
        setState(() {});
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created. Please log in."),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      setState(() {
        _serverError = "Network error. Try again.";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
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
          _background(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    color: Color(0xFF9255E8),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Create your Silvora vault",
                    style: TextStyle(
                      color: Color(0xFFE7D8FF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _field(
                    controller: _emailCtrl,
                    label: "Email",
                    icon: Icons.email,
                    error: _emailError,
                    onChanged: _validateEmail,
                  ),
                  const SizedBox(height: 14),

                  _field(
                    controller: _passwordCtrl,
                    label: "Password",
                    icon: Icons.lock,
                    obscure: true,
                    error: _passwordError,
                    onChanged: _validatePassword,
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    "• Minimum 8 characters\n• At least 1 letter and 1 number",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),

                  if (_serverError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _serverError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _register : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9255E8),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Create account",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Already have an account? Log in",
                      style: TextStyle(color: Color(0xFFB38CFF)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    String? error,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF9255E8)),
        labelText: label,
        errorText: error,
        filled: true,
        fillColor: const Color(0xFF16161F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D12), Color(0xFF13131A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _HexGridPainter(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
    );
  }
}

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
          final angle =
              (60 * i - 30) * math.pi / 180;
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
  bool shouldRepaint(covariant _HexGridPainter old) =>
      old.color != color;
}

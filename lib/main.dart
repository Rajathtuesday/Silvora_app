
// ================================================================================
// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/files/file_list_screen.dart';
import 'screens/app_entry/app_entry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilvoraApp());
}

class SilvoraApp extends StatelessWidget {
  const SilvoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),

      /// 🔑 AppEntry is now the real startup brain
      home: const AppEntry(),

      /// Named routes stay exactly as they are
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/files': (_) => const FileListScreen(),
      },
    );
  }
}

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:silvora_app/state/secure_state.dart';
import 'theme/app_theme.dart';

import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/login/register_screen.dart';
import 'presentation/screens/files/file_list_screen.dart';
import 'presentation/screens/app_entry/app_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureState.restoreSession();
  runApp(const SilvoraApp());
}

class SilvoraApp extends StatelessWidget {
  const SilvoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AppEntry(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/files': (_) => const FileListScreen(),
      },
    );
  }
}
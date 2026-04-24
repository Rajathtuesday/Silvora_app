import 'package:flutter/material.dart';
import 'package:silvora_app/screens/login/login_screen.dart';
import 'package:silvora_app/theme/silvora_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilvoraApp());
}

class SilvoraApp extends StatelessWidget {
  const SilvoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silvora Base',
      debugShowCheckedModeBanner: false,
      theme: SilvoraTheme.dark(),
      home: const LoginScreen(),
    );
  }
}

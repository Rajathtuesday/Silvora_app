// lib/presentation/screens/app_entry/app_entry.dart
import 'package:flutter/material.dart';
import '../../../state/secure_state.dart';
import '../login/login_screen.dart';
import '../files/file_list_screen.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_route);
  }

  void _route() {
    Widget target =
        SecureState.accessToken == null
            ? const LoginScreen()
            : const FileListScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: AnimatedOpacity(
            opacity: 1,
            duration: Duration(milliseconds: 600),
            child: CircularProgressIndicator(),
          ),
        ),
      );
  }
}
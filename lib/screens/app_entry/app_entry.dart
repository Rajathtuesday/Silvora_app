
//========================================================================================
// lib/screens/app_entry/app_entry.dart
import 'package:flutter/material.dart';

import '../../state/secure_state.dart';
import '../../state/upload_retry_state.dart';
import '../login/login_screen.dart';
import '../upload/upload_screen.dart';
import '../files/file_list_screen.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeOnce();
    });
  }

  Future<void> _routeOnce() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    Widget target;

    // 1️⃣ Not logged in
    if (SecureState.accessToken == null) {
      target = const LoginScreen();
    }
    // 2️⃣ Has pending upload (resume screen decides what to do)
    else if (await UploadRetryStore.hasPendingUpload()) {
      target = const UploadScreen();
    }
    // 3️⃣ Normal entry
    else {
      target = const FileListScreen();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

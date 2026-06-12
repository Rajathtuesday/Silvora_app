import 'package:flutter/material.dart';
import 'package:silvora_app/screens/auth_gate.dart';
import 'package:silvora_app/services/vault_service.dart';
import 'package:silvora_app/state/secure_state.dart';
import 'package:silvora_app/theme/silvora_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilvoraApp());
}

class SilvoraApp extends StatefulWidget {
  const SilvoraApp({super.key});

  @override
  State<SilvoraApp> createState() => _SilvoraAppState();
}

class _SilvoraAppState extends State<SilvoraApp> with WidgetsBindingObserver {
  // Auto-lock: if the app stays backgrounded longer than this, the in-memory
  // master key is wiped and the user must re-enter their password. Protects an
  // unlocked vault on a lost or borrowed phone.
  static const Duration _autoLockAfter = Duration(minutes: 2);

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since == null) return;

      final away = DateTime.now().difference(since);
      if (SecureState.isUnlocked && away >= _autoLockAfter) {
        VaultService.lock();
        _navKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silvora',
      navigatorKey: _navKey,
      debugShowCheckedModeBanner: false,
      theme: SilvoraTheme.dark(),
      home: const AuthGate(),
    );
  }
}

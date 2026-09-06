import 'package:flutter/material.dart';
import 'package:silvora_app/screens/auth_gate.dart';
import 'package:silvora_app/screens/device_security_gate.dart';
import 'package:silvora_app/services/vault_service.dart';
import 'package:silvora_app/state/secure_state.dart';
import 'package:silvora_app/theme/silvora_theme.dart';
import 'package:silvora_app/utils/auto_lock_timer.dart';

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
  // Auto-lock: if the app stays backgrounded (or the screen is off) longer than
  // this, the in-memory master key is wiped and the user must re-enter their
  // password. Protects an unlocked vault on a lost or borrowed phone. The short
  // grace tolerates brief app-switches (file picker, share sheet) without
  // locking mid-flow.
  static const Duration _autoLockAfter = Duration(minutes: 1);

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  // Monotonic (not wall-clock) timer -- see auto_lock_timer.dart for why:
  // a plain DateTime.now() comparison can be defeated by winding the
  // device's system clock backward while the phone sits unlocked and
  // backgrounded.
  final AutoLockTimer _autoLockTimer = AutoLockTimer();

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
      _autoLockTimer.markBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      // Always evaluate (and let it reset its internal clock) regardless of
      // whether the vault is currently unlocked, so a stale running timer
      // never carries over into the next background/resume cycle.
      final wasAwayTooLong = _autoLockTimer.shouldLockOnResume(_autoLockAfter);
      if (SecureState.isUnlocked && wasAwayTooLong) {
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
      home: const DeviceSecurityGate(),
    );
  }
}

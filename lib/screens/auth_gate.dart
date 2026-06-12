import 'package:flutter/material.dart';

import '../state/secure_state.dart';
import '../storage/jwt_store.dart';
import 'login/login_screen.dart';
import 'login/unlock_screen.dart';
import '../theme/silvora_theme.dart';

/// Decides where the app lands on startup:
/// - no saved session  -> Login
/// - saved session      -> Unlock (vault still needs the password locally)
///
/// The master key is never persisted, so even with a restored session the
/// user re-enters the password to unlock. This keeps the zero-knowledge
/// guarantee while skipping the full re-authentication round trip.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final store = JwtStore();
    final access = await store.getAccessToken();
    final refresh = await store.getRefreshToken();

    if (!mounted) return;

    if (refresh == null || refresh.isEmpty) {
      _go(const LoginScreen());
      return;
    }

    // Restore the session into memory; the vault still needs the password.
    SecureState.accessToken = access;
    SecureState.refreshToken = refresh;
    _go(const UnlockScreen());
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: SilvoraColors.gold),
            SizedBox(height: 24),
            CircularProgressIndicator(color: SilvoraColors.gold),
          ],
        ),
      ),
    );
  }
}

// lib/screens/device_security_gate.dart
import 'package:flutter/material.dart';

import '../services/device_security_service.dart';
import '../theme/silvora_theme.dart';
import 'auth_gate.dart';

/// Runs before anything else in the app -- AuthGate (and therefore the
/// vault) is never reached at all if the device fails this check. Blocks
/// outright rather than just warning, since a rooted device or one with
/// USB debugging enabled meaningfully weakens the guarantees an
/// end-to-end-encrypted vault is supposed to provide (a compromised OS or
/// an attached debugger can potentially read process memory directly,
/// bypassing the encryption entirely regardless of how correct the crypto
/// code itself is).
class DeviceSecurityGate extends StatefulWidget {
  const DeviceSecurityGate({super.key});

  @override
  State<DeviceSecurityGate> createState() => _DeviceSecurityGateState();
}

class _DeviceSecurityGateState extends State<DeviceSecurityGate> {
  DeviceSecurityStatus? _status;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() => _checking = true);
    final status = await DeviceSecurityService.check();
    if (!mounted) return;
    setState(() {
      _status = status;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: SilvoraColors.primary)),
      );
    }

    final status = _status!;
    if (!status.isCompromised) {
      return const AuthGate();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_outlined, size: 72, color: SilvoraColors.error),
                const SizedBox(height: 24),
                Text(
                  status.isRooted ? "Unsupported device" : "Developer mode is on",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: SilvoraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  status.isRooted
                      ? "This device appears to be rooted or running modified system "
                          "software. That can let other apps or processes read memory "
                          "Silvora relies on staying private, which undermines the "
                          "encryption guarantees this app is built on -- so Silvora "
                          "won't open here."
                      : "Developer Options and/or USB debugging are turned on. These "
                          "make it possible for a connected computer or another app to "
                          "inspect what's running on this device, which isn't safe for "
                          "an encrypted vault. Turn them off in Settings, then try again.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SilvoraColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                if (!status.isRooted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _runCheck,
                      child: const Text("I've turned it off — check again"),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

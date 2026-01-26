// import 'package:flutter/widgets.dart';
// import '../state/secure_state.dart';

// class AppLifecycleGuard with WidgetsBindingObserver {
//   static final AppLifecycleGuard _instance = AppLifecycleGuard._internal();
//   factory AppLifecycleGuard() => _instance;
//   AppLifecycleGuard._internal();

//   void init() {
//     WidgetsBinding.instance.addObserver(this);
//   }

//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.detached) {
//       _lockVault();
//     }
//   }

//   void _lockVault() {
//     SecureState.lockVault();
//     SecureState.accessToken = null;
//     SecureState.refreshToken = null;
//   }
// }

// lib/core/app_lifecycle_guard.dart
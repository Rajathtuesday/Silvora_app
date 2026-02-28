// // lib/services/device_service.dart
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

// class DeviceService {
//   static Future<String> getDeviceId() async {
//     final deviceInfo = DeviceInfoPlugin();

//     String raw;
//     if (kIsWeb) {
//       final webInfo = await deviceInfo.webBrowserInfo;
//       raw = '${webInfo.userAgent}-${webInfo.vendor}-${webInfo.hardwareConcurrency}';
//     } else {
//       final androidInfo = await deviceInfo.androidInfo;
//       raw = '${androidInfo.id}-${androidInfo.model}-${androidInfo.manufacturer}';
//     }

//     final bytes = utf8.encode(raw);
//     final hash = sha256.convert(bytes).toString();
//     return hash; // this is what server sees
//   }

//   static Future<String> getDeviceLabel() async {
//     // This is only for YOU in UI (can be plaintext on client)
//     // You can customize this more nicely, e.g., "Rajath's Redmi"
//     return 'Device-${DateTime.now().year}';
//   }
// }

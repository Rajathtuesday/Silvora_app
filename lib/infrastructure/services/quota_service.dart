// // lib/services/quota_service.dart
// // lib/services/quota_service.dart
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;

// // import '../state/secure_state.dart';

// // class QuotaService {
// //   static Future<(dynamic, dynamic)> fetchQuota() async {
// //     final resp = await http.get(
// //       Uri.parse("${SecureState.serverUrl}/upload/quota/"),
// //       headers: SecureState.authHeader(),
// //     );

// //     if (resp.statusCode != 200) {
// //       throw Exception("Failed to fetch quota");
// //     }

// //     final data = jsonDecode(resp.body);
// //     return (data["used_bytes"], data["limit_bytes"]);
// //   }
// // }

// // lib/services/quota_service.dart
// import 'dart:convert';

// import 'package:http/http.dart' as http;

// import '../state/secure_state.dart';

// class QuotaService {
//   static Future<({int used, int limit})> fetchQuota() async {
//     final url = "${SecureState.serverBaseUrl}/upload/quota/";

//     print("📡 [QUOTA] Requesting → $url");
//     print("🔐 [QUOTA] Token present: ${SecureState.accessToken != null}");

//     final res = await http.get(
//       Uri.parse(url),
//       headers: SecureState.authHeader(),
//     );

//     print("📥 [QUOTA] Status: ${res.statusCode}");
//     print("📦 [QUOTA] Raw body: ${res.body}");

//     if (res.statusCode != 200) {
//       throw Exception("Quota fetch failed (${res.statusCode})");
//     }

//     final data = jsonDecode(res.body);

//     print("🧮 [QUOTA] Parsed JSON: $data");

//     return (
//       used: (data['used_bytes'] as num).toInt(),
//       limit: (data['limit_bytes'] as num).toInt(),
//     );
//   }
// }
// ========================v2===========================
// // lib/services/quota_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../state/secure_state.dart';

// class QuotaService {
//   static Future<Map<String, dynamic>?> fetchQuota() async {
//     if (!SecureState.isAuthenticated) {
//       return null;
//     }

//     final url =
//         "${SecureState.serverBaseUrl}/upload/quota/";

//     try {
//       final resp = await http.get(
//         Uri.parse(url),
//         headers: SecureState.authHeader(),
//       );

//       if (resp.statusCode == 200) {
//         return jsonDecode(resp.body);
//       }

//       if (resp.statusCode == 401) {
//         // token expired → logout
//         await SecureState.logout();
//         return null;
//       }

//       // Do NOT crash login for quota failure
//       return null;

//     } catch (_) {
//       // network failure
//       return null;
//     }
//   }
// }



// ========================v3===========================
// lib/services/quota_service.dart


import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../state/secure_state.dart';
import '../../domain/models/quota.dart';

class QuotaService {
  static Future<Quota?> fetchQuota() async {
    if (!SecureState.isAuthenticated) {
      return null;
    }

    final url =
        "${SecureState.serverBaseUrl}/quota/";

    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: SecureState.authHeader(),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return Quota.fromJson(data);
      }

      if (resp.statusCode == 401) {
        await SecureState.logout();
        return null;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

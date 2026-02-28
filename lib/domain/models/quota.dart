// class Quota {
//   final int usedBytes;
//   final int limitBytes;

//   Quota({
//     required this.usedBytes,
//     required this.limitBytes,
//   });

//   factory Quota.fromJson(Map<String, dynamic> json) {
//     return Quota(
//       usedBytes: json["used_bytes"] ?? 0,
//       limitBytes: json["limit_bytes"] ?? 0,
//     );
//   }
// }
// =========================v2===========================
// lib/models/quota.dart

class Quota {
  final int usedBytes;
  final int limitBytes;
  final int remainingBytes;
  final double percentUsed;

  Quota({
    required this.usedBytes,
    required this.limitBytes,
    required this.remainingBytes,
    required this.percentUsed,
  });

  factory Quota.fromJson(Map<String, dynamic> json) {
    return Quota(
      usedBytes: json["used_bytes"] ?? 0,
      limitBytes: json["limit_bytes"] ?? 0,
      remainingBytes: json["remaining_bytes"] ?? 0,
      percentUsed: (json["percent_used"] ?? 0).toDouble(),
    );
  }
}

// import 'package:flutter/material.dart';

// class StorageUsageCard extends StatelessWidget {
//   final int usedBytes;
//   final int limitBytes;

//   const StorageUsageCard({
//     super.key,
//     required this.usedBytes,
//     required this.limitBytes,
//   });

//   double get _ratio =>
//       limitBytes == 0 ? 0 : usedBytes / limitBytes;

//   Color _barColor(BuildContext context) {
//     if (_ratio >= 0.95) return Colors.redAccent;
//     if (_ratio >= 0.80) return Colors.orangeAccent;
//     return Theme.of(context).colorScheme.primary;
//   }

//   String _format(int bytes) {
//     final mb = bytes / (1024 * 1024);
//     final gb = mb / 1024;

//     if (gb >= 1) {
//       return "${gb.toStringAsFixed(2)} GB";
//     }
//     return "${mb.toStringAsFixed(1)} MB";
//   }

//   @override
//   Widget build(BuildContext context) {
//     final percent = (_ratio * 100).clamp(0, 100).toStringAsFixed(0);

//     return Card(
//       margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Storage usage",
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 8),

//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: LinearProgressIndicator(
//                 value: _ratio.clamp(0, 1),
//                 minHeight: 10,
//                 backgroundColor:
//                     Colors.grey.withOpacity(0.25),
//                 valueColor: AlwaysStoppedAnimation(
//                   _barColor(context),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 8),

//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "${_format(usedBytes)} used",
//                   style: const TextStyle(fontSize: 12),
//                 ),
//                 Text(
//                   "$percent% of ${_format(limitBytes)}",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _ratio >= 0.95
//                         ? Colors.redAccent
//                         : Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// ==================================================================
import 'package:flutter/material.dart';

class StorageUsageCard extends StatelessWidget {
  final int usedBytes;
  final int limitBytes;

  const StorageUsageCard({
    super.key,
    required this.usedBytes,
    required this.limitBytes,
  });

  double get _ratio =>
      limitBytes == 0 ? 0 : usedBytes / limitBytes;

  String _format(int bytes) {
    final mb = bytes / (1024 * 1024);
    final gb = mb / 1024;

    if (gb >= 1) {
      return "${gb.toStringAsFixed(2)} GB";
    }
    return "${mb.toStringAsFixed(1)} MB";
  }

  /// Color logic still matters for warning states
  Gradient _progressGradient() {
    if (_ratio >= 0.95) {
      return const LinearGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
      );
    }
    if (_ratio >= 0.80) {
      return const LinearGradient(
        colors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
      );
    }
    return const LinearGradient(
      colors: [
        Color(0xFF7C4DFF), // deep purple
        Color(0xFFB388FF), // soft violet
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent =
        (_ratio * 100).clamp(0, 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A24),
              const Color(0xFF221B33),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Storage usage",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),

            // ───── Gradient progress bar ─────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  FractionallySizedBox(
                    widthFactor: _ratio.clamp(0, 1),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: _progressGradient(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_format(usedBytes)} used",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  "$percent% of ${_format(limitBytes)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: _ratio >= 0.95
                        ? Colors.redAccent
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/utils/trash_retention.dart';

void main() {
  group('TrashRetention.daysLeftLabel', () {
    // Every fixture below is offset a couple of hours away from an exact
    // day boundary on purpose. daysLeftLabel calls DateTime.now() internally
    // a moment after these fixtures are built, and Duration.inDays
    // truncates -- so a fixture built at exactly "N days from now" can
    // truncate down to N-1 depending on how much wall-clock time elapses
    // between fixture construction and the function's own DateTime.now()
    // call. Padding by a couple of hours keeps every case comfortably clear
    // of that boundary so the test is deterministic either way.

    test('uses the server-provided purge_after directly when present', () {
      // Server retention could be anything -- 20 days here, deliberately NOT
      // the client's own 7-day default, so this only passes if purge_after
      // is actually being read rather than silently recomputed from
      // deletedAt + a hardcoded number.
      final purgeAfter = DateTime.now().add(const Duration(days: 20, hours: 2)).toIso8601String();
      final deletedAt = DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String();

      final label = TrashRetention.daysLeftLabel(purgeAfter: purgeAfter, deletedAt: deletedAt);

      expect(label, equals("20 days left"));
    });

    test('falls back to deletedAt + the default retention window when purge_after is absent', () {
      // This is what silvora_backend's list_trash() response actually looks
      // like today (2026-09-06) -- no purge_after key at all.
      final deletedAt = DateTime.now().subtract(const Duration(days: 1, hours: 22)).toIso8601String();

      final label = TrashRetention.daysLeftLabel(purgeAfter: null, deletedAt: deletedAt);

      // 7-day default minus ~1.9 elapsed days = ~5.1 days remaining.
      expect(label, equals("5 days left"));
    });

    test('reflects a changed server-side retention window instead of silently drifting', () {
      // This is the exact drift scenario the original finding described: if
      // the server's retention window is ever changed (here, from 7 to 30
      // days), a client relying purely on a hardcoded 7 would report the
      // wrong countdown. Reading purge_after directly can't drift.
      final purgeAfter = DateTime.now().add(const Duration(days: 25, hours: 2)).toIso8601String();

      final label = TrashRetention.daysLeftLabel(purgeAfter: purgeAfter, deletedAt: null);

      expect(label, equals("25 days left"));
    });

    test('returns "Expires soon" once purge_after has passed', () {
      final purgeAfter = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();

      final label = TrashRetention.daysLeftLabel(purgeAfter: purgeAfter, deletedAt: null);

      expect(label, equals("Expires soon"));
    });

    test('returns "Expires soon" once the fallback deletedAt-based estimate has passed', () {
      final deletedAt = DateTime.now().subtract(const Duration(days: 8)).toIso8601String();

      final label = TrashRetention.daysLeftLabel(purgeAfter: null, deletedAt: deletedAt);

      expect(label, equals("Expires soon"));
    });

    test('an unparseable purge_after falls back to the deletedAt estimate rather than crashing', () {
      final deletedAt = DateTime.now().subtract(const Duration(days: 2, hours: 22)).toIso8601String();

      final label = TrashRetention.daysLeftLabel(purgeAfter: "not-a-date", deletedAt: deletedAt);

      // 7-day default minus ~2.9 elapsed days = ~4.1 days remaining.
      expect(label, equals("4 days left"));
    });

    test('returns "Unknown" when neither purge_after nor deletedAt is available', () {
      final label = TrashRetention.daysLeftLabel(purgeAfter: null, deletedAt: null);

      expect(label, equals("Unknown"));
    });

    test('an unparseable deletedAt with no purge_after falls back to a plain day count', () {
      final label = TrashRetention.daysLeftLabel(purgeAfter: null, deletedAt: "garbage");

      expect(label, equals("7 days"));
    });
  });
}

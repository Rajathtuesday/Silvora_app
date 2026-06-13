import 'package:flutter_test/flutter_test.dart';
import 'package:silvora_app/services/retry.dart';

void main() {
  Future<void> noSleep(Duration _) async {}

  group('retry', () {
    test('returns immediately on first success', () async {
      var calls = 0;
      final r = await retry(() async {
        calls++;
        return 42;
      }, sleep: noSleep);
      expect(r, 42);
      expect(calls, 1);
    });

    test('retries a thrown error then succeeds', () async {
      var calls = 0;
      final r = await retry(() async {
        calls++;
        if (calls < 3) throw Exception("dropped socket");
        return "ok";
      }, sleep: noSleep);
      expect(r, "ok");
      expect(calls, 3);
    });

    test('rethrows after maxAttempts and stops trying', () async {
      var calls = 0;
      await expectLater(
        retry(() async {
          calls++;
          throw StateError("x");
        }, maxAttempts: 3, sleep: noSleep),
        throwsA(isA<StateError>()),
      );
      expect(calls, 3);
    });

    test('retryIf exhausts attempts and returns the last result', () async {
      var calls = 0;
      final r = await retry<bool>(
        () async {
          calls++;
          return false; // never "succeeds"
        },
        maxAttempts: 4,
        retryIf: (ok) => !ok,
        sleep: noSleep,
      );
      expect(r, false);
      expect(calls, 4);
    });

    test('retryIf stops as soon as the result is good', () async {
      var calls = 0;
      final r = await retry<bool>(
        () async {
          calls++;
          return calls >= 2; // false, then true
        },
        maxAttempts: 5,
        retryIf: (ok) => !ok,
        sleep: noSleep,
      );
      expect(r, true);
      expect(calls, 2);
    });

    test('backoff doubles between attempts', () async {
      final delays = <Duration>[];
      var calls = 0;
      await retry(
        () async {
          calls++;
          if (calls < 3) throw Exception("blip");
          return 1;
        },
        baseDelay: const Duration(seconds: 1),
        sleep: (d) async => delays.add(d),
      );
      expect(delays, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });
  });
}

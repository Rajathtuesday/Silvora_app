import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/utils/auto_lock_timer.dart';

void main() {
  group('AutoLockTimer (2026-09-06 fix: monotonic, not wall-clock)', () {
    test('does not report lock-worthy if resume happens without ever backgrounding', () {
      final timer = AutoLockTimer();
      expect(timer.shouldLockOnResume(const Duration(seconds: 1)), isFalse);
    });

    test('does not lock if resumed before the threshold elapses', () async {
      final timer = AutoLockTimer();
      timer.markBackgrounded();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(timer.shouldLockOnResume(const Duration(seconds: 5)), isFalse);
    });

    test('locks if resumed after staying away at least the threshold', () async {
      final timer = AutoLockTimer();
      timer.markBackgrounded();
      await Future.delayed(const Duration(milliseconds: 60));

      expect(timer.shouldLockOnResume(const Duration(milliseconds: 30)), isTrue);
    });

    test('a second markBackgrounded before resume does not restart the clock', () async {
      final timer = AutoLockTimer();
      timer.markBackgrounded();
      await Future.delayed(const Duration(milliseconds: 40));
      timer.markBackgrounded(); // must be a no-op -- already running
      await Future.delayed(const Duration(milliseconds: 40));

      // ~80ms have elapsed since the FIRST markBackgrounded call. If the
      // second call had wrongly restarted the clock, only ~40ms would have
      // elapsed and this threshold would not be met.
      expect(timer.shouldLockOnResume(const Duration(milliseconds: 60)), isTrue);
    });

    test('resets on resume so a stale result never carries into the next cycle', () async {
      final timer = AutoLockTimer();
      timer.markBackgrounded();
      await Future.delayed(const Duration(milliseconds: 60));
      expect(timer.shouldLockOnResume(const Duration(milliseconds: 30)), isTrue);

      // Calling again immediately, with no new markBackgrounded in between,
      // must not still report true from leftover state.
      expect(timer.shouldLockOnResume(const Duration(milliseconds: 30)), isFalse);
    });

    test('a full background/resume/background/resume cycle measures each away-period independently', () async {
      final timer = AutoLockTimer();

      timer.markBackgrounded();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(timer.shouldLockOnResume(const Duration(milliseconds: 100)), isFalse); // away briefly

      timer.markBackgrounded();
      await Future.delayed(const Duration(milliseconds: 60));
      expect(timer.shouldLockOnResume(const Duration(milliseconds: 30)), isTrue); // away long enough this time
    });
  });
}

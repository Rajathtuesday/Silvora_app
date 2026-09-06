/// Tracks how long the app has been backgrounded using a monotonic clock
/// (Stopwatch), not wall-clock time.
///
/// The previous implementation (in main.dart) compared two DateTime.now()
/// values -- one taken when the app was backgrounded, one taken on resume.
/// DateTime.now() reflects the device's system clock, which an attacker
/// holding a physically unlocked, backgrounded phone can change: wind the
/// clock backward, wait however long they actually need, then bring the app
/// back to the foreground. The computed "elapsed" wall-clock difference can
/// come out small or even negative, so the 1-minute auto-lock never fires no
/// matter how much real time passed.
///
/// Stopwatch measures elapsed time using the OS's monotonic timer, which is
/// not tied to the wall clock and is not affected by system date/time
/// changes -- there is nothing to wind backward.
class AutoLockTimer {
  final Stopwatch _stopwatch;

  AutoLockTimer({Stopwatch? stopwatch}) : _stopwatch = stopwatch ?? Stopwatch();

  /// Call when the app is backgrounded (paused/inactive). Idempotent: a
  /// second call before the next resume does not restart the clock, so the
  /// measurement is always "time since we FIRST left," matching the
  /// intended behavior of tolerating brief in-and-out app switches without
  /// resetting the away-timer each time.
  void markBackgrounded() {
    if (!_stopwatch.isRunning) _stopwatch.start();
  }

  /// Call when the app resumes. Returns true if the app was actually
  /// backgrounded (via [markBackgrounded]) and stayed away for at least
  /// [threshold]. Always stops and resets the internal clock before
  /// returning, whether or not it returns true, so the next
  /// background/resume cycle starts clean and a stray extra call right
  /// after resume can't report a stale "should lock" a second time.
  bool shouldLockOnResume(Duration threshold) {
    if (!_stopwatch.isRunning) return false; // never actually backgrounded
    final away = _stopwatch.elapsed;
    _stopwatch
      ..stop()
      ..reset();
    return away >= threshold;
  }
}

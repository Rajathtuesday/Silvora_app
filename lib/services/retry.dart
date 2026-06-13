import 'dart:async';

/// Retry an async operation with exponential backoff.
///
/// Two kinds of failure are retried:
///  - the action throws (e.g. a dropped socket), or
///  - [retryIf] returns true for the result (e.g. a non-200 response).
///
/// After [maxAttempts] the last thrown error is rethrown, or the last result
/// is returned. [sleep] is injectable so tests run instantly.
Future<T> retry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(seconds: 1),
  bool Function(T result)? retryIf,
  Future<void> Function(Duration)? sleep,
}) async {
  assert(maxAttempts >= 1);
  final doSleep = sleep ?? (d) => Future<void>.delayed(d);

  var attempt = 0;
  while (true) {
    attempt++;
    try {
      final result = await action();
      if (retryIf != null && retryIf(result) && attempt < maxAttempts) {
        await doSleep(_backoff(baseDelay, attempt));
        continue;
      }
      return result;
    } catch (_) {
      if (attempt >= maxAttempts) rethrow;
      await doSleep(_backoff(baseDelay, attempt));
    }
  }
}

/// baseDelay * 2^(attempt-1): 1s, 2s, 4s, ...
Duration _backoff(Duration baseDelay, int attempt) {
  return baseDelay * (1 << (attempt - 1));
}

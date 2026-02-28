// lib/upload/upload_state.dart

enum UploadState {
  created,        // local only, nothing sent to server
  starting,       // requesting uploadId from server
  running,        // actively uploading chunks
  paused,         // halted safely
  resuming,       // reconciling local vs server
  finalizing,     // server assembling
  completed,      // immutable terminal state
  failed,         // unrecoverable without user action
}

enum UploadPauseReason {
  authRequired,        // user logged out / token expired
  vaultLocked,         // master key wiped
  networkLost,         // connectivity issue
  integrityMismatch,  // crypto or chunk mismatch
  appBackgrounded,    // OS lifecycle
}

bool isTerminalState(UploadState s) {
  return s == UploadState.completed || s == UploadState.failed;
}

/// Allowed state transitions (security critical)
const Map<UploadState, Set<UploadState>> allowedTransitions = {
  UploadState.created: {
    UploadState.starting,
    UploadState.failed,
  },
  UploadState.starting: {
    UploadState.running,
    UploadState.paused,
    UploadState.failed,
  },
  UploadState.running: {
    UploadState.paused,
    UploadState.finalizing,
    UploadState.failed,
  },
  UploadState.paused: {
    UploadState.resuming,
    UploadState.failed,
  },
  UploadState.resuming: {
    UploadState.running,
    UploadState.paused,
    UploadState.failed,
  },
  UploadState.finalizing: {
    UploadState.completed,
    UploadState.failed,
  },
  UploadState.completed: const {},
  UploadState.failed: const {},
};

void assertValidTransition(
  UploadState from,
  UploadState to,
) {
  final allowed = allowedTransitions[from];
  if (allowed == null || !allowed.contains(to)) {
    throw StateError(
      "Invalid upload state transition: $from → $to",
    );
  }
}

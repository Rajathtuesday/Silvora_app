# Silvora

A zero-knowledge, end-to-end encrypted (E2EE) cloud storage app. Files are
encrypted on-device before upload; the server only ever stores ciphertext and
encrypted key envelopes, and has no way to read your files, your filenames,
or recover your account if you lose both your password and recovery phrase.

This is the Flutter client. The companion Django backend lives in a separate
repository (`silvora_demo`).

## How it works

- **Master key**: a random 32-byte key generated on-device at registration,
  wrapped with a KEK derived from your password via Argon2id, uniquely
  salted. The server stores only the encrypted envelope.
- **Files**: a per-file key is derived via HKDF from the master key; chunks
  and filenames are encrypted client-side with XChaCha20-Poly1305 before
  upload, in resumable 2MB chunks.
- **Integrity**: a client-signed manifest (SHA-256 per chunk, encrypted) is
  built and uploaded alongside every file. Downloads verify every chunk
  against it and refuse to proceed on any mismatch, reorder, or truncation.
- **Recovery**: a 24-word BIP39 recovery phrase, generated and verified at
  signup, wraps a second copy of the master key. Forgetting your password
  doesn't mean losing your files, forgetting *both* the password and the
  phrase does.
- **Trash**: deleted files are recoverable for 7 days, then permanently
  purged by a daily backend job.
- **Device security**: the app blocks launch on rooted devices or devices
  with USB debugging / Developer Options enabled, and sets `FLAG_SECURE` to
  block screenshots and screen recording.

## Getting started

Requires the Flutter SDK (`^3.7.2`, see `pubspec.yaml`).

```
flutter pub get
flutter run
```

By default the app points at the production backend
(`https://api.silvora.cloud`). To run against a local backend instead
(Android emulator):

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Testing

```
flutter analyze   # zero issues expected, CI fails on any error/warning
flutter test
```

Both run in CI on every push/PR (`.github/workflows/ci.yml`).

## Project layout

- `lib/crypto/` — key derivation, XChaCha20, HKDF, recovery phrase, file
  decryption + integrity verification.
- `lib/services/` — API client, chunked upload/download, integrity manifest
  build/fetch.
- `lib/screens/` — UI: vault, upload, trash, settings, billing, auth.
- `lib/state/` — in-memory session state (master key, server URL).
- `test/` — unit tests for the crypto and integrity layers.

## Status

Closed beta. Currently in the Play Console Internal Testing track, working
toward Closed Testing.

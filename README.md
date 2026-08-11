# Silvora

A zero-knowledge, end-to-end encrypted (E2EE) cloud storage app. Files are encrypted on-device before upload. The server only ever stores ciphertext and encrypted key envelopes, and has no way to read your files, your filenames, or recover your account if you lose both your password and recovery phrase.

This is the Flutter client. The companion Django backend lives in a separate repository (`silvora_backend`).

## How it works

### The key hierarchy

- **Master key**: a random 32-byte key, generated on-device at registration via `Random.secure()`. This is the root key for the whole vault, and it never leaves the device unencrypted.
- **Password path**: the client derives a KEK from your password with Argon2id (a unique salt per account), then wraps the master key with it using XChaCha20-Poly1305. Only the wrapped envelope is sent to the server.
- **Recovery path, entirely independent of your password**: at signup, the app also generates a 24-word BIP39 recovery phrase, derives a second KEK from it (its own salt, same Argon2id), and wraps a *second* copy of the same master key. A separate value derived from the phrase via HKDF is sent to the server so it can verify you typed the right phrase back, without the server ever learning the phrase itself. Forgetting your password doesn't mean losing your files. Forgetting both the password and the phrase does.
- **Per-file, per-filename, and per-integrity-key derivation**: each of these is its own HKDF derivation from the master key, with its own domain-separation label (`silvora_file_<id>`, `silvora_filename_<id>`, `silvora-integrity-<id>`). A key leaked for one purpose can't be reused for another.

### Where keys actually live

The master key exists **only in memory** while the app is unlocked, held as a static field, and is explicitly zeroed out (overwritten with zeros, not just dereferenced) whenever the app locks. It's never written to disk. The master-key envelope itself, along with its KDF parameters, isn't cached on-device either: it's fetched fresh from the server every time you unlock, then decrypted locally. The only things that do persist on-device are your JWT access and refresh tokens, stored via `flutter_secure_storage` (OS Keychain on iOS, Keystore on Android), and a couple of non-sensitive bits of app state (pending-upload resume markers, the local Downloads index) in plain `shared_preferences`.

The app auto-locks and wipes the in-memory master key if it's been backgrounded for a minute or more.

### Files: upload, download, integrity

Files are chunked at 2MB. Each chunk is encrypted client-side with XChaCha20-Poly1305 using the per-file key and a fresh random nonce, then uploaded as `{nonce, ciphertext, mac}`. Filenames are encrypted the same way, as a single shot rather than chunks, before the upload even starts.

Alongside the file, the app builds and uploads a separate integrity manifest: a SHA-256 hash of every chunk's plaintext, encrypted with its own per-file integrity key. The server can't read this manifest, but it won't finalize an upload without one present. On download, every chunk is re-hashed after decryption and checked against the manifest; any mismatch, reorder, or truncation aborts the download rather than silently serving corrupted or tampered data. An older file with no manifest at all downloads unverified (treated as legacy); a manifest that existed once and has since gone missing is treated as tampering and fails hard, it does not quietly downgrade to unverified.

Uploads are resumable: if the app is killed or loses connectivity mid-upload, relaunching offers to resume from wherever it left off, using the server's record of which chunk indices already arrived.

### Networking

The app talks to the backend over plain HTTPS with a JWT access/refresh token pair. Token refresh is single-flight: if several requests hit a 401 at once, only one refresh call is actually made and the rest wait on it, which avoids a race where concurrent refresh attempts could invalidate each other under refresh-token rotation. The client also proactively refreshes just before a request if the current token's own expiry claim is within 10 seconds of expiring, rather than waiting to get a 401 first.

### Device security

Before login is even reached, a native Android check blocks the app outright on a rooted device, and blocks (with a "recheck" button) if Developer Options or USB debugging are enabled. This check fails open on any internal error, deliberately, since the code's own comment is explicit that it must never lock out a real user on a clean device over a detection glitch. It's heuristic, not a cryptographic guarantee, and it's Android-only. Release builds also set `FLAG_SECURE` on the window to block screenshots and screen recording (skipped in debug builds so store screenshots can still be taken).

### Trash

Deleted files move to Trash with a 7-day countdown before the backend's daily cron job permanently purges them.

## Getting started

Requires the Flutter SDK (`^3.7.2`, see `pubspec.yaml`).

```
flutter pub get
flutter run
```

By default the app points at the production backend (`https://api.silvora.cloud`). To run against a local backend instead (Android emulator):

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

There's no `.env` file anywhere in this repo. All configuration is either this compile-time `dart-define` or a hardcoded default. No Firebase setup is required either, there are no Firebase packages in `pubspec.yaml` and no `google-services.json` in the repo.

## Testing

```
flutter analyze   # zero issues expected, CI fails on any error/warning
flutter test
```

Both run in CI on every push/PR (`.github/workflows/ci.yml`).

Test coverage is entirely at the service and crypto layer: key derivation and round-trips, the password-encoding regression test (an earlier bug mixed up UTF-8 and UTF-16 handling of non-ASCII passwords, there's now a dedicated test asserting the old buggy derivation and the fixed one actually produce different keys), the full recovery-phrase chain, device-security fail-open behavior, integrity manifest tamper detection, and the generic retry helper's backoff timing. There are no widget or integration tests, and the actual network-calling code (`ApiService`, `UploadService`, `DownloadService`, the live `VaultService.unlock`) isn't under test, only the pure logic underneath it is.

## Project layout

- `lib/crypto/`: Argon2id, XChaCha20-Poly1305, HKDF, recovery-phrase crypto, and integrity-manifest verification. This is the actual security boundary of the app; everything else just calls into it.
- `lib/services/`: `AuthClient` (HTTP wrapper with refresh-on-401), upload/download services, integrity manifest build and fetch.
- `lib/state/secure_state.dart`: the only file in `lib/state/`. A single class of static fields acting as in-memory session state (auth tokens, server URL, the unlocked master key, a cached HKDF intermediate value). Not a `Provider`/`Riverpod`/`Bloc` style state object; screens manage their own local UI state with plain `setState`.
- `lib/screens/`: `login/` (login, register, unlock, recovery-phrase display, account recovery), `files/` (the main vault view), `upload/`, `downloads/` (the in-app decrypted-files library), `trash/`, `billing/`, `settings/` (change password, delete account).
- `lib/storage/`: `flutter_secure_storage`-backed JWT persistence.
- `test/`: unit tests for the crypto, integrity, device-security, and retry-helper layers.

Navigation is entirely imperative (`Navigator.push`/`MaterialPageRoute`), there's no named-route table or router package.

## Platform notes

- **Android**: two native `MethodChannel`s in `MainActivity.kt`, one for the root/developer-mode security gate, one for saving files to the public Downloads folder. `minSdk` follows the Flutter default; `compileSdk`/`targetSdk` are 36.
- **iOS**: scaffolding is present and the app builds, but the native device-security and mediastore channels are Android-only. There's no iOS equivalent implementation yet, so treat iOS as unverified rather than assuming parity with Android.
- **Web/desktop**: the platform folders exist (Flutter's default multi-platform scaffold) but the app's real target is mobile. A `web/sodium.js` file is present but unused by any Dart code.

## Known gaps, worth knowing about before you assume something works

- **A signing keystore and its password are committed to this repository** (`android/key.properties`, `android/app/upload-keystore.jks`). That means a fresh clone can build a signed release out of the box, which is convenient, but it also means the signing credential has been sitting in git history. Worth rotating the keystore and removing the old one from history at some point, this is a real exposure, not a style nitpick.
- **`billing/billing_screen.dart` is currently unreachable from the UI.** It's fully built (tier selection, monthly/yearly toggle) but was deliberately pulled from the menu, since Google Play policy requires in-app digital subscriptions to go through Play Billing, and this app instead opens an external browser checkout link. The screen is intact, working code, just dead code pending real Play Billing integration.
- **`lib/screens/file_view/file_view_screen.dart` is an empty file**, not implemented. `lib/screens/viewers/image_view_screen.dart` and `pdf_view_screen.dart` are implemented but not referenced anywhere, the actual file list uses an inline dialog for previews instead.
- **Several model, util, and widget files are empty placeholders**: `lib/models/file_metadata.dart`, `lib/models/user.dart`, `lib/utils/converters.dart`, `lib/utils/logger.dart`, `lib/utils/validators.dart`, `lib/widgets/silvora_button.dart`, `lib/widgets/silvora_textfield.dart`. `lib/models/manifest.dart` and `lib/models/chunk_metadata.dart` do have real classes in them, but nothing else in the app actually imports and uses those classes, the real upload/download code builds and parses the equivalent JSON manually instead.
- **`dio` is listed in `pubspec.yaml` but never imported anywhere.** The app's real HTTP client is the plain `http` package throughout. Safe to remove `dio` as a dependency.
- **A minor Argon2 parameter inconsistency**: `argon2.dart`'s documented default is `parallelism: 2`, but every actual call site (registration, recovery, password change) explicitly passes `parallelism: 1`. Not a security bug since the value that's actually used is what gets stored and later replayed, but the mismatched default is worth cleaning up so it doesn't mislead the next person reading the file.

## Status

Closed beta. Currently in the Play Console Internal Testing track. Confirm this is still current before repeating it elsewhere, status like this goes stale fast.

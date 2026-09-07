# Changelog

All notable changes to the Silvora app are recorded here, newest first.
This file starts 2026-09-07 - it is not a retroactive rewrite of the full
project history. For anything earlier, `git log` is the source of truth.

---

## 2026-09-07

### Fixed
- **App hanging indefinitely on launch, on real devices** - two separate unbounded native/platform calls in the startup path, found by testing the actual release build on real hardware (a debug build hides both, since it skips the security gate entirely):
  - The root-detection check (`MainActivity.kt`) ran `Runtime.exec(["which", "su"])` synchronously on the main thread with no timeout. Some devices' shell simply never returns promptly. Moved onto a worker thread with a 2-second timeout, failing open (treating the device as not rooted) if it doesn't return in time - a slow root check should never be the reason a legitimate user can't open their own vault.
  - `flutter_secure_storage` reads/writes (`jwt_store.dart`) can hang indefinitely on certain Samsung devices' Android Keystore implementation - a known, documented category of real hangs on that plugin. Every read and write is now wrapped in a 3-second timeout.
- **Email/username getting auto-capitalized while typing**, silently breaking login for anyone who registered with a capital letter the server had already lowercased before storing. Fixed on the app side too (`textCapitalization: TextCapitalization.none` plus explicit `.toLowerCase()`) rather than relying on the server to normalize it alone.

### Added
- **Show/hide toggle on the password fields during registration.**

Shipped as `1.0.5+6`.

---

## Recent history

A condensed summary of earlier shipped work, grouped by theme rather than
commit-by-commit. See `git log` for the exact commits.

- Required the current password before allowing a password change.
- Fixed resumable upload silently restarting from scratch on a flaky resume check.
- Zeroized the ephemeral KEK and cached HKDF PRK in several spots that had been missed on lock/delete.
- Switched background auto-lock to a monotonic timer instead of the wall clock (immune to the user changing their system clock).
- Preferred the server-provided `purge_after` for the Trash countdown instead of a hardcoded 7 days.
- Added client-side rollback/replay protection to the integrity manifest, and fixed a 404-spoofing gap that could orphan plaintext on a failed decrypt.
- Added a password strength check at registration.

---

*For anything before this file started, see the full commit history: `git log`.*

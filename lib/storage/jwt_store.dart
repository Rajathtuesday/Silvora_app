// lib/storage/jwt_store.dart
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Real production incident, 2026-09-07: flutter_secure_storage's default
/// Android backend (EncryptedSharedPreferences over the Android Keystore)
/// is well documented to hang indefinitely on certain real Samsung devices
/// -- a known category of Keystore/hardware-security-module quirk, not
/// something this app's own code can prevent at the source. AuthGate calls
/// getAccessToken()/getRefreshToken() on every single app launch, before
/// showing anything but a bare loading spinner, with no timeout anywhere
/// -- so a hang here meant the app never opened at all, on real hardware,
/// for a real tester. This was the second of two separate unbounded
/// platform-channel calls found in the startup path today; the first
/// (the root-check in DeviceSecurityGate) was fixed earlier and uses the
/// same reasoning.
///
/// Every operation below is now bounded. A timeout is treated the same as
/// "nothing was there" (null for a read, silently give up for a write) --
/// the safe fallback either way: AuthGate just sends the user to the
/// login screen instead of resuming their session, a minor inconvenience
/// next to the app not opening at all.
const _kStorageTimeout = Duration(seconds: 3);

class JwtStore {
  static const _kAccess = 'jwt_access';
  static const _kRefresh = 'jwt_refresh';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens(String access, String refresh) async {
    try {
      await _storage.write(key: _kAccess, value: access).timeout(_kStorageTimeout);
      await _storage.write(key: _kRefresh, value: refresh).timeout(_kStorageTimeout);
    } on TimeoutException {
      // Nothing safe to do here except not hang the caller -- the user
      // will simply be asked to log in again next launch instead of
      // resuming a session that never got saved.
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _kAccess).timeout(_kStorageTimeout);
    } on TimeoutException {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _kRefresh).timeout(_kStorageTimeout);
    } on TimeoutException {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kAccess).timeout(_kStorageTimeout);
      await _storage.delete(key: _kRefresh).timeout(_kStorageTimeout);
    } on TimeoutException {
      // Best-effort -- if the underlying storage is hanging, there is
      // nothing more this call can safely do.
    }
  }
}

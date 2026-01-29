
// ================================================
// lib/services/vault_service.dart
import 'dart:typed_data';
import '../crypto/master_key.dart';
import '../state/secure_state.dart';

class VaultService {
  /// Called ONLY after successful login
  static Future<void> unlockWithPassword(String password) async {
    final Uint8List masterKey =
        await MasterKey.deriveFromPassword(password);

    SecureState.setMasterKey(masterKey);
  }

  static Uint8List get masterKey {
    return SecureState.requireMasterKey();
  }
}

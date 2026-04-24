import 'dart:typed_data';

import '../state/secure_state.dart';
import '../crypto/argon2.dart';
import '../crypto/xchacha.dart';

class VaultService {
  static Future<void> unlockWithPassword({
    required String password,
    required Uint8List salt,
    required Uint8List encryptedMasterKey,
    required Uint8List nonce,
    int iterations = 3,
  }) async {
    final kek = await Argon2Kdf.deriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
    );

    final mac = encryptedMasterKey.sublist(encryptedMasterKey.length - 16);
    final ciphertext = encryptedMasterKey.sublist(0, encryptedMasterKey.length - 16);

    final masterKey = await XChaCha.decrypt(
      ciphertext: ciphertext,
      key: kek,
      nonce: nonce,
      mac: mac,
    );

    SecureState.setMasterKey(masterKey);
  }

  static void lock() {
    SecureState.lock();
  }

  static bool get isUnlocked {
    try {
      final _ = SecureState.masterKey;
      return true;
    } catch (_) {
      return false;
    }
  }
}

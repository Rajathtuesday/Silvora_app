import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/argon2.dart';
import 'package:silvora_app/crypto/master_key.dart';
import 'package:silvora_app/crypto/xchacha.dart';
import 'package:silvora_app/state/secure_state.dart';
import 'package:silvora_app/services/vault_service.dart';

void main() {
  group('Cryptography Round-Trip Tests', () {
    test('MasterKey generation creates exactly 32 random bytes', () {
      final key1 = MasterKey.generate();
      final key2 = MasterKey.generate();

      expect(key1.length, equals(32));
      expect(key2.length, equals(32));
      expect(key1, isNot(equals(key2)), reason: "Keys should be unique/random");
    });

    test('XChaCha20 correctly encrypts and decrypts a MasterKey', () async {
      final originalMasterKey = MasterKey.generate();
      
      // Simulate Key Encryption Key (KEK) generated from password
      final randomKek = MasterKey.generate(); 
      final nonce = await XChaCha.randomNonce();

      // Encrypt
      final box = await XChaCha.encrypt(
        plaintext: originalMasterKey,
        key: randomKek,
        nonce: nonce,
      );

      expect(box.cipherText.length, equals(originalMasterKey.length));

      // Decrypt
      final decryptedBytes = await XChaCha.decrypt(
        ciphertext: Uint8List.fromList(box.cipherText),
        key: randomKek,
        nonce: Uint8List.fromList(box.nonce),
        mac: Uint8List.fromList(box.mac.bytes),
      );
      expect(decryptedBytes, equals(originalMasterKey));
    });

    test('Argon2Kdf derives a consistent 32-byte key from password and salt', () async {
      final password = "MySuperSecretPassword123!";
      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      final key1 = await Argon2Kdf.deriveKey(password: password, salt: salt, iterations: 3);
      final key2 = await Argon2Kdf.deriveKey(password: password, salt: salt, iterations: 3);

      expect(key1.length, equals(32));
      expect(key1, equals(key2), reason: "Same password and salt must yield the same KEK");
    });
  });

  group('VaultService and SecureState', () {
    setUp(() {
      SecureState.lock(); // Ensure clean state before each test
    });

    test('SecureState safely locks and unlocks', () {
      expect(SecureState.isUnlocked, isFalse);

      final fakeKey = Uint8List(32);
      SecureState.setMasterKey(fakeKey);
      
      expect(SecureState.isUnlocked, isTrue);
      expect(SecureState.masterKey, equals(fakeKey));

      SecureState.lock();
      expect(SecureState.isUnlocked, isFalse);
      expect(() => SecureState.masterKey, throwsStateError);
    });

    test('VaultService.unlockWithPassword handles Argon2+XChaCha correctly', () async {
      // 1. Setup a vault just like the register flow
      final password = "UserPassword123";
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      
      final masterKey = MasterKey.generate();
      
      final kek = await Argon2Kdf.deriveKey(password: password, salt: salt, iterations: 2);
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);
      
      // The backend stores the envelope as ciphertext + mac
      final envelopeBytes = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);

      // 2. Attempt to unlock
      await VaultService.unlockWithPassword(
        password: password,
        salt: salt,
        encryptedMasterKey: envelopeBytes,
        nonce: nonce,
        iterations: 2,
      );

      // 3. Verify success
      expect(SecureState.isUnlocked, isTrue);
      expect(SecureState.masterKey, equals(masterKey));
    });
  });
}

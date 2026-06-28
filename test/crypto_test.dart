import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/argon2.dart';
import 'package:silvora_app/crypto/hkdf.dart';
import 'package:silvora_app/crypto/master_key.dart';
import 'package:silvora_app/crypto/xchacha.dart';
import 'package:silvora_app/state/secure_state.dart';
import 'package:silvora_app/services/vault_service.dart';
import 'package:silvora_app/crypto/recovery_crypto.dart';

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

    test('Argon2Kdf encodes non-ASCII passwords as UTF-8, not UTF-16 code units', () async {
      // Regression test for a real bug: .codeUnits is raw UTF-16 code units,
      // identical to UTF-8 only for ASCII. 'é' is one UTF-16 code unit but
      // two UTF-8 bytes, so the two encodings feed Argon2 different bytes
      // and must derive different keys. If this ever regresses back to
      // .codeUnits, this test independently re-derives the old (wrong) key
      // and proves the production code no longer matches it.
      const password = "Pässwörd123!é";
      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      final actualKey = await Argon2Kdf.deriveKey(password: password, salt: salt, iterations: 3);

      final oldBuggySecretKey = await Argon2id(memory: 65536, iterations: 3, parallelism: 2, hashLength: 32)
          .deriveKey(secretKey: SecretKey(Uint8List.fromList(password.codeUnits)), nonce: salt);
      final oldBuggyKey = Uint8List.fromList(await oldBuggySecretKey.extractBytes());

      expect(actualKey, isNot(equals(oldBuggyKey)),
          reason: "Argon2Kdf must use utf8.encode(password), not password.codeUnits");

      // And it must still be internally consistent -- same non-ASCII
      // password + salt always derives the same key.
      final actualKeyAgain = await Argon2Kdf.deriveKey(password: password, salt: salt, iterations: 3);
      expect(actualKey, equals(actualKeyAgain));
    });
  });

  group('HKDF Extract/Expand split', () {
    test('split Extract+Expand produces identical output to the combined call', () async {
      // The whole point of caching the PRK is that it must be invisible
      // to anyone decrypting a file -- if this ever drifted from the
      // combined call's output, every already-encrypted file would
      // become undecryptable, same class of bug as the password-encoding
      // fix earlier.
      final ikm = Uint8List.fromList(List.generate(32, (i) => i));
      final info = utf8.encode("silvora_file_some-file-id");

      final combined = await hkdfSha256(ikm: ikm, info: info);

      final prk = await hkdfExtract(ikm);
      final split = await hkdfExpand(prk: prk, info: info);

      expect(split, equals(combined));
    });

    test('one Extract reused across multiple Expand calls matches separate combined calls', () async {
      final ikm = Uint8List.fromList(List.generate(32, (i) => 32 - i));
      final prk = await hkdfExtract(ikm);

      for (final label in ["file-a", "file-b", "filename-a"]) {
        final info = utf8.encode("silvora_$label");
        final viaCachedPrk = await hkdfExpand(prk: prk, info: info);
        final viaCombinedCall = await hkdfSha256(ikm: ikm, info: info);
        expect(viaCachedPrk, equals(viaCombinedCall), reason: "mismatch for label $label");
      }
    });

    test('different info labels from the same cached PRK derive different keys', () async {
      final ikm = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final prk = await hkdfExtract(ikm);

      final keyA = await hkdfExpand(prk: prk, info: utf8.encode("file-a"));
      final keyB = await hkdfExpand(prk: prk, info: utf8.encode("file-b"));

      expect(keyA, isNot(equals(keyB)));
    });
  });

  group('SecureState master key PRK cache', () {
    setUp(() => SecureState.lock());
    tearDown(() => SecureState.lock());

    test('getMasterKeyPrk matches a fresh Extract of the same master key', () async {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      SecureState.setMasterKey(key);

      final cached = await SecureState.getMasterKeyPrk();
      final fresh = await hkdfExtract(key);

      expect((await cached.extractBytes()), equals(await fresh.extractBytes()));
    });

    test('getMasterKeyPrk returns the same instance on repeated calls (actually cached)', () async {
      SecureState.setMasterKey(Uint8List.fromList(List.generate(32, (i) => i)));

      final first = await SecureState.getMasterKeyPrk();
      final second = await SecureState.getMasterKeyPrk();

      expect(identical(first, second), isTrue, reason: "should reuse the cached PRK, not recompute it");
    });

    test('lock() clears the cached PRK', () async {
      SecureState.setMasterKey(Uint8List.fromList(List.generate(32, (i) => i)));
      final beforeLock = await SecureState.getMasterKeyPrk();

      SecureState.lock();
      SecureState.setMasterKey(Uint8List.fromList(List.generate(32, (i) => i)));
      final afterRelock = await SecureState.getMasterKeyPrk();

      expect(identical(beforeLock, afterRelock), isFalse,
          reason: "a fresh unlock must compute a fresh PRK, not reuse one from before lock()");
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

  group('Recovery phrase', () {
    test('newSalt generates 32 bytes, not the Argon2id spec minimum of 16', () {
      final salt = RecoveryCrypto.newSalt();
      expect(salt.length, equals(32),
          reason: "A 256-bit recovery phrase's whole security model rests on "
              "this salt being unpredictable -- 32 bytes costs nothing extra "
              "over the 16-byte minimum and removes any ambiguity.");
    });

    test('generates a valid 24-word phrase', () {
      final phrase = RecoveryCrypto.generatePhrase();
      expect(phrase.split(' ').length, equals(24));
      expect(RecoveryCrypto.isValidPhrase(phrase), isTrue);
      expect(RecoveryCrypto.isValidPhrase("not a real recovery phrase at all"), isFalse);
    });

    test('Recovery-KEK is deterministic for the same phrase + salt', () async {
      final phrase = RecoveryCrypto.generatePhrase();
      final salt = RecoveryCrypto.newSalt();
      final k1 = await RecoveryCrypto.deriveKek(phrase, salt);
      final k2 = await RecoveryCrypto.deriveKek(phrase, salt);
      expect(k1, equals(k2));
      expect(k1.length, equals(32));
    });

    test('master key round-trips through the recovery envelope', () async {
      final masterKey = MasterKey.generate();
      final phrase = RecoveryCrypto.generatePhrase();
      final salt = RecoveryCrypto.newSalt();
      final kek = await RecoveryCrypto.deriveKek(phrase, salt);
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);

      final recovered = await XChaCha.decrypt(
        ciphertext: Uint8List.fromList(box.cipherText),
        key: kek,
        nonce: Uint8List.fromList(nonce),
        mac: Uint8List.fromList(box.mac.bytes),
      );
      expect(recovered, equals(masterKey));
    });

    test('auth key is deterministic and 32 bytes', () async {
      final phrase = RecoveryCrypto.generatePhrase();
      final salt = RecoveryCrypto.newSalt();
      final kek = await RecoveryCrypto.deriveKek(phrase, salt);
      final a1 = await RecoveryCrypto.deriveAuthKey(kek);
      final a2 = await RecoveryCrypto.deriveAuthKey(kek);
      expect(a1, equals(a2));
      expect(a1.length, equals(32));
    });
  });
}

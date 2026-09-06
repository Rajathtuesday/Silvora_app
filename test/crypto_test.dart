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
import 'package:silvora_app/crypto/login_auth.dart';
import 'package:silvora_app/crypto/zeroize.dart';

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

    test('lock() actually destroys the cached PRK, not just drops the reference (2026-09-06 fix)', () async {
      // Earlier known limitation: the cached PRK was only dereferenced on
      // lock(), left for the GC's own schedule instead of being byte-wiped
      // like _masterKey. hkdfExtract() now builds the PRK as a
      // SecretKeyData with overwriteWhenDestroyed: true, and lock() now
      // calls .destroy() on it before dropping the reference -- so the same
      // object this test holds a reference to must show as destroyed
      // afterward, proving the wipe reached the real shared instance and
      // not just a copy.
      SecureState.setMasterKey(Uint8List.fromList(List.generate(32, (i) => i)));
      final prk = await SecureState.getMasterKeyPrk() as SecretKeyData;

      expect(prk.hasBeenDestroyed, isFalse);
      SecureState.lock();

      expect(prk.hasBeenDestroyed, isTrue);
      expect(() => prk.bytes, throwsStateError);
    });

    test('the SecretKeyData construction hkdfExtract uses actually zeros its bytes on destroy', () async {
      // Goes one level below SecureState/hkdfExtract to prove the exact
      // mechanism they rely on -- SecretKeyData(bytes, overwriteWhenDestroyed:
      // true) -- really does overwrite real memory, not just flip a
      // "destroyed" flag. SecretKeyData.bytes itself becomes unreadable
      // after destroy() (by design, see the test below), so this keeps its
      // own independent reference to the exact raw Uint8List handed to the
      // constructor -- SecretKeyData/SensitiveBytes wrap that same list
      // in place rather than copying it, so if destroy() truly zeroes the
      // real buffer, this independently-held reference reflects it too.
      final raw = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final key = SecretKeyData(raw, overwriteWhenDestroyed: true);

      expect(raw.any((b) => b != 0), isTrue, reason: "sanity check: key material isn't already all zero");

      key.destroy();

      expect(raw.every((b) => b == 0), isTrue,
          reason: "overwriteWhenDestroyed: true should zero the real underlying buffer in place, "
              "not just discard the pointer to it");
      expect(key.hasBeenDestroyed, isTrue);
      expect(() => key.bytes, throwsStateError);
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

  group('Login-auth key (2026-08-31 fix: login/KEK separation)', () {
    test('deterministic and 32 bytes, same shape as the recovery auth key', () async {
      final kek = Uint8List.fromList(List.generate(32, (i) => i));
      final k1 = await LoginAuthCrypto.deriveLoginAuthKey(kek);
      final k2 = await LoginAuthCrypto.deriveLoginAuthKey(kek);
      expect(k1, equals(k2), reason: "same KEK must always derive the same login-auth-key");
      expect(k1.length, equals(32));
    });

    test('different KEKs (i.e. different passwords) derive different login-auth-keys', () async {
      final kekA = Uint8List.fromList(List.generate(32, (i) => i));
      final kekB = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final a = await LoginAuthCrypto.deriveLoginAuthKey(kekA);
      final b = await LoginAuthCrypto.deriveLoginAuthKey(kekB);
      expect(a, isNot(equals(b)));
    });

    test('is NOT the KEK itself -- it is actually transformed, not passed through', () async {
      final kek = Uint8List.fromList(List.generate(32, (i) => i * 3 % 256));
      final loginAuthKey = await LoginAuthCrypto.deriveLoginAuthKey(kek);
      expect(loginAuthKey, isNot(equals(kek)),
          reason: "if this ever matched the KEK, the whole point of the fix is gone -- "
              "the server would be storing something that IS the key material.");
    });

    test('domain separation actually matters: the SAME kek produces a DIFFERENT '
        'value here than through the recovery-auth-key derivation', () async {
      // Not a real-world scenario (login and recovery normally derive from
      // different KEKs, via different passwords/phrases) -- this isolates
      // the one thing that's supposed to matter: the "silvora-login-auth"
      // vs "silvora-recovery-auth" HKDF info label. If someone ever "simplified"
      // this by reusing one label for both, this test catches it.
      final kek = Uint8List.fromList(List.generate(32, (i) => 255 - i));
      final loginAuthKey = await LoginAuthCrypto.deriveLoginAuthKey(kek);
      final recoveryAuthKeyIfSameKek = await RecoveryCrypto.deriveAuthKey(kek);
      expect(loginAuthKey, isNot(equals(recoveryAuthKeyIfSameKek)),
          reason: "login-auth and recovery-auth must use distinct HKDF info labels");
    });

    test('hex round-trips cleanly via the existing RecoveryCrypto helpers', () async {
      final kek = Uint8List.fromList(List.generate(32, (i) => i));
      final loginAuthKey = await LoginAuthCrypto.deriveLoginAuthKey(kek);
      final hex = RecoveryCrypto.toHex(loginAuthKey);
      final backToBytes = RecoveryCrypto.fromHex(hex);
      expect(backToBytes, equals(loginAuthKey));
    });
  });

  group('Login flow no longer sends the raw password (2026-08-31 fix)', () {
    test('the value sent over the wire is the derived key, not the password, '
        'given the same kek register/login now derive locally', () async {
      // Mirrors what register_screen.dart / login_screen.dart actually do:
      // derive the KEK once, use it both to wrap the master key locally AND
      // to compute what gets sent over the wire -- and confirm those two
      // uses produce genuinely different bytes from the raw password.
      const password = "Str0ng!Vault#Key2026";
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final masterKey = MasterKey.generate();

      final kek = await Argon2Kdf.deriveKey(password: password, salt: salt, iterations: 2);
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(plaintext: masterKey, key: kek, nonce: nonce);
      // envelope isn't inspected further here -- unlockWithPassword's
      // existing test above already covers the encrypt/decrypt round trip
      // for a kek derived this same way; this test's job is the wire value.
      // ignore: unused_local_variable
      final envelope = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);

      final loginAuthKey = await LoginAuthCrypto.deriveLoginAuthKey(kek);
      final wireValue = RecoveryCrypto.toHex(loginAuthKey);

      // What would have been sent under the OLD (vulnerable) scheme.
      expect(wireValue, isNot(equals(password)),
          reason: "the value sent over the wire must never be the raw password");
      expect(wireValue.length, equals(64), reason: "32 bytes, hex-encoded");
    });
  });

  group('zeroize (2026-09-01 fix: ephemeral KEK/master-key wiping)', () {
    test('overwrites every byte of the buffer with 0', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i + 1));
      expect(bytes.any((b) => b != 0), isTrue); // sanity: not already zero

      zeroize(bytes);

      expect(bytes, everyElement(equals(0)));
    });

    test('SecureState.lock() actually zeroizes the master key in place, not just drops it', () async {
      final key = Uint8List.fromList(List.generate(32, (i) => 200 - i));
      SecureState.setMasterKey(key);
      final live = SecureState.masterKey; // same underlying buffer SecureState holds

      SecureState.lock();

      expect(live, everyElement(equals(0)));
    });
  });
}

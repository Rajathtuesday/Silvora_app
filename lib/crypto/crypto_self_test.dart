// import 'dart:typed_data';

// import 'master_key.dart';
// import 'argon2.dart';
// import 'xchacha.dart';
// import '../state/secure_state.dart';

// bool bytesEqual(Uint8List a, Uint8List b) {
//   if (a.length != b.length) return false;
//   for (int i = 0; i < a.length; i++) {
//     if (a[i] != b[i]) return false;
//   }
//   return true;
// }

// Future<void> runCryptoSelfTest() async {
//   print("🔐 CRYPTO SELF TEST — START");

//   // 1️⃣ Generate master key
//   final masterKey = MasterKey.generate();
//   print("Master key length: ${masterKey.length}");
//   assert(masterKey.length == 32);

//   // 2️⃣ Derive password key
//   final salt = Uint8List.fromList([1, 2, 3, 4]);
//   final pwdKey = Argon2Kdf.deriveKey(
//     password: "test-password",
//     salt: salt,
//   );
//   assert(pwdKey.length == 32);

//   // 3️⃣ Encrypt master key
//   final enc = await XChaChaCrypto.encrypt(
//     plaintext: masterKey,
//     key: pwdKey,
//   );

//   // 4️⃣ Decrypt master key
//   final dec = await XChaChaCrypto.decrypt(
//     ciphertext: enc["ciphertext"]!,
//     nonce: enc["nonce"]!,
//     mac: enc["mac"]!,
//     key: pwdKey,
//   );

//   assert(bytesEqual(masterKey, dec));
//   print("✔ Master key encrypt/decrypt OK");

//   // 5️⃣ Load into vault
//   SecureState.unlock(dec);
//   final vaultKey = SecureState.requireMasterKey();
//   assert(bytesEqual(masterKey, vaultKey));
//   print("✔ Vault unlock OK");

//   // 6️⃣ Encrypt sample file bytes
//   final fileData = Uint8List.fromList([10, 20, 30, 40, 50]);

//   final encFile = await XChaChaCrypto.encrypt(
//     plaintext: fileData,
//     key: vaultKey,
//   );

//   final decFile = await XChaChaCrypto.decrypt(
//     ciphertext: encFile["ciphertext"]!,
//     nonce: encFile["nonce"]!,
//     mac: encFile["mac"]!,
//     key: vaultKey,
//   );

//   assert(bytesEqual(fileData, decFile));
//   print("✔ File encryption OK");

//   // 7️⃣ Lock vault
//   SecureState.lock();
//   try {
//     SecureState.requireMasterKey();
//     throw Exception("Vault should be locked");
//   } catch (_) {
//     print("✔ Vault lock OK");
//   }

//   print("✅ CRYPTO SELF TEST — PASSED");
// }




// import 'dart:typed_data';

// import 'master_key.dart';
// import 'xchacha_crypto.dart';
// import '../state/secure_state.dart';

// Future<void> runCryptoSelfTest() async {
//   final masterKey = MasterKey.generate();

//   SecureState.unlock(masterKey);

//   final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);

//   final enc = await XChaChaCrypto.encrypt(
//     plaintext: plaintext,
//     key: SecureState.masterKey,
//   );

//   final dec = await XChaChaCrypto.decrypt(
//     ciphertext: enc["ciphertext"]!,
//     nonce: enc["nonce"]!,
//     mac: enc["mac"]!,
//     key: SecureState.masterKey,
//   );

//   if (dec.length != plaintext.length) {
//     throw Exception("Crypto self test failed");
//   }
// }
// =========================================================
import 'dart:typed_data';
import 'dart:math';

import 'package:cryptography/src/cryptography/secret_box.dart';

import 'xchacha.dart';
import 'master_key.dart';

Future<void> runCryptoSelfTest() async {
  final crypto = XChaCha();

  // 1️⃣ Generate master key
  final Uint8List masterKey = MasterKey.generate();

  // 2️⃣ Random plaintext
  final rnd = Random.secure();
  final Uint8List plain = Uint8List.fromList(
    List.generate(1024, (_) => rnd.nextInt(256)),
  );

  // 3️⃣ Nonce
  final Uint8List nonce = await crypto.randomNonce();

  // 4️⃣ Encrypt → returns SecretBox internally
  final encrypted = await crypto.encrypt(
    plaintext: plain,
    key: masterKey,
    nonce: nonce,
  );

  // 🔍 encrypted = cipherText || mac (your wrapper design)
  final int macLen = 16;
  final Uint8List cipherText =
      encrypted.sublist(0, encrypted.length - macLen);
  final Uint8List mac =
      encrypted.sublist(encrypted.length - macLen);

  // 5️⃣ Decrypt
  final Uint8List decrypted = await crypto.decrypt(
    ciphertext: cipherText,
    key: masterKey,
    nonce: nonce,
    mac: mac,
  );

  // 6️⃣ Verify
  if (plain.length != decrypted.length) {
    throw Exception("❌ Length mismatch");
  }

  for (int i = 0; i < plain.length; i++) {
    if (plain[i] != decrypted[i]) {
      throw Exception("❌ Data corruption at byte $i");
    }
  }

  // ignore: avoid_print
  print("✅ Crypto self-test PASSED");
}

// extension on SecretBox {
//   get length => null;
// }
// // ================================================================================
//     info: utf8.encode("silvora-chunk-$chunkIndex"),
//   );
// }
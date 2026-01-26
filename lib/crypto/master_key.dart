// import 'dart:typed_data';
// import 'dart:convert';
// import 'package:cryptography/cryptography.dart';
// import 'package:collection/collection.dart';

// import 'argon2.dart';
// import 'hkdf.dart';
// import 'xchacha.dart';

// class MasterKeyManager {
//   final Argon2KeyDerivation argon2 = Argon2KeyDerivation();
//   final XChaCha xchacha = XChaCha();

//   /// Generate 32 random bytes using a secure algorithm's RNG
//   List<int> generateMasterKey() {
//     final rng = Xchacha20.poly1305Aead().newNonce(); // 24 bytes
//     final extended = <int>[]
//       ..addAll(rng)
//       ..addAll(Xchacha20.poly1305Aead().newNonce()); // +24 bytes → >32
//     return extended.sublist(0, 32);
//   }

//   Future<Map<String, String>> encryptMasterKey({
//     required List<int> masterKey,
//     required String password,
//   }) async {
//     final salt = Xchacha20.poly1305Aead().newNonce().sublist(0, 16);

//     final derived = await argon2.deriveKey(
//       password: password,
//       salt: salt,
//     );

//     final enc = await xchacha.encrypt(masterKey, derived);

//     return {
//       "encrypted_master_key_hex": _toHex(enc["ciphertext"]!),
//       "key_salt_b64": base64.encode(salt),
//       "nonce_b64": base64.encode(enc["nonce"]!),
//       "mac_b64": base64.encode(enc["mac"]!),
//     };
//   }

//   Future<List<int>> decryptMasterKey({
//     required String encryptedMasterKeyHex,
//     required String password,
//     required String keySaltB64,
//     required String nonceB64,
//     required String macB64,
//   }) async {
//     final ciphertext = _fromHex(encryptedMasterKeyHex);
//     final salt = base64.decode(keySaltB64);
//     final nonce = base64.decode(nonceB64);
//     final mac = base64.decode(macB64);

//     final derived = await argon2.deriveKey(
//       password: password,
//       salt: salt,
//     );

//     return await xchacha.decrypt(ciphertext, nonce, derived, mac);
//   }

//   Future<List<int>> deriveFileKey(List<int> masterKey, List<int> fileSalt) {
//     return hkdfSha256(
//       salt: fileSalt,
//       ikm: masterKey,
//       info: utf8.encode("silvora:file"),
//       length: 32,
//     );
//   }

//   Future<List<int>> deriveChunkKey(List<int> fileKey, int index) {
//     return hkdfSha256(
//       salt: null,
//       ikm: fileKey,
//       info: utf8.encode("silvora:chunk:$index"),
//       length: 32,
//     );
//   }

//   String _toHex(List<int> bytes) =>
//       bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

//   List<int> _fromHex(String hex) {
//     final out = <int>[];
//     for (var i = 0; i < hex.length; i += 2) {
//       out.add(int.parse(hex.substring(i, i + 2), radix: 16));
//     }
//     return out;
//   }
// }





// =-------------------------------------------------------------------------=

// lib/crypto/master_key.dart
//
// Master key generation + wrapping/unwrapping using the user's password.
// Algo: XChaCha20-Poly1305 + PBKDF2-HMAC-SHA256
//
// This is "phase 1" E2EE: server only ever sees an encrypted master key.

// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';

// /// Metadata + encrypted blob that you store on the backend.
// class MasterKeyEnvelope {
//   final Uint8List masterKey;        // plaintext MK (only kept in memory on client)
//   final String ciphertextB64;       // base64 of encrypted MK
//   final String nonceB64;            // base64 of 24-byte XChaCha20 nonce
//   final String macB64;              // base64 of 16-byte Poly1305 MAC
//   final String saltB64;             // base64 of KDF salt
//   final String algo;                // identifier string

//   const MasterKeyEnvelope({
//     required this.masterKey,
//     required this.ciphertextB64,
//     required this.nonceB64,
//     required this.macB64,
//     required this.saltB64,
//     required this.algo,
//   });

//   Map<String, dynamic> toJson() => {
//         "mk_ciphertext_b64": ciphertextB64,
//         "mk_nonce_b64": nonceB64,
//         "mk_mac_b64": macB64,
//         "mk_salt_b64": saltB64,
//         "mk_algo": algo,
//       };
// }

// class MasterKeyManager {
//   // Identifier stored in DB; useful if we later change algorithms.
//   static const String algoId = "xchacha20-poly1305+pbkdf2-sha256";

//   static const int _masterKeyBytes = 32;
//   static const int _pwKeyBytes = 32;
//   static const int _saltBytes = 16;
//   static const int _pbkdf2Iterations = 150000; // bump in prod if needed

//   static final _xchacha = Xchacha20.poly1305Aead();

//   /// Create a fresh 32-byte master key and wrap it with a key derived
//   /// from the user's password.
//   ///
//   /// Call this **once** during registration (or first login that needs E2EE).
//   static Future<MasterKeyEnvelope> createForNewUser({
//     required String password,
//   }) async {
//     // 1) Generate raw master key
//     final mk = _randomBytes(_masterKeyBytes);

//     // 2) Generate random salt for password KDF
//     final salt = _randomBytes(_saltBytes);

//     // 3) Derive password key using PBKDF2-HMAC-SHA256
//     final pwKeyBytes = await _derivePasswordKeyBytes(
//       password: password,
//       salt: salt,
//     );

//     final pwKey = SecretKey(pwKeyBytes);

//     // 4) Encrypt the master key with XChaCha20-Poly1305
//     final nonce = await _xchacha.newNonce();
//     final secretBox = await _xchacha.encrypt(
//       mk,
//       secretKey: pwKey,
//       nonce: nonce,
//     );

//     final ciphertextB64 = base64Encode(secretBox.cipherText);
//     final nonceB64 = base64Encode(nonce);
//     final macB64 = base64Encode(secretBox.mac.bytes);
//     final saltB64 = base64Encode(salt);

//     return MasterKeyEnvelope(
//       masterKey: mk,
//       ciphertextB64: ciphertextB64,
//       nonceB64: nonceB64,
//       macB64: macB64,
//       saltB64: saltB64,
//       algo: algoId,
//     );
//   }

//   /// Given the stored envelope (from server) + user's password,
//   /// decrypt and return the plaintext master key.
//   ///
//   /// Throw if the password is wrong or data is corrupted.
//   static Future<Uint8List> unlockMasterKey({
//     required String password,
//     required String ciphertextB64,
//     required String nonceB64,
//     required String macB64,
//     required String saltB64,
//     required String algo,
//   }) async {
//     if (algo != algoId) {
//       // Later we can support migrations; for now, just enforce.
//       throw StateError("Unsupported master key algo: $algo");
//     }

//     final ciphertext = base64Decode(ciphertextB64);
//     final nonce = base64Decode(nonceB64);
//     final macBytes = base64Decode(macB64);
//     final salt = base64Decode(saltB64);

//     // 1) Re-derive password key
//     final pwKeyBytes = await _derivePasswordKeyBytes(
//       password: password,
//       salt: salt,
//     );
//     final pwKey = SecretKey(pwKeyBytes);

//     // 2) Decrypt
//     final secretBox = SecretBox(
//       ciphertext,
//       nonce: nonce,
//       mac: Mac(macBytes),
//     );

//     final clear = await _xchacha.decrypt(
//       secretBox,
//       secretKey: pwKey,
//     );

//     return Uint8List.fromList(clear);
//   }

//   /// Internal: derive a 32-byte key from password + salt using PBKDF2-HMAC-SHA256.
//   static Future<Uint8List> _derivePasswordKeyBytes({
//     required String password,
//     required Uint8List salt,
//   }) async {
//     final pbkdf2 = Pbkdf2(
//       macAlgorithm: Hmac.sha256(),
//       iterations: _pbkdf2Iterations,
//       bits: _pwKeyBytes * 8,
//     );

//     final secretKey = await pbkdf2.deriveKey(
//       secretKey: SecretKey(utf8.encode(password)),
//       nonce: salt, // 'nonce' is used as salt in this API
//     );

//     return Uint8List.fromList(await secretKey.extractBytes());
//   }

//   static Uint8List _randomBytes(int length) {
//     final rnd = Random.secure();
//     return Uint8List.fromList(
//       List<int>.generate(length, (_) => rnd.nextInt(256)),
//     );
//   }
// }

// =--------------------------------------------------------------------------------------------=


// // lib/crypto/master_key.dart
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';

// import 'package:cryptography/cryptography.dart';

// /// Metadata for user's master key coming from backend.
// class MasterKeyMeta {
//   final bool hasMasterKey;
//   final String? encryptedMasterKeyHex;
//   final String? kdfSaltB64;
//   final int? kdfIterations;
//   final String? kdfAlgorithm;
//   final String? aeadAlgorithm;
//   final String? nonceB64;
//   final int? version;

//   MasterKeyMeta({
//     required this.hasMasterKey,
//     this.encryptedMasterKeyHex,
//     this.kdfSaltB64,
//     this.kdfIterations,
//     this.kdfAlgorithm,
//     this.aeadAlgorithm,
//     this.nonceB64,
//     this.version,
//   });

//   factory MasterKeyMeta.fromJson(Map<String, dynamic> json) {
//     return MasterKeyMeta(
//       hasMasterKey: json['has_master_key'] as bool? ?? false,
//       encryptedMasterKeyHex: json['encrypted_master_key_hex'] as String?,
//       kdfSaltB64: json['kdf_salt_b64'] as String?,
//       kdfIterations: json['kdf_iterations'] as int?,
//       kdfAlgorithm: json['kdf_algorithm'] as String?,
//       aeadAlgorithm: json['aead_algorithm'] as String?,
//       nonceB64: json['nonce_b64'] as String?,
//       version: json['version'] as int?,
//     );
//   }
// }

// /// Utility: random bytes.
// Uint8List randomBytes(int length) {
//   final rnd = Random.secure();
//   final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
//   return Uint8List.fromList(bytes);
// }

// /// Hex encoding helpers
// String bytesToHex(Uint8List bytes) {
//   final buf = StringBuffer();
//   for (final b in bytes) {
//     buf.write(b.toRadixString(16).padLeft(2, '0'));
//   }
//   return buf.toString();
// }

// Uint8List hexToBytes(String hex) {
//   final result = <int>[];
//   for (var i = 0; i < hex.length; i += 2) {
//     result.add(int.parse(hex.substring(i, i + 2), radix: 16));
//   }
//   return Uint8List.fromList(result);
// }

// /// KDF: derive KEK from password using PBKDF2-HMAC-SHA256.
// /// For v1 we only use password; later we can switch to (password + PIN) here.
// Future<SecretKey> deriveKekFromPassword({
//   required String password,
//   required Uint8List salt,
//   required int iterations,
// }) async {
//   final pbkdf2 = Pbkdf2(
//     macAlgorithm: Hmac.sha256(),
//     iterations: iterations,
//     bits: 256,
//   );
//   return pbkdf2.deriveKey(
//     secretKey: SecretKey(utf8.encode(password)),
//     nonce: salt,
//   );
// }

// /// Encrypt a 32-byte master key with XChaCha20-Poly1305
// Future<Map<String, String>> encryptMasterKey({
//   required Uint8List masterKeyBytes,
//   required String password,
//   int iterations = 150000,
// }) async {
//   // 1) Generate random salt for KDF
//   final salt = randomBytes(16);

//   // 2) Derive KEK
//   final kek = await deriveKekFromPassword(
//     password: password,
//     salt: salt,
//     iterations: iterations,
//   );

//   // 3) Encrypt master key using XChaCha20-Poly1305
//   final alg = Xchacha20.poly1305Aead();
//   final nonce = await alg.newNonce(); // 24 bytes

//   final secretBox = await alg.encrypt(
//     masterKeyBytes,
//     secretKey: kek,
//     nonce: nonce,
//   );

//   // ciphertext + MAC in one field, encoded as hex
//   final cipherAndTag = Uint8List.fromList(
//     [...secretBox.cipherText, ...secretBox.mac.bytes],
//   );

//   return {
//     'encrypted_master_key_hex': bytesToHex(cipherAndTag),
//     'kdf_salt_b64': base64Encode(salt),
//     'kdf_iterations': iterations.toString(),
//     'kdf_algorithm': 'pbkdf2-hmac-sha256',
//     'aead_algorithm': 'xchacha20-poly1305',
//     'nonce_b64': base64Encode(nonce),
//   };
// }

// /// Decrypt master key using password + metadata from server.
// Future<Uint8List> decryptMasterKey({
//   required String password,
//   required MasterKeyMeta meta,
// }) async {
//   if (meta.encryptedMasterKeyHex == null ||
//       meta.kdfSaltB64 == null ||
//       meta.nonceB64 == null ||
//       meta.kdfIterations == null) {
//     throw Exception("Incomplete master key metadata");
//   }

//   final salt = base64Decode(meta.kdfSaltB64!);
//   final nonce = base64Decode(meta.nonceB64!);
//   final iterations = meta.kdfIterations!;
//   final algName = meta.aeadAlgorithm ?? 'xchacha20-poly1305';

//   if (algName != 'xchacha20-poly1305') {
//     throw Exception("Unsupported AEAD algorithm: $algName");
//   }

//   final cipherAndTag = hexToBytes(meta.encryptedMasterKeyHex!);

//   if (cipherAndTag.length < 16) {
//     throw Exception("Invalid encrypted master key length");
//   }

//   final cipherLen = cipherAndTag.length - 16;
//   final cipherText = cipherAndTag.sublist(0, cipherLen);
//   final macBytes = cipherAndTag.sublist(cipherLen);
//   final mac = Mac(macBytes);

//   final kek = await deriveKekFromPassword(
//     password: password,
//     salt: salt,
//     iterations: iterations,
//   );

//   final alg = Xchacha20.poly1305Aead();
//   final secretBox = SecretBox(
//     cipherText,
//     nonce: nonce,
//     mac: mac,
//   );

//   final clearBytes = await alg.decrypt(
//     secretBox,
//     secretKey: kek,
//   );

//   return Uint8List.fromList(clearBytes);
// }

// ----------------------------------------------------------------------------


// lib/crypto/master_key.dart

// import 'dart:convert';
// import 'dart:math';

// import 'package:cryptography/cryptography.dart';

// /// Holds everything we need about the user's master key.
// class MasterKeyBundle {
//   /// Raw 32-byte master key (kept only in memory on the client)
//   final List<int> masterKey;

//   /// Hex-encoded encrypted blob (ciphertext + MAC)
//   final String encryptedMasterKeyHex;

//   /// Base64 salt used for KDF
//   final String kdfSaltB64;

//   /// Which KDF we used (for future migrations)
//   final String kdfAlgorithm;

//   /// KDF iterations (PBKDF2)
//   final int kdfIterations;

//   /// AEAD algorithm name (we use xchacha20-poly1305)
//   final String aeadAlgorithm;

//   /// Base64 nonce for AEAD
//   final String nonceB64;

//   /// Version of the format
//   final int version;

//   MasterKeyBundle({
//     required this.masterKey,
//     required this.encryptedMasterKeyHex,
//     required this.kdfSaltB64,
//     required this.kdfAlgorithm,
//     required this.kdfIterations,
//     required this.aeadAlgorithm,
//     required this.nonceB64,
//     required this.version,
//   });

//   /// Generate a brand new master key and encrypt it under a KEK derived
//   /// from the user's password using PBKDF2-HMAC-SHA256.
//   static Future<MasterKeyBundle> createForPassword({
//     required String password,
//     int kdfIterations = 150000,
//     String kdfAlgorithm = "pbkdf2-hmac-sha256",
//     String aeadAlgorithm = "xchacha20-poly1305",
//   }) async {
//     if (password.isEmpty) {
//       throw ArgumentError("Password cannot be empty when deriving KEK");
//     }

//     // 1) Generate random 32-byte master key
//     final rng = Random.secure();
//     final masterKey = List<int>.generate(32, (_) => rng.nextInt(256));

//     // 2) Generate random salt for KDF (16 bytes is enough)
//     final kdfSaltBytes = List<int>.generate(16, (_) => rng.nextInt(256));
//     final kdfSaltB64 = base64Encode(kdfSaltBytes);

//     // 3) Derive KEK from password using PBKDF2-HMAC-SHA256
//     final pbkdf2 = Pbkdf2(
//       macAlgorithm: Hmac.sha256(),
//       iterations: kdfIterations,
//       bits: 256, // 256-bit key
//     );

//     final kekSecretKey = await pbkdf2.deriveKey(
//       secretKey: SecretKey(utf8.encode(password)),
//       // cryptography uses `nonce` param as salt for PBKDF2
//       nonce: kdfSaltBytes,
//     );

//     // 4) Encrypt master key with XChaCha20-Poly1305
//     final aead = Xchacha20.poly1305Aead();
//     final secretBox = await aead.encrypt(
//       masterKey,
//       secretKey: kekSecretKey,
//     );

//     // We pack ciphertext + MAC into a single hex blob
//     final combinedBytes = <int>[
//       ...secretBox.cipherText,
//       ...secretBox.mac.bytes,
//     ];
//     final encryptedHex = _bytesToHex(combinedBytes);
//     final nonceB64 = base64Encode(secretBox.nonce);

//     return MasterKeyBundle(
//       masterKey: masterKey,
//       encryptedMasterKeyHex: encryptedHex,
//       kdfSaltB64: kdfSaltB64,
//       kdfAlgorithm: kdfAlgorithm,
//       kdfIterations: kdfIterations,
//       aeadAlgorithm: aeadAlgorithm,
//       nonceB64: nonceB64,
//       version: 1,
//     );
//   }

//   /// Decrypt an existing master key blob using the user's password and metadata.
//   static Future<List<int>> decryptFromPassword({
//     required String password,
//     required String encryptedMasterKeyHex,
//     required String kdfSaltB64,
//     required int kdfIterations,
//     required String kdfAlgorithm, // currently assumed pbkdf2-hmac-sha256
//     required String nonceB64,
//     String aeadAlgorithm = "xchacha20-poly1305",
//   }) async {
//     if (password.isEmpty) {
//       throw ArgumentError("Password cannot be empty when deriving KEK");
//     }

//     // 1) Rebuild salt
//     final kdfSaltBytes = base64Decode(kdfSaltB64);

//     // 2) Re-derive KEK using same KDF parameters
//     if (kdfAlgorithm != "pbkdf2-hmac-sha256") {
//       throw UnsupportedError(
//         "Unsupported KDF: $kdfAlgorithm (expected pbkdf2-hmac-sha256)",
//       );
//     }

//     final pbkdf2 = Pbkdf2(
//       macAlgorithm: Hmac.sha256(),
//       iterations: kdfIterations,
//       bits: 256,
//     );

//     final kekSecretKey = await pbkdf2.deriveKey(
//       secretKey: SecretKey(utf8.encode(password)),
//       nonce: kdfSaltBytes,
//     );

//     // 3) Decode encrypted blob (ciphertext + MAC)
//     final allBytes = _hexToBytes(encryptedMasterKeyHex);
//     if (allBytes.length <= 16) {
//       throw StateError("Encrypted master key blob too small");
//     }
//     final cipherBytes = allBytes.sublist(0, allBytes.length - 16);
//     final macBytes = allBytes.sublist(allBytes.length - 16);

//     final nonce = base64Decode(nonceB64);

//     if (aeadAlgorithm != "xchacha20-poly1305") {
//       throw UnsupportedError(
//         "Unsupported AEAD: $aeadAlgorithm (expected xchacha20-poly1305)",
//       );
//     }

//     // 4) AEAD decrypt
//     final aead = Xchacha20.poly1305Aead();
//     final secretBox = SecretBox(
//       cipherBytes,
//       nonce: nonce,
//       mac: Mac(macBytes),
//     );

//     final plaintext = await aead.decrypt(
//       secretBox,
//       secretKey: kekSecretKey,
//     );

//     if (plaintext.length != 32) {
//       throw StateError(
//         "Unexpected master key length: ${plaintext.length} (expected 32)",
//       );
//     }

//     return plaintext;
//   }

//   // ---------- Helpers ----------

//   static String _bytesToHex(List<int> bytes) {
//     final sb = StringBuffer();
//     for (final b in bytes) {
//       sb.write(b.toRadixString(16).padLeft(2, '0'));
//     }
//     return sb.toString();
//   }

//   static List<int> _hexToBytes(String hex) {
//     if (hex.length.isOdd) {
//       throw FormatException("Invalid hex string, length must be even");
//     }
//     final result = <int>[];
//     for (var i = 0; i < hex.length; i += 2) {
//       final byteStr = hex.substring(i, i + 2);
//       result.add(int.parse(byteStr, radix: 16));
//     }
//     return result;
//   }
// }


// ---------------------------still needs refactor-------------------------
// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:silvora_app/crypto/file_key.dart';
// import '../state/secure_state.dart';
// import '../crypto/argon2.dart';
// import '../crypto/master_key.dart';
// import '../storage/key_cache.dart';

// class VaultService {
//   static const passwordTTL = Duration(days: 2);

//   /// Login flow (password required)
//   static Future<void> unlockWithPassword({
//     required String password,
//     required Uint8List encryptedMasterKey,
//     required Uint8List salt,
//   }) async {
//     final pwdKey = await argon2DeriveKey(password, salt);
//     final masterKey = decryptMasterKey(
//       encrypted: encryptedMasterKey,
//       key: pwdKey,
//     );

//     SecureState.setMasterKey(masterKey);
//     await KeyCache.store(masterKey); // biometric-sealed
//   }

//   /// Auto-unlock using biometrics
//   static Future<bool> tryBiometricUnlock() async {
//     try {
//       final cached = await KeyCache.retrieve();
//       if (cached == null) return false;

//       SecureState.setMasterKey(cached);
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   static bool needsPassword() {
//     return SecureState.requiresPasswordReauth(passwordTTL);
//   }

//   static void lock() {
//     SecureState.lock();
//   }
// }

// -==================================================================================-
// // lib/crypto/master_key.dart
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// Future<Uint8List> decryptMasterKey({
//   required Uint8List encrypted,
//   required Uint8List key,
// }) async {
//   final algo = Xchacha20.poly1305Aead();

//   final nonce = encrypted.sublist(0, 24);
//   final mac = encrypted.sublist(encrypted.length - 16);
//   final cipher = encrypted.sublist(24, encrypted.length - 16);

//   final box = SecretBox(
//     cipher,
//     nonce: nonce,
//     mac: Mac(mac),
//   );

//   final plain = await algo.decrypt(
//     box,
//     secretKey: SecretKey(key),
//   );

//   return Uint8List.fromList(plain);
// }
// ========================================================================
// lib/crypto/master_key.dart
// import 'dart:typed_data';
// import 'dart:math';

// import 'argon2.dart';
// import 'xchacha.dart';

// class MasterKeyCrypto {
//   static final _crypto = XChaCha();

//   static Uint8List generateMasterKey() {
//     final rand = Random.secure();
//     return Uint8List.fromList(
//       List.generate(32, (_) => rand.nextInt(256)),
//     );
//   }

//   static Future<Uint8List> encryptMasterKey({
//     required Uint8List masterKey,
//     required String password,
//     required Uint8List salt,
//   }) async {
//     final kek = await argon2DeriveKey(
//       password: password,
//       salt: salt,
//     );

//     final nonce = await _crypto.randomNonce();

//     final cipher = await _crypto.encrypt(
//       plaintext: masterKey,
//       key: kek,
//       nonce: nonce,
//     );

//     return Uint8List.fromList([
//       ...nonce,
//       ...cipher,
//     ]);
//   }

//   static Future<Uint8List> decryptMasterKey({
//     required Uint8List encrypted,
//     required String password,
//     required Uint8List salt,
//   }) async {
//     final kek = await argon2DeriveKey(
//       password: password,
//       salt: salt,
//     );

//     final nonce = encrypted.sublist(0, 24);
//     final cipher = encrypted.sublist(24, encrypted.length - 16);
//     final mac = encrypted.sublist(encrypted.length - 16);

//     return _crypto.decrypt(
//       ciphertext: cipher,
//       nonce: nonce,
//       mac: mac,
//       key: kek,
//     );
//   }
// }
// // ============================================================================
// // lib/crypto/master_key.dart
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';
// import 'argon2.dart';
// import 'xchacha.dart';

// class MasterKeyCrypto {
//   static final _cipher = XChaCha();

//   /// Generate new master key
//   static Uint8List generate() {
//     return Uint8List(32)
//       ..setAll(0, List<int>.generate(32, (_) => DateTime.now().millisecond % 256));
//   }

//   /// Encrypt master key using password-derived key
//   static Future<Uint8List> encrypt({
//     required Uint8List masterKey,
//     required String password,
//     required Uint8List salt,
//   }) async {
//     final pwdKey = await Argon2Kdf.deriveKey(
//       password: password,
//       salt: salt,
//     );

//     final nonce = await _cipher.randomNonce();
//     final box = await _cipher.encrypt(
//       plaintext: masterKey,
//       key: pwdKey,
//       nonce: nonce,
//     );

//     // nonce || ciphertext || mac
//     return Uint8List.fromList([
//       ...nonce,
//       ...box.cipherText,
//       ...box.mac.bytes,
//     ]);
//   }

//   /// Decrypt master key
//   static Future<Uint8List> decrypt({
//     required Uint8List encrypted,
//     required String password,
//     required Uint8List salt,
//   }) async {
//     final pwdKey = await Argon2Kdf.deriveKey(
//       password: password,
//       salt: salt,
//     );

//     final nonce = encrypted.sublist(0, 24);
//     final mac = encrypted.sublist(encrypted.length - 16);
//     final cipher = encrypted.sublist(24, encrypted.length - 16);

//     return _cipher.decrypt(
//       ciphertext: cipher,
//       key: pwdKey,
//       nonce: nonce,
//       mac: mac,
//     );
//   }
// }
// ----------------------------------------------------------------------------
// import 'dart:typed_data';

// import '../state/secure_state.dart';
// import '../crypto/master_key.dart';

// /// VaultService
// /// --------------
// /// - Unlocks master key after login
// /// - Enforces password re-auth TTL
// /// - NEVER stores keys on disk
// class VaultService {
//   static const Duration passwordTTL = Duration(days: 2);

//   /// 🔐 Unlock vault using user password
//   static Future<void> unlockWithPassword(String password) async {
//     // If still valid, skip re-derivation
//     if (!SecureState.requiresPasswordReauth(passwordTTL)) {
//       return;
//     }

//     // Derive master key (PBKDF2 / Argon2 / HKDF handled here)
//     final Uint8List masterKey =
//         await MasterKey.deriveFromPassword(password);

//     // Store ONLY in memory
//     SecureState.setMasterKey(masterKey);
//   }

//   /// 🔒 Force lock vault (logout / app background)
//   static void lock() {
//     SecureState.lock();
//   }

//   /// 🧠 Convenience getter (throws if locked)
//   static Uint8List get masterKey {
//     return SecureState.requireMasterKey();
//   }
// }
// ----------------------------------------------------------------------------
// // lib/crypto/master_key.dart
// import 'dart:typed_data';
// import 'package:cryptography/cryptography.dart';

// /// MasterKey
// /// ---------
// /// Derives a 32-byte master key from a password.
// /// This key NEVER leaves memory.
// class MasterKey {
//   static final _kdf = Pbkdf2(
//     macAlgorithm: Hmac.sha256(),
//     iterations: 150000,
//     bits: 256,
//   );

//   /// TEMP salt (MVP only)
//   /// Later: fetched from backend envelope
//   static final Uint8List _salt = Uint8List.fromList(
//     List<int>.generate(16, (i) => i + 1),
//   );

//   static Future<Uint8List> deriveFromPassword(String password) async {
//     final secretKey = await _kdf.deriveKey(
//       secretKey: SecretKey(password.codeUnits),
//       nonce: _salt,
//     );

//     final bytes = await secretKey.extractBytes();
//     return Uint8List.fromList(bytes);
//   }
// }
// ----------------------------------------------------------------------------
// lib/crypto/master_key.dart
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// MasterKey
/// ---------
/// Derives a 32-byte master key from a password.
/// This key NEVER leaves memory.
class MasterKey {
  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 150000,
    bits: 256,
  );  
  /// TEMP salt (MVP only)
  /// Later: fetched from backend envelope
  static final Uint8List _salt = Uint8List.fromList(
    List<int>.generate(16, (i) => i + 1),
  );    

  static Future<Uint8List> deriveFromPassword(String password) async {
    final secretKey = await _kdf.deriveKey(
      secretKey: SecretKey(password.codeUnits),
      nonce: _salt,
    );

    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

}
// ----------------------------------------------------------------------------
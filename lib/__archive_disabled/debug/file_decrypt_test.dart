// // lib/crypto/file_decrypt_test.dart
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:crypto/crypto.dart';

// import '../../state/secure_state.dart';
// import '../../services/api_services.dart';
// import '../crypto/file_decryptor.dart';

// Future<void> runFileDecryptTest(String fileId) async {
//   print("🔍 Starting file decrypt test");

//   final manifest = await ApiService.fetchManifest(fileId);
//   final encrypted = await ApiService.fetchEncryptedData(fileId);

//   final masterKey = SecureState.requireMasterKey();

//   final decryptor = FileDecryptor(
//     masterKey: masterKey,
//     manifest: manifest,
//   );

//   final plain = await decryptor.decrypt(encrypted);

//   final hash = sha256.convert(plain).toString();

//   print("✅ Decrypted size: ${plain.length}");
  

//   print("🔐 SHA256(decrypted): $hash");
// }

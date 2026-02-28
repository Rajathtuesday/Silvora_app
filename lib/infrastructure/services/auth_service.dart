import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';

import '../../state/secure_state.dart';
import '../../crypto/master_key_provider.dart';
import '../../crypto/master_key_crypto.dart';
import '../storage/jwt_store.dart';

class AuthService {
  static Future<void> login({
    required String email,
    required String password,
  }) async {

    // ------------------------------------------------
    // 1️⃣ Obtain JWT
    // ------------------------------------------------
    final tokenResp = await http.post(
      Uri.parse("${SecureState.serverBaseUrl}/api/auth/token/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": email,
        "password": password,
      }),
    );

    if (tokenResp.statusCode != 200) {
      throw Exception("Invalid credentials");
    }

    final tokenData = jsonDecode(tokenResp.body);

    final String? access = tokenData["access"];
    final String? refresh = tokenData["refresh"];

    if (access == null || refresh == null) {
      throw Exception("Token response missing fields");
    }

    await JwtStore.instance.saveTokens(access, refresh);
    SecureState.accessToken = access;
    SecureState.refreshToken = refresh;

    // ------------------------------------------------
    // 2️⃣ Fetch Master Key Envelope
    // ------------------------------------------------
    final metaResp = await http.get(
      Uri.parse("${SecureState.serverBaseUrl}/api/auth/master-key"),
      headers: {
        "Authorization": "Bearer $access",
      },
    );

    if (metaResp.statusCode != 200) {
      throw Exception("Failed to fetch master key metadata");
    }

    final meta = jsonDecode(metaResp.body);
    print("META RESPONSE: $meta");

    final String? encryptedHex = meta["encrypted_master_key_hex"];
    final String? saltHex = meta["kdf_salt_hex"];
    final String? nonceHex = meta["nonce_hex"];

    if (encryptedHex == null || saltHex == null || nonceHex == null) {
      throw Exception("Master key metadata incomplete");
    }

    // ------------------------------------------------
    // 3️⃣ Decode HEX → bytes
    // ------------------------------------------------
    final Uint8List salt =
        Uint8List.fromList(hex.decode(saltHex));

    final Uint8List nonce =
        Uint8List.fromList(hex.decode(nonceHex));

    final Uint8List cipherBytes =
        Uint8List.fromList(hex.decode(encryptedHex));

    // Basic structural validation
    if (nonce.length != 24) {
      throw Exception("Invalid nonce length");
    }

    if (cipherBytes.length < 48) {
      throw Exception("Encrypted master key corrupted");
    }

    // ------------------------------------------------
    // 4️⃣ Derive KEK (Argon2id)
    // ------------------------------------------------
    final Uint8List kek = await MasterKeyProvider.derive(
      password: password,
      salt: salt,
    );

    // ------------------------------------------------
    // 5️⃣ Decrypt Master Key (XChaCha20-Poly1305)
    // ------------------------------------------------
    final Uint8List masterKey =
        await MasterKeyCrypto.decrypt(
      cipherText: cipherBytes,
      kek: kek,
      nonce: nonce,
    );

    if (masterKey.length != 32) {
      throw Exception("Master key integrity failure");
    }

    // ------------------------------------------------
    // 6️⃣ Unlock Vault
    // ------------------------------------------------
    await SecureState.unlockWithMasterKey(masterKey);

    if (!SecureState.isSessionReady) {
      throw Exception("Vault unlock failed");
    }
  }
}
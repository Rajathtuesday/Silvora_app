
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
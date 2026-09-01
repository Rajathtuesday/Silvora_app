import 'dart:convert';
import 'dart:typed_data';

import 'hkdf.dart';

/// Login-auth crypto: proves possession of the password to the server
/// without the server ever seeing (or being able to replay-derive from) the
/// password itself.
///
/// password -> Argon2(password, salt) = KEK       (wraps the master key, stays on-device)
///          -> HKDF(KEK, "login-auth") = Login-auth-key (this is what the server sees/stores)
///
/// One-way from the KEK (HKDF), so a captured login-auth-key -- via a
/// compromised server, a logged request body, a MITM'd endpoint -- can
/// never be used to reconstruct the KEK and unwrap the vault. Mirrors
/// RecoveryCrypto.deriveAuthKey exactly, same reasoning, different label.
class LoginAuthCrypto {
  static Future<Uint8List> deriveLoginAuthKey(Uint8List kek) =>
      hkdfSha256(ikm: kek, info: utf8.encode("silvora-login-auth"));
}

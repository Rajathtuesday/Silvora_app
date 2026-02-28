import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/argon2.dart';

void main() {
  test('Argon2 derives same key for same password + salt', () async {
    final salt = Uint8List.fromList(List.filled(16, 1));

    final k1 = await Argon2Kdf.deriveKey(
      password: 'password123',
      salt: salt,
    );

    final k2 = await Argon2Kdf.deriveKey(
      password: 'password123',
      salt: salt,
    );

    expect(k1, equals(k2));
    expect(k1.length, 32);
  });

  test('Argon2 changes output when salt changes', () async {
    final k1 = await Argon2Kdf.deriveKey(
      password: 'password123',
      salt: Uint8List.fromList(List.filled(16, 1)),
    );

    final k2 = await Argon2Kdf.deriveKey(
      password: 'password123',
      salt: Uint8List.fromList(List.filled(16, 2)),
    );

    expect(k1, isNot(equals(k2)));
  });

  test('Empty password throws', () async {
    expect(
      () => Argon2Kdf.deriveKey(
        password: '',
        salt: Uint8List.fromList([1, 2, 3]),
      ),
      throwsArgumentError,
    );
  });
}

  import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/crypto/hkdf.dart';

void main() {
  test('HKDF produces deterministic output', () async {
    final ikm = Uint8List.fromList(List.generate(32, (i) => i));
    final info = Uint8List.fromList([1, 2, 3]);

    final k1 = await hkdfSha256(
      ikm: ikm,
      info: info,
      length: 32,
    );

    final k2 = await hkdfSha256(
      ikm: ikm,
      info: info,
      length: 32,
    );

    expect(k1, equals(k2));
  });

  test('HKDF respects output length', () async {
    final key = await hkdfSha256(
      ikm: Uint8List.fromList(List.filled(32, 9)),
      info: Uint8List.fromList([9]),
      length: 16,
    );

    expect(key.length, 16);
  });

  test('Different info produces different keys', () async {
    final ikm = Uint8List.fromList(List.filled(32, 1));

    final k1 = await hkdfSha256(
      ikm: ikm,
      info: Uint8List.fromList([1]),
      length: 32,
    );

    final k2 = await hkdfSha256(
      ikm: ikm,
      info: Uint8List.fromList([2]),
      length: 32,
    );

    expect(k1, isNot(equals(k2)));
  });
}

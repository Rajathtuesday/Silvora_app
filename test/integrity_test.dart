import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:silvora_app/services/integrity_service.dart';
import 'package:silvora_app/crypto/file_decryptor.dart';

/// Routes getTemporaryPath() to a real temp dir so FileDecryptor can stream
/// output during unit tests (no Android plugin available in the test VM).
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async =>
      Directory.systemTemp.createTempSync('silvora_itg').path;
}

/// Encrypt one plaintext chunk the way upload does: XChaCha20-Poly1305 with a
/// fresh nonce, wrapped in the self-describing {n,c,m} envelope.
Future<Uint8List> _makeChunkEnvelope(List<int> plain, SecretKey key) async {
  final algo = Xchacha20.poly1305Aead();
  final nonce = await algo.newNonce();
  final box = await algo.encrypt(plain, secretKey: key, nonce: nonce);
  final env = jsonEncode({
    "n": base64Encode(nonce),
    "c": base64Encode(box.cipherText),
    "m": base64Encode(box.mac.bytes),
  });
  return Uint8List.fromList(utf8.encode(env));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProvider();

  group('Integrity hashing', () {
    test('hashChunk matches the SHA-256 known-answer for "hello"', () async {
      final h = await IntegrityService.hashChunk(utf8.encode("hello"));
      expect(
        h,
        equals("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"),
      );
    });

    test('hashChunk is deterministic and order-sensitive', () async {
      final a = await IntegrityService.hashChunk(utf8.encode("chunk-A"));
      final a2 = await IntegrityService.hashChunk(utf8.encode("chunk-A"));
      final b = await IntegrityService.hashChunk(utf8.encode("chunk-B"));
      expect(a, equals(a2));
      expect(a, isNot(equals(b)));
    });
  });

  group('Integrity manifest envelope round-trip', () {
    test('encrypt then decrypt recovers the manifest (AEAD wire format)', () async {
      // Mirror the buildAndUpload / fetch wire format with an explicit key.
      final key = Uint8List.fromList(List.generate(32, (i) => (i * 7) % 256));
      final manifest = {
        "v": 1,
        "file_id": "abc",
        "total_chunks": 2,
        "total_plain_size": 33,
        "chunks": [
          {"i": 0, "h": "aa"},
          {"i": 1, "h": "bb"},
        ],
      };

      final algo = Xchacha20.poly1305Aead();
      final nonce = await algo.newNonce();
      final box = await algo.encrypt(
        utf8.encode(jsonEncode(manifest)),
        secretKey: SecretKey(key),
        nonce: nonce,
      );

      final recovered = await algo.decrypt(
        SecretBox(box.cipherText, nonce: nonce, mac: box.mac),
        secretKey: SecretKey(key),
      );
      final parsed = jsonDecode(utf8.decode(recovered)) as Map<String, dynamic>;
      expect(parsed["total_chunks"], equals(2));
      expect((parsed["chunks"] as List).length, equals(2));
    });

    test('a tampered manifest ciphertext fails authentication', () async {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final algo = Xchacha20.poly1305Aead();
      final nonce = await algo.newNonce();
      final box = await algo.encrypt(
        utf8.encode('{"v":1}'),
        secretKey: SecretKey(key),
        nonce: nonce,
      );
      final flipped = Uint8List.fromList(box.cipherText);
      flipped[0] ^= 0xFF; // tamper one byte

      expect(
        () async => algo.decrypt(
          SecretBox(flipped, nonce: nonce, mac: box.mac),
          secretKey: SecretKey(key),
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });

  group('FileDecryptor integrity verification', () {
    final key = SecretKey(Uint8List.fromList(List.generate(32, (i) => 200 - i)));
    final c0 = utf8.encode("the first chunk of bytes");
    final c1 = utf8.encode("the second chunk of bytes!!");

    Future<Map<int, Uint8List>> envelopes() async => {
          0: await _makeChunkEnvelope(c0, key),
          1: await _makeChunkEnvelope(c1, key),
        };

    test('passes with correct hashes and reassembles the plaintext', () async {
      final envs = await envelopes();
      final hashes = {
        0: await IntegrityService.hashChunk(c0),
        1: await IntegrityService.hashChunk(c1),
      };

      final file = await FileDecryptor.decryptFile(
        chunksMeta: [
          {"index": 0},
          {"index": 1},
        ],
        secretKey: key,
        filename: "out_ok.bin",
        expectedHashes: hashes,
        fetchChunk: (i) async => envs[i]!,
      );

      expect(await file.readAsBytes(), equals(Uint8List.fromList([...c0, ...c1])));
    });

    test('fails when a chunk hash does not match (tamper/substitution)', () async {
      final envs = await envelopes();
      final hashes = {
        0: await IntegrityService.hashChunk(c0),
        1: "deadbeef" * 8, // wrong signed hash for chunk 1
      };

      expect(
        () async => FileDecryptor.decryptFile(
          chunksMeta: [
            {"index": 0},
            {"index": 1},
          ],
          secretKey: key,
          filename: "out_tamper.bin",
          expectedHashes: hashes,
          fetchChunk: (i) async => envs[i]!,
        ),
        throwsA(predicate((e) => e.toString().contains("Integrity check failed"))),
      );
    });

    test('fails when chunk count does not match the manifest (truncation)', () async {
      final envs = await envelopes();
      final hashes = {0: await IntegrityService.hashChunk(c0)}; // signed 1, server offers 2

      expect(
        () async => FileDecryptor.decryptFile(
          chunksMeta: [
            {"index": 0},
            {"index": 1},
          ],
          secretKey: key,
          filename: "out_trunc.bin",
          expectedHashes: hashes,
          fetchChunk: (i) async => envs[i]!,
        ),
        throwsA(predicate((e) => e.toString().contains("Integrity check failed"))),
      );
    });

    test('legacy file (null hashes) still decrypts without verification', () async {
      final envs = await envelopes();
      final file = await FileDecryptor.decryptFile(
        chunksMeta: [
          {"index": 0},
          {"index": 1},
        ],
        secretKey: key,
        filename: "out_legacy.bin",
        expectedHashes: null,
        fetchChunk: (i) async => envs[i]!,
      );
      expect(await file.readAsBytes(), equals(Uint8List.fromList([...c0, ...c1])));
    });
  });
}

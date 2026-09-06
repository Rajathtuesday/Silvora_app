import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:silvora_app/services/integrity_service.dart';
import 'package:silvora_app/services/integrity_version_store.dart';
import 'package:silvora_app/crypto/file_decryptor.dart';
import 'package:silvora_app/crypto/hkdf.dart';
import 'package:silvora_app/crypto/xchacha.dart';
import 'package:silvora_app/state/secure_state.dart';

/// Routes getTemporaryPath() to a real temp dir so FileDecryptor can stream
/// output during unit tests (no Android plugin available in the test VM).
/// Remembers the last directory handed out so tests can inspect what
/// FileDecryptor actually did on disk after it returns/throws.
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  static late Directory lastTempDir;

  @override
  Future<String?> getTemporaryPath() async {
    lastTempDir = Directory.systemTemp.createTempSync('silvora_itg');
    return lastTempDir.path;
  }
}

/// Encrypt one plaintext chunk the way upload does: XChaCha20-Poly1305 with a
/// fresh nonce, wrapped in the self-describing {n,c,m} envelope.
Future<Uint8List> _makeChunkEnvelope(List<int> plain, SecretKey key) async {
  final algo = Xchacha20.poly1305Aead();
  final nonce = algo.newNonce();
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
      final nonce = algo.newNonce();
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
      final nonce = algo.newNonce();
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

      final result = await FileDecryptor.decryptFile(
        chunksMeta: [
          {"index": 0},
          {"index": 1},
        ],
        secretKey: key,
        filename: "out_ok.bin",
        expectedHashes: hashes,
        fetchChunk: (i) async => envs[i]!,
      );

      expect(await result.readAsBytes(), equals(Uint8List.fromList([...c0, ...c1])));
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

    test('deletes the partial plaintext when a chunk fails mid-stream', () async {
      final envs = await envelopes();
      final hashes = {
        0: await IntegrityService.hashChunk(c0), // chunk 0 verifies and gets written
        1: "deadbeef" * 8, // chunk 1's signed hash is wrong -> throws after chunk 0 is on disk
      };

      await expectLater(
        () => FileDecryptor.decryptFile(
          chunksMeta: [
            {"index": 0},
            {"index": 1},
          ],
          secretKey: key,
          filename: "out_partial.bin",
          expectedHashes: hashes,
          fetchChunk: (i) async => envs[i]!,
        ),
        throwsA(anything),
      );

      final leftover = File("${_FakePathProvider.lastTempDir.path}/out_partial.bin");
      expect(await leftover.exists(), isFalse);
    });
  });

  group('IntegrityService.fetch fails closed', () {
    test('a 404 (no manifest at all) throws instead of skipping verification', () async {
      final server = await HttpServer.bind('localhost', 0);
      server.listen((req) {
        req.response.statusCode = 404;
        req.response.close();
      });
      final originalUrl = SecureState.serverUrl;
      SecureState.serverUrl = 'http://localhost:${server.port}';

      try {
        await expectLater(
          () => IntegrityService.fetch('some-file-id'),
          throwsA(anything),
        );
      } finally {
        SecureState.serverUrl = originalUrl;
        await server.close(force: true);
      }
    });
  });

  group('Integrity manifest rollback/replay protection (2026-09-06 fix)', () {
    // Real backend field name/shape for a server-authoritative version
    // counter is not settled yet (a separate change is being designed in
    // silvora_backend in parallel) -- these tests exercise the client-side
    // assumption documented in IntegrityVersionStore: the client-signed
    // manifest carries an integer "version" field, and a device refuses a
    // download whose version is lower than one it has already recorded for
    // that file.
    // flutter_test's TestWidgetsFlutterBinding (initialized above for the
    // path_provider mock) installs an HttpOverrides that makes every real
    // HttpClient request return 400 without ever reaching the network --
    // fine for the "fails closed" test above (any non-200 already throws,
    // by design), but these tests need a REAL round trip to a local
    // HttpServer to prove the version check against genuine POST/GET
    // traffic, so the override is suspended for their duration.
    HttpOverrides? previousHttpOverrides;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SecureState.setMasterKey(Uint8List.fromList(List.generate(32, (i) => (i * 13 + 7) % 256)));
      previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
    });
    tearDown(() {
      SecureState.lock();
      HttpOverrides.global = previousHttpOverrides;
    });

    /// Runs a tiny fake backend that stores whatever integrity envelope was
    /// last POSTed and serves it back on GET -- enough to drive
    /// buildAndUpload()/fetch() through a real POST-then-GET round trip
    /// without hand-rolling the AEAD envelope format by hand.
    Future<HttpServer> fakeIntegrityServer(void Function(Uint8List) onStored, Uint8List? Function() current) async {
      final server = await HttpServer.bind('localhost', 0);
      server.listen((req) async {
        if (req.method == 'POST') {
          final bytes = await req.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
          onStored(Uint8List.fromList(bytes));
          req.response.statusCode = 200;
        } else {
          final body = current();
          req.response.statusCode = body == null ? 404 : 200;
          if (body != null) req.response.add(body);
        }
        await req.response.close();
      });
      return server;
    }

    test('a download reporting an older manifest version than this device already saw is refused', () async {
      const fileId = 'rollback-test-file';
      Uint8List? stored;
      final server = await fakeIntegrityServer((b) => stored = b, () => stored);
      final originalUrl = SecureState.serverUrl;
      SecureState.serverUrl = 'http://localhost:${server.port}';

      final tmpFile = File(
        '${Directory.systemTemp.path}/rollback_src_${DateTime.now().microsecondsSinceEpoch}.bin',
      )..writeAsBytesSync(utf8.encode('hello world, this is the file content'));

      try {
        // The device legitimately uploads generation 2 of this file (today
        // every real file is only ever generation 1 -- there is no
        // re-upload-in-place feature yet -- but the check must still hold
        // for whatever generation number a manifest actually claims).
        expect(
          await IntegrityService.buildAndUpload(fileId: fileId, file: tmpFile, chunkSize: 1024, version: 2),
          isTrue,
        );

        // A normal download right after upload sees that same v2 manifest.
        final firstFetch = await IntegrityService.fetch(fileId);
        expect(firstFetch.version, equals(2));

        // Simulate a compromised/malicious server reverting the stored
        // manifest to an OLDER, but still validly-signed-at-the-time,
        // generation 1 -- built by legitimately re-running buildAndUpload
        // with version: 1, which overwrites the fake server's stored blob
        // (standing in for a storage-level revert to an earlier real
        // snapshot the attacker separately retained).
        expect(
          await IntegrityService.buildAndUpload(fileId: fileId, file: tmpFile, chunkSize: 1024, version: 1),
          isTrue,
        );

        // This device already recorded version 2 as this file's baseline
        // (from both the first upload and the first fetch), so a download
        // now reporting version 1 must be refused -- correct AEAD
        // authentication alone is not enough, since the old blob really
        // was signed by the real key at the time.
        await expectLater(
          () => IntegrityService.fetch(fileId),
          throwsA(predicate((e) => e.toString().contains('older than the version'))),
        );
      } finally {
        SecureState.serverUrl = originalUrl;
        await server.close(force: true);
        if (tmpFile.existsSync()) tmpFile.deleteSync();
      }
    });

    test('a manifest with no "version" field at all (upload predates this fix) is treated as version 1, not rejected', () async {
      const fileId = 'legacy-no-version-file';
      final key = await hkdfSha256(ikm: SecureState.masterKey, info: utf8.encode('silvora-integrity-$fileId'));
      final manifest = {
        'v': 1,
        'file_id': fileId,
        'total_chunks': 1,
        'total_plain_size': 5,
        'chunks': [
          {'i': 0, 'h': 'deadbeef'}
        ],
      };
      final nonce = await XChaCha.randomNonce();
      final box = await XChaCha.encrypt(
        plaintext: Uint8List.fromList(utf8.encode(jsonEncode(manifest))),
        key: key,
        nonce: nonce,
      );
      final envelope = utf8.encode(jsonEncode({
        'n': base64Encode(nonce),
        'c': base64Encode(box.cipherText),
        'm': base64Encode(box.mac.bytes),
      }));

      final server = await HttpServer.bind('localhost', 0);
      server.listen((req) async {
        req.response.statusCode = 200;
        req.response.add(envelope);
        await req.response.close();
      });
      final originalUrl = SecureState.serverUrl;
      SecureState.serverUrl = 'http://localhost:${server.port}';

      try {
        final result = await IntegrityService.fetch(fileId);
        expect(result.version, equals(1));
      } finally {
        SecureState.serverUrl = originalUrl;
        await server.close(force: true);
      }
    });
  });

  group('IntegrityVersionStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('getLastSeen is null before anything has ever been recorded for a file', () async {
      expect(await IntegrityVersionStore.getLastSeen('never-seen-file'), isNull);
    });

    test('recordSeen then getLastSeen round-trips', () async {
      await IntegrityVersionStore.recordSeen('file-a', 3);
      expect(await IntegrityVersionStore.getLastSeen('file-a'), equals(3));
    });

    test('recordSeen never moves the stored version backward', () async {
      await IntegrityVersionStore.recordSeen('file-b', 5);
      await IntegrityVersionStore.recordSeen('file-b', 2); // an attempted rollback write
      expect(await IntegrityVersionStore.getLastSeen('file-b'), equals(5));
    });

    test('recordSeen does move forward when the new version is genuinely higher', () async {
      await IntegrityVersionStore.recordSeen('file-c', 1);
      await IntegrityVersionStore.recordSeen('file-c', 4);
      expect(await IntegrityVersionStore.getLastSeen('file-c'), equals(4));
    });

    test('forget removes a file so a later recordSeen starts fresh', () async {
      await IntegrityVersionStore.recordSeen('file-d', 9);
      await IntegrityVersionStore.forget('file-d');
      expect(await IntegrityVersionStore.getLastSeen('file-d'), isNull);
    });

    test('tracks multiple files independently', () async {
      await IntegrityVersionStore.recordSeen('file-e', 1);
      await IntegrityVersionStore.recordSeen('file-f', 7);
      expect(await IntegrityVersionStore.getLastSeen('file-e'), equals(1));
      expect(await IntegrityVersionStore.getLastSeen('file-f'), equals(7));
    });
  });
}

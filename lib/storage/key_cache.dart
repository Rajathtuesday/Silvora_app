// lib/storage/key_cache.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyCache {
  static const _storage = FlutterSecureStorage();
  static const _key = "sealed_master_key";

  static Future<void> store(Uint8List key) async {
    await _storage.write(
      key: _key,
      value: base64Encode(key),
    );
  }

  static Future<Uint8List?> retrieve() async {
    final val = await _storage.read(key: _key);
    if (val == null) return null;
    return Uint8List.fromList(base64Decode(val));
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}

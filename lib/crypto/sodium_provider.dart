import 'package:sodium/sodium.dart';
import 'package:sodium_libs/sodium_libs.dart' as sodium_libs;

class SodiumProvider {
  static Sodium? _instance;

  static Future<Sodium> get instance async {
    if (_instance != null) return _instance!;

    _instance = await sodium_libs.SodiumInit.init();
    return _instance!;
  }
}

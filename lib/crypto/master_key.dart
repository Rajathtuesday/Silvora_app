import 'dart:math';
import 'dart:typed_data';

class MasterKey {
  /// Generates a random 256-bit master key using a secure random number generator.
  /// This is the root of the zero-knowledge hierarchy for a user's vault.
  static Uint8List generate() {
    final rand = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => rand.nextInt(256)),
    );
  }
}

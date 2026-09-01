import 'dart:typed_data';

/// Best-effort in-place wipe of sensitive key material right after its last
/// use, instead of leaving it for however long GC takes to reclaim it. Same
/// technique SecureState.lock() already uses on the long-lived master key,
/// extracted so any transient Uint8List (a KEK, a decrypted master key
/// local) can use it too.
void zeroize(Uint8List bytes) => bytes.fillRange(0, bytes.length, 0);

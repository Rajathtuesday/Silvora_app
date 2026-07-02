// lib/services/device_security_service.dart
import 'package:flutter/services.dart';

class DeviceSecurityStatus {
  final bool isRooted;
  final bool developerModeEnabled;

  const DeviceSecurityStatus({
    required this.isRooted,
    required this.developerModeEnabled,
  });

  bool get isCompromised => isRooted || developerModeEnabled;
}

class DeviceSecurityService {
  static const _channel = MethodChannel('silvora/device_security');

  /// Root and Developer Options/USB debugging checks happen natively
  /// (Android APIs, not something Dart can see directly). Heuristic, not
  /// foolproof -- a determined attacker who's already rooted a device can
  /// hide it from checks like this. This is a warning gate, not the only
  /// thing protecting the vault: the actual encryption never assumes the
  /// OS itself is trustworthy. Fails open (treats errors as "not
  /// compromised") deliberately -- a broken check must never lock a real
  /// user out of their own vault on an otherwise-clean device.
  static Future<DeviceSecurityStatus> check() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkDeviceSecurity');
      return DeviceSecurityStatus(
        isRooted: result?['isRooted'] == true,
        developerModeEnabled: result?['developerModeEnabled'] == true,
      );
    } catch (_) {
      return const DeviceSecurityStatus(isRooted: false, developerModeEnabled: false);
    }
  }
}

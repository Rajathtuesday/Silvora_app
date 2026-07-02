import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silvora_app/services/device_security_service.dart';

void main() {
  const channel = MethodChannel('silvora/device_security');
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('DeviceSecurityStatus', () {
    test('isCompromised is true if either flag is set', () {
      expect(const DeviceSecurityStatus(isRooted: true, developerModeEnabled: false).isCompromised, isTrue);
      expect(const DeviceSecurityStatus(isRooted: false, developerModeEnabled: true).isCompromised, isTrue);
      expect(const DeviceSecurityStatus(isRooted: true, developerModeEnabled: true).isCompromised, isTrue);
    });

    test('isCompromised is false only when both flags are clear', () {
      expect(const DeviceSecurityStatus(isRooted: false, developerModeEnabled: false).isCompromised, isFalse);
    });
  });

  group('DeviceSecurityService.check', () {
    test('passes through a clean result from the native side', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => {'isRooted': false, 'developerModeEnabled': false},
      );

      final status = await DeviceSecurityService.check();
      expect(status.isRooted, isFalse);
      expect(status.developerModeEnabled, isFalse);
    });

    test('passes through a compromised result from the native side', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => {'isRooted': true, 'developerModeEnabled': false},
      );

      final status = await DeviceSecurityService.check();
      expect(status.isRooted, isTrue);
      expect(status.isCompromised, isTrue);
    });

    test('fails open (not compromised) if the native channel throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'BOOM'),
      );

      final status = await DeviceSecurityService.check();
      expect(status.isCompromised, isFalse,
          reason: "a broken check must never lock a real user out of a clean device");
    });

    test('fails open if the native side returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => null,
      );

      final status = await DeviceSecurityService.check();
      expect(status.isCompromised, isFalse);
    });
  });
}

import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RaikoIdentity {
  const RaikoIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  final String deviceId;
  final String deviceName;
  final String platform;

  static const RaikoIdentity fallback = RaikoIdentity(
    deviceId: 'mobile-fallback',
    deviceName: 'RAIKO Mobile',
    platform: 'unknown',
  );

  static const String _deviceIdKey = 'raiko.identity.device_id';

  static Future<RaikoIdentity> resolve(SharedPreferences prefs) async {
    final deviceId = await _resolveDeviceId(prefs);
    final platform = _detectPlatform();
    final deviceName = await _detectDeviceName(platform);
    return RaikoIdentity(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
    );
  }

  static Future<String> _resolveDeviceId(SharedPreferences prefs) async {
    final stored = prefs.getString(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final generated = _generateDeviceId();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'mobile-$hex';
  }

  static String _detectPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static Future<String> _detectDeviceName(String platform) async {
    final plugin = DeviceInfoPlugin();
    try {
      switch (platform) {
        case 'android':
          final info = await plugin.androidInfo;
          final manufacturer = info.manufacturer.trim();
          final model = info.model.trim();
          final combined = '$manufacturer $model'.trim();
          return combined.isEmpty ? 'Android device' : combined;
        case 'ios':
          final info = await plugin.iosInfo;
          return info.name.isEmpty ? info.model : info.name;
        case 'macos':
          final info = await plugin.macOsInfo;
          return info.computerName.isEmpty ? 'Mac' : info.computerName;
        case 'windows':
          final info = await plugin.windowsInfo;
          return info.computerName.isEmpty ? 'Windows PC' : info.computerName;
        case 'linux':
          final info = await plugin.linuxInfo;
          return info.prettyName;
      }
    } catch (_) {
      // Fall through to default name.
    }
    return 'RAIKO Mobile';
  }
}

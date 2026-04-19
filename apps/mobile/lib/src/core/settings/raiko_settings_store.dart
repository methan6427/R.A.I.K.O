import 'package:shared_preferences/shared_preferences.dart';

import '../config/raiko_backend_config.dart';

class RaikoSettingsStore {
  RaikoSettingsStore._(this._prefs);

  factory RaikoSettingsStore.wrap(SharedPreferences prefs) =>
      RaikoSettingsStore._(prefs);

  factory RaikoSettingsStore.inMemory() => RaikoSettingsStore._(null);

  static const String _baseHttpKey = 'raiko.backend.base_http_url';
  static const String _websocketKey = 'raiko.backend.websocket_url';
  static const String _tokenKey = 'raiko.backend.auth_token';
  static const String _deviceNameKey = 'raiko.identity.device_name';

  final SharedPreferences? _prefs;

  RaikoBackendConfig load() {
    final prefs = _prefs;
    if (prefs == null) {
      return RaikoBackendConfig.defaults;
    }
    final base = prefs.getString(_baseHttpKey);
    final ws = prefs.getString(_websocketKey);
    final token = prefs.getString(_tokenKey);
    if (base == null && ws == null && token == null) {
      return RaikoBackendConfig.defaults;
    }
    return RaikoBackendConfig.defaults.copyWith(
      baseHttpUrl: base,
      websocketUrl: ws,
      authToken: token,
    );
  }

  String? loadDeviceName() => _prefs?.getString(_deviceNameKey);

  Future<void> saveDeviceName(String name) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (name.trim().isEmpty) {
      await prefs.remove(_deviceNameKey);
    } else {
      await prefs.setString(_deviceNameKey, name.trim());
    }
  }

  Future<void> save(RaikoBackendConfig config) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await Future.wait(<Future<void>>[
      prefs.setString(_baseHttpKey, config.baseHttpUrl),
      prefs.setString(_websocketKey, config.websocketUrl),
      prefs.setString(_tokenKey, config.authToken),
    ]);
  }
}

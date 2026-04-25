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
  static const String _porcupineAccessKeyKey = 'raiko.voice.porcupine_access_key';
  static const String _geminiApiKeyKey = 'raiko.voice.gemini_api_key';
  static const String _confirmBeforeExecuteKey = 'raiko.voice.confirm_before_execute';
  static const String _listeningTimeoutKey = 'raiko.voice.listening_timeout_seconds';

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

  String? get deviceName => loadDeviceName();

  Future<void> saveDeviceName(String name) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (name.trim().isEmpty) {
      await prefs.remove(_deviceNameKey);
    } else {
      await prefs.setString(_deviceNameKey, name.trim());
    }
  }

  String? get porcupineAccessKey => _prefs?.getString(_porcupineAccessKeyKey);

  Future<void> savePorcupineAccessKey(String key) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (key.trim().isEmpty) {
      await prefs.remove(_porcupineAccessKeyKey);
    } else {
      await prefs.setString(_porcupineAccessKeyKey, key.trim());
    }
  }

  String? get geminiApiKey => _prefs?.getString(_geminiApiKeyKey);

  Future<void> saveGeminiApiKey(String key) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (key.trim().isEmpty) {
      await prefs.remove(_geminiApiKeyKey);
    } else {
      await prefs.setString(_geminiApiKeyKey, key.trim());
    }
  }

  bool? get confirmBeforeExecute => _prefs?.getBool(_confirmBeforeExecuteKey);

  Future<void> saveConfirmBeforeExecute(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_confirmBeforeExecuteKey, value);
  }

  int? get listeningTimeoutSeconds =>
      _prefs?.getInt(_listeningTimeoutKey) ?? 10;

  Future<void> saveListeningTimeout(int seconds) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setInt(_listeningTimeoutKey, seconds);
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

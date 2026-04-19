import 'dart:convert';
import 'dart:io';

class DesktopSettings {
  const DesktopSettings({
    required this.backendUrl,
    required this.authToken,
    required this.deviceName,
    required this.agentName,
  });

  final String backendUrl;
  final String authToken;
  final String deviceName;
  final String agentName;

  static const DesktopSettings defaults = DesktopSettings(
    backendUrl: 'ws://127.0.0.1:8080/ws',
    authToken: '',
    deviceName: 'RAIKO Desktop',
    agentName: 'RAIKO Desktop Agent',
  );

  DesktopSettings copyWith({
    String? backendUrl,
    String? authToken,
    String? deviceName,
    String? agentName,
  }) {
    return DesktopSettings(
      backendUrl: backendUrl ?? this.backendUrl,
      authToken: authToken ?? this.authToken,
      deviceName: deviceName ?? this.deviceName,
      agentName: agentName ?? this.agentName,
    );
  }
}

class DesktopSettingsStore {
  static File _file() {
    final appData = Platform.environment['APPDATA'] ?? '.';
    final dir = Directory('$appData\\RAIKO Desktop');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File('${dir.path}\\settings.json');
  }

  static DesktopSettings load() {
    try {
      final file = _file();
      if (!file.existsSync()) return DesktopSettings.defaults;
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return DesktopSettings(
        backendUrl: map['backendUrl'] as String? ?? DesktopSettings.defaults.backendUrl,
        authToken: map['authToken'] as String? ?? DesktopSettings.defaults.authToken,
        deviceName: map['deviceName'] as String? ?? DesktopSettings.defaults.deviceName,
        agentName: map['agentName'] as String? ?? DesktopSettings.defaults.agentName,
      );
    } catch (_) {
      return DesktopSettings.defaults;
    }
  }

  static void save(DesktopSettings settings) {
    try {
      _file().writeAsStringSync(jsonEncode(<String, String>{
        'backendUrl': settings.backendUrl,
        'authToken': settings.authToken,
        'deviceName': settings.deviceName,
        'agentName': settings.agentName,
      }));
    } catch (_) {}
  }
}

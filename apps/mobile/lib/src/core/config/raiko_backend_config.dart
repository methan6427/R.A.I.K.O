class RaikoBackendConfig {
  const RaikoBackendConfig({
    required this.baseHttpUrl,
    required this.websocketUrl,
    required this.authToken,
  });

  static const RaikoBackendConfig defaults = RaikoBackendConfig(
    baseHttpUrl: String.fromEnvironment(
      'RAIKO_BASE_HTTP_URL',
      defaultValue: 'http://10.0.2.2:8080',
    ),
    websocketUrl: String.fromEnvironment(
      'RAIKO_WEBSOCKET_URL',
      defaultValue: 'ws://10.0.2.2:8080/ws',
    ),
    authToken: String.fromEnvironment(
      'RAIKO_AUTH_TOKEN',
      defaultValue: 'raiko-dev',
    ),
  );

  final String baseHttpUrl;
  final String websocketUrl;
  final String authToken;

  RaikoBackendConfig copyWith({
    String? baseHttpUrl,
    String? websocketUrl,
    String? authToken,
  }) {
    return RaikoBackendConfig(
      baseHttpUrl: _normalizeHttpUrl(baseHttpUrl ?? this.baseHttpUrl),
      websocketUrl: _normalizeWebsocketUrl(websocketUrl ?? this.websocketUrl),
      authToken: (authToken ?? this.authToken).trim(),
    );
  }

  static String _normalizeHttpUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return defaults.baseHttpUrl;
    }

    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static String _normalizeWebsocketUrl(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? defaults.websocketUrl : trimmed;
  }
}

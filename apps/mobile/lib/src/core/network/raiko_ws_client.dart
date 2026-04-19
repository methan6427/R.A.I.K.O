import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/raiko_backend_config.dart';
import 'raiko_api_client.dart';
import 'raiko_backend_models.dart';

class RaikoWsClient extends ChangeNotifier {
  RaikoWsClient({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.kind,
    RaikoBackendConfig? initialConfig,
    RaikoApiClient? apiClient,
  }) : _config = initialConfig ?? RaikoBackendConfig.defaults,
       _apiClient =
           apiClient ??
           RaikoApiClient(config: initialConfig ?? RaikoBackendConfig.defaults);

  final String deviceId;
  String deviceName;
  final String platform;
  final String kind;

  RaikoBackendConfig _config;
  final RaikoApiClient _apiClient;
  WebSocket? _socket;
  bool isConnecting = false;
  bool _isStarting = false;
  bool _disposed = false;
  bool _autoReconnect = true;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Completer<void>? _registrationCompleter;
  bool isConnected = false;
  String selectedAgentId = '';
  String? lastError;
  RaikoCommandResult? lastCommandResult;

  List<RaikoDeviceInfo> devices = const <RaikoDeviceInfo>[];
  List<RaikoAgentInfo> agents = const <RaikoAgentInfo>[];
  List<RaikoActivityInfo> activity = const <RaikoActivityInfo>[];
  List<RaikoCommandInfo> commands = const <RaikoCommandInfo>[];
  final List<String> logs = <String>[];

  String get baseHttpUrl => _config.baseHttpUrl;
  String get websocketUrl => _config.websocketUrl;
  String get authToken => _config.authToken;

  RaikoAgentInfo? get selectedAgent {
    for (final RaikoAgentInfo agent in agents) {
      if (agent.id == selectedAgentId) {
        return agent;
      }
    }

    return null;
  }

  Future<void> start() async {
    if (_isStarting) {
      return;
    }

    _isStarting = true;
    _autoReconnect = true;
    try {
      await connect(force: true);
      await loadOverview();
    } finally {
      _isStarting = false;
    }
  }

  Future<void> connect({String? url, bool force = false}) async {
    if (isConnecting) {
      return;
    }

    if (url != null && url.trim().isNotEmpty) {
      updateWebsocketUrl(url);
    }

    final existingSocket = _socket;
    if (existingSocket != null && !force) {
      return;
    }

    isConnecting = true;
    notifyListeners();

    try {
      if (existingSocket != null) {
        _socket = null;
        isConnected = false;
        await existingSocket.close();
      }

      final headers = authToken.trim().isEmpty
          ? null
          : <String, dynamic>{'x-raiko-token': authToken.trim()};
      final socket = await WebSocket.connect(websocketUrl, headers: headers);
      _socket = socket;
      isConnected = false;
      lastError = null;
      _registrationCompleter = Completer<void>();
      _log('Socket opened to $websocketUrl');

      socket.listen(
        _handleMessage,
        onDone: () {
          if (!identical(_socket, socket)) {
            return;
          }
          _completePendingRegistration(
            StateError(
              'Connection closed before device registration completed.',
            ),
          );
          _log('Connection closed');
          isConnected = false;
          _socket = null;
          notifyListeners();
          _scheduleReconnect();
        },
        onError: (Object error) {
          if (!identical(_socket, socket)) {
            return;
          }
          final message = 'Socket error: $error';
          _completePendingRegistration(StateError(message));
          _log(message);
          lastError = message;
          isConnected = false;
          _socket = null;
          notifyListeners();
          _scheduleReconnect();
        },
      );

      _send('device.register', <String, Object?>{
        'deviceId': deviceId,
        'name': deviceName,
        'platform': platform,
        'kind': kind,
      });
      await _registrationCompleter!.future.timeout(const Duration(seconds: 5));
      if (identical(_socket, socket)) {
        isConnected = true;
        _reconnectAttempts = 0;
        _log('Connected to $websocketUrl');
      }
    } catch (error) {
      final message = 'Connection failed: $error';
      _completePendingRegistration(error);
      _log(message);
      lastError = message;
      isConnected = false;
      final socket = _socket;
      _socket = null;
      await socket?.close();
    } finally {
      isConnecting = false;
    }

    notifyListeners();
  }

  Future<void> reconnect() async {
    _autoReconnect = true;
    _reconnectAttempts = 0;
    await connect(force: true);
  }

  Future<void> loadOverview() async {
    try {
      final overview = await _apiClient.fetchOverview();
      _applyOverview(overview);
      _log('Overview loaded from $baseHttpUrl');
    } catch (error) {
      final message = 'Overview request failed: $error';
      _log(message);
      lastError = message;
    }

    notifyListeners();
  }

  Future<void> loadDevices() async {
    try {
      devices = await _apiClient.fetchDevices();
      _synchronizeSelectedAgent();
      _log('Loaded ${devices.length} device(s) from REST');
    } catch (error) {
      final message = 'Devices request failed: $error';
      _log(message);
      lastError = message;
    }

    notifyListeners();
  }

  Future<void> loadAgents() async {
    try {
      agents = await _apiClient.fetchAgents();
      _synchronizeSelectedAgent();
      _log('Loaded ${agents.length} agent(s) from REST');
    } catch (error) {
      final message = 'Agents request failed: $error';
      _log(message);
      lastError = message;
    }

    notifyListeners();
  }

  Future<void> loadActivity() async {
    try {
      activity = await _apiClient.fetchActivity();
      _log('Loaded ${activity.length} activity event(s) from REST');
    } catch (error) {
      final message = 'Activity request failed: $error';
      _log(message);
      lastError = message;
    }

    notifyListeners();
  }

  Future<void> loadCommands() async {
    try {
      commands = await _apiClient.fetchCommands();
      _log('Loaded ${commands.length} command record(s) from REST');
    } catch (error) {
      final message = 'Commands request failed: $error';
      _log(message);
      lastError = message;
    }

    notifyListeners();
  }

  void sendCommand(String action, {Map<String, Object?>? args}) {
    final socket = _socket;
    if (socket == null || selectedAgentId.isEmpty) {
      _log('Cannot send $action without an active connection and target agent');
      return;
    }

    final commandId = 'cmd-${DateTime.now().millisecondsSinceEpoch}';
    _send('command.send', <String, Object?>{
      'commandId': commandId,
      'sourceDeviceId': deviceId,
      'targetAgentId': selectedAgentId,
      'action': action,
      'args': args ?? <String, Object?>{},
    });
    _log('Sent $action to $selectedAgentId');
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _autoReconnect = false;
    final socket = _socket;
    _completePendingRegistration(StateError('Connection cancelled.'));
    _socket = null;
    isConnected = false;
    _reconnectAttempts = 0;
    socket?.close();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    disconnect();
    super.dispose();
  }

  void updateDeviceName(String name) {
    if (name.trim().isEmpty) return;
    deviceName = name.trim();
    notifyListeners();
  }

  void updateSelectedAgent(String agentId) {
    selectedAgentId = agentId;
    notifyListeners();
  }

  void updateBaseHttpUrl(String nextUrl) {
    _updateConfig(_config.copyWith(baseHttpUrl: nextUrl));
  }

  void updateWebsocketUrl(String nextUrl) {
    _updateConfig(_config.copyWith(websocketUrl: nextUrl));
  }

  void updateAuthToken(String nextToken) {
    _updateConfig(_config.copyWith(authToken: nextToken));
  }

  void updateConnectionSettings({
    String? baseHttpUrl,
    String? websocketUrl,
    String? authToken,
  }) {
    _updateConfig(
      _config.copyWith(
        baseHttpUrl: baseHttpUrl,
        websocketUrl: websocketUrl,
        authToken: authToken,
      ),
    );
  }

  void _handleMessage(dynamic raw) {
    final json = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = json['type'] as String? ?? 'unknown';
    final payload =
        (json['payload'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    switch (type) {
      case 'device.state':
        devices = (payload['devices'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (dynamic item) => RaikoDeviceInfo.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList(growable: false);
        agents = (payload['agents'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (dynamic item) => RaikoAgentInfo.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList(growable: false);
        _synchronizeSelectedAgent();
        _log(
          'State updated: ${agents.length} agent(s), ${devices.length} client device(s)',
        );
        break;
      case 'activity.snapshot':
        activity = (payload['activity'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (dynamic item) => RaikoActivityInfo.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList(growable: false);
        break;
      case 'command.snapshot':
        commands = (payload['commands'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (dynamic item) => RaikoCommandInfo.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList(growable: false);
        break;
      case 'command.result':
        lastCommandResult = RaikoCommandResult(
          commandId: payload['commandId'] as String? ?? '',
          action: payload['action'] as String? ?? 'unknown',
          status: payload['status'] as String? ?? 'unknown',
          output: payload['output'] as String? ?? '',
          receivedAt: DateTime.now(),
        );
        _log(
          'Result: ${payload['action']} -> ${payload['status']} (${payload['output']})',
        );
        break;
      case 'ack':
        final completer = _registrationCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
          _registrationCompleter = null;
        }
        _log(payload['message'] as String? ?? 'Acknowledged');
        break;
      case 'error':
        final message = payload['message'] as String?;
        if (message != null) {
          _completePendingRegistration(StateError(message));
        }
        lastError = message;
        _log('Error: ${payload['message']}');
        break;
      default:
        break;
    }

    notifyListeners();
  }

  void _send(String type, Map<String, Object?> payload) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    socket.add(jsonEncode(<String, Object?>{'type': type, 'payload': payload}));
  }

  void _applyOverview(RaikoOverviewSnapshot overview) {
    devices = overview.devices;
    agents = overview.agents;
    activity = overview.activity;
    commands = overview.commands;
    _synchronizeSelectedAgent();
  }

  void _synchronizeSelectedAgent() {
    if (agents.isEmpty) {
      selectedAgentId = '';
      return;
    }

    if (agents.every((RaikoAgentInfo agent) => agent.id != selectedAgentId)) {
      selectedAgentId = agents.first.id;
    }
  }

  void _updateConfig(RaikoBackendConfig nextConfig) {
    _config = nextConfig;
    _apiClient.updateConfig(nextConfig);
    notifyListeners();
  }

  void _completePendingRegistration(Object error) {
    final completer = _registrationCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }

    completer.completeError(error);
    _registrationCompleter = null;
  }

  void _scheduleReconnect() {
    if (_disposed || !_autoReconnect) {
      return;
    }

    final delay = _reconnectDelay(_reconnectAttempts);
    _reconnectAttempts++;
    _log('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_disposed && _autoReconnect) {
        connect(force: true);
      }
    });
  }

  static Duration _reconnectDelay(int attempt) {
    // Exponential backoff: 2s, 4s, 8s, 16s, capped at 30s
    final seconds = (2 << attempt).clamp(2, 30);
    return Duration(seconds: seconds);
  }

  void _log(String message) {
    logs.insert(0, '${DateTime.now().toIso8601String()}  $message');
    if (logs.length > 40) {
      logs.removeLast();
    }
  }
}

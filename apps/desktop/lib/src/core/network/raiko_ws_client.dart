import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';


class RaikoDeviceInfo {
  const RaikoDeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.kind,
    required this.status,
    required this.connectedAt,
    required this.lastSeenAt,
  });

  final String id;
  final String name;
  final String platform;
  final String kind;
  final String status;
  final String connectedAt;
  final String lastSeenAt;

  factory RaikoDeviceInfo.fromJson(Map<String, dynamic> json) {
    return RaikoDeviceInfo(
      id: json['id'] as String? ?? 'unknown-device',
      name: json['name'] as String? ?? 'Unknown Device',
      platform: json['platform'] as String? ?? 'unknown',
      kind: json['kind'] as String? ?? 'desktop',
      status: json['status'] as String? ?? 'offline',
      connectedAt: json['connectedAt'] as String? ?? '',
      lastSeenAt: json['lastSeenAt'] as String? ?? '',
    );
  }
}

class RaikoAgentInfo {
  const RaikoAgentInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.status,
    required this.connectedAt,
    required this.lastSeenAt,
    required this.supportedCommands,
  });

  final String id;
  final String name;
  final String platform;
  final String status;
  final String connectedAt;
  final String lastSeenAt;
  final List<String> supportedCommands;

  factory RaikoAgentInfo.fromJson(Map<String, dynamic> json) {
    return RaikoAgentInfo(
      id: json['id'] as String? ?? 'unknown-agent',
      name: json['name'] as String? ?? 'Unknown Agent',
      platform: json['platform'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'offline',
      connectedAt: json['connectedAt'] as String? ?? '',
      lastSeenAt: json['lastSeenAt'] as String? ?? '',
      supportedCommands: (json['supportedCommands'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }
}

class RaikoActivityInfo {
  const RaikoActivityInfo({
    required this.type,
    required this.actorId,
    required this.detail,
    required this.createdAt,
  });

  final String type;
  final String actorId;
  final String detail;
  final String createdAt;

  factory RaikoActivityInfo.fromJson(Map<String, dynamic> json) {
    return RaikoActivityInfo(
      type: json['type'] as String? ?? 'unknown',
      actorId: json['actorId'] as String? ?? 'unknown',
      detail: json['detail'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class RaikoCommandInfo {
  const RaikoCommandInfo({
    required this.commandId,
    required this.sourceDeviceId,
    required this.targetAgentId,
    required this.action,
    required this.status,
    required this.createdAt,
    this.output,
    this.completedAt,
  });

  final String commandId;
  final String sourceDeviceId;
  final String targetAgentId;
  final String action;
  final String status;
  final String createdAt;
  final String? output;
  final String? completedAt;

  factory RaikoCommandInfo.fromJson(Map<String, dynamic> json) {
    return RaikoCommandInfo(
      commandId: json['commandId'] as String? ?? 'unknown-command',
      sourceDeviceId: json['sourceDeviceId'] as String? ?? 'unknown-source',
      targetAgentId: json['targetAgentId'] as String? ?? 'unknown-target',
      action: json['action'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? '',
      output: json['output'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }
}

class RaikoWsClient extends ChangeNotifier {
  RaikoWsClient({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.kind,
    this.backendUrl = 'ws://127.0.0.1:8080/ws',
    String agentName = '',
  }) : agentName = agentName.isEmpty ? deviceName : agentName;

  final String deviceId;
  String deviceName;
  final String platform;
  final String kind;
  String agentName;

  String backendUrl;
  String authToken = '';
  WebSocket? _socket;
  bool isConnected = false;
  String selectedAgentId = '';
  String? lastError;

  List<RaikoDeviceInfo> devices = const <RaikoDeviceInfo>[];
  List<RaikoAgentInfo> agents = const <RaikoAgentInfo>[];
  List<RaikoActivityInfo> activity = const <RaikoActivityInfo>[];
  List<RaikoCommandInfo> commands = const <RaikoCommandInfo>[];
  final List<String> logs = <String>[];

  RaikoAgentInfo? get selectedAgent {
    for (final RaikoAgentInfo agent in agents) {
      if (agent.id == selectedAgentId) {
        return agent;
      }
    }

    return null;
  }

  Future<void> connect([String? url]) async {
    if (_socket != null) {
      return;
    }

    if (url != null && url.trim().isNotEmpty) {
      backendUrl = url.trim();
    }

    try {
      final headers = authToken.trim().isEmpty ? null : <String, dynamic>{'x-raiko-token': authToken.trim()};
      final socket = await WebSocket.connect(backendUrl, headers: headers);
      _socket = socket;
      isConnected = true;
      lastError = null;
      _log('Connected to $backendUrl');
      _send('device.register', <String, Object?>{
        'deviceId': deviceId,
        'name': deviceName,
        'platform': platform,
        'kind': kind,
      });

      _send('agent.register', <String, Object?>{
        'agentId': deviceId,
        'name': agentName,
        'platform': platform,
        'supportedCommands': <String>['shutdown', 'restart', 'sleep', 'lock'],
      });

      socket.listen(
        _handleMessage,
        onDone: () {
          _log('Connection closed');
          isConnected = false;
          _socket = null;
          notifyListeners();
        },
        onError: (Object error) {
          final message = 'Socket error: $error';
          _log(message);
          lastError = message;
          isConnected = false;
          _socket = null;
          notifyListeners();
        },
      );
    } catch (error) {
      final message = 'Connection failed: $error';
      _log(message);
      lastError = message;
      isConnected = false;
      _socket = null;
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
    _socket?.close();
    _socket = null;
    isConnected = false;
    notifyListeners();
  }

  void updateDeviceName(String name) {
    if (name.trim().isEmpty) return;
    deviceName = name.trim();
    notifyListeners();
  }

  void updateAgentName(String name) {
    if (name.trim().isEmpty) return;
    agentName = name.trim();
    notifyListeners();
  }

  void updateSelectedAgent(String agentId) {
    selectedAgentId = agentId;
    notifyListeners();
  }

  void updateBackendUrl(String nextUrl) {
    backendUrl = nextUrl.trim();
    notifyListeners();
  }

  void updateAuthToken(String nextToken) {
    authToken = nextToken.trim();
    notifyListeners();
  }

  void _handleMessage(dynamic raw) {
    final json = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = json['type'] as String? ?? 'unknown';
    final payload = (json['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    switch (type) {
      case 'device.state':
        devices = (payload['devices'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => RaikoDeviceInfo.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false);
        agents = (payload['agents'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => RaikoAgentInfo.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false);
        if (agents.isNotEmpty && agents.every((RaikoAgentInfo agent) => agent.id != selectedAgentId)) {
          selectedAgentId = agents.first.id;
        }
        _log('State updated: ${agents.length} agent(s), ${devices.length} client device(s)');
        break;
      case 'activity.snapshot':
        activity = (payload['activity'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => RaikoActivityInfo.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false);
        break;
      case 'command.snapshot':
        commands = (payload['commands'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => RaikoCommandInfo.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false);
        break;
      case 'command.dispatch':
        unawaited(_executeCommand(payload));
        break;
      case 'command.result':
        _log('Result: ${payload['action']} -> ${payload['status']} (${payload['output']})');
        break;
      case 'ack':
        _log(payload['message'] as String? ?? 'Acknowledged');
        break;
      case 'error':
        lastError = payload['message'] as String?;
        _log('Error: ${payload['message']}');
        break;
      default:
        break;
    }

    notifyListeners();
  }

  Future<void> _executeCommand(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    final action = payload['action'] as String? ?? '';
    final completedAt = DateTime.now().toIso8601String();

    String output;
    String status;

    try {
      switch (action) {
        case 'shutdown':
          await Process.run('shutdown.exe', <String>['/s', '/t', '0', '/f']);
          output = 'Shutdown initiated';
          break;
        case 'restart':
          await Process.run('shutdown.exe', <String>['/r', '/t', '0', '/f']);
          output = 'Restart initiated';
          break;
        case 'sleep':
          await Process.run('rundll32.exe', <String>['powrprof.dll,SetSuspendState', '0,1,0']);
          output = 'Sleep initiated';
          break;
        case 'lock':
          await Process.run('rundll32.exe', <String>['user32.dll,LockWorkStation']);
          output = 'Workstation locked';
          break;
        default:
          output = 'Unsupported action: $action';
          status = 'failed';
          _send('command.result', <String, Object?>{
            'commandId': commandId,
            'agentId': deviceId,
            'action': action,
            'status': status,
            'output': output,
            'completedAt': completedAt,
          });
          return;
      }
      status = 'success';
    } catch (e) {
      output = 'Error: $e';
      status = 'failed';
    }

    _log('Executed $action: $output');
    _send('command.result', <String, Object?>{
      'commandId': commandId,
      'agentId': deviceId,
      'action': action,
      'status': status,
      'output': output,
      'completedAt': completedAt,
    });
  }

  void _send(String type, Map<String, Object?> payload) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    socket.add(jsonEncode(<String, Object?>{
      'type': type,
      'payload': payload,
    }));
  }

  void _log(String message) {
    logs.insert(0, '${DateTime.now().toIso8601String()}  $message');
    if (logs.length > 40) {
      logs.removeLast();
    }
  }
}

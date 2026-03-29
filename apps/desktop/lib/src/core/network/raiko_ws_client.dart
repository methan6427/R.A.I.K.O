import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class RaikoWsClient extends ChangeNotifier {
  RaikoWsClient({required this.deviceId, required this.deviceName, required this.platform, required this.kind});

  final String deviceId;
  final String deviceName;
  final String platform;
  final String kind;

  WebSocket? _socket;
  bool isConnected = false;
  String selectedAgentId = 'agent-win-01';
  List<String> agents = const <String>[];
  final List<String> logs = <String>[];

  Future<void> connect([String url = 'ws://127.0.0.1:8080/ws']) async {
    if (_socket != null) {
      return;
    }

    final socket = await WebSocket.connect(url);
    _socket = socket;
    isConnected = true;
    _log('Connected to $url');
    _send('device.register', {
      'deviceId': deviceId,
      'name': deviceName,
      'platform': platform,
      'kind': kind,
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
        _log('Socket error: $error');
        isConnected = false;
        _socket = null;
        notifyListeners();
      },
    );

    notifyListeners();
  }

  void sendCommand(String action, {Map<String, Object?>? args}) {
    if (_socket == null) {
      _log('Cannot send command while disconnected');
      return;
    }

    final commandId = 'cmd-${DateTime.now().millisecondsSinceEpoch}';
    _send('command.send', {
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

  void updateSelectedAgent(String agentId) {
    selectedAgentId = agentId;
    notifyListeners();
  }

  void _handleMessage(dynamic raw) {
    final json = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = json['type'] as String? ?? 'unknown';
    final payload = (json['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    if (type == 'device.state') {
      final nextAgents = (payload['agents'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => (item as Map<String, dynamic>)['id'] as String)
          .toList(growable: false);
      agents = nextAgents;
      if (agents.isNotEmpty && !agents.contains(selectedAgentId)) {
        selectedAgentId = agents.first;
      }
      _log('State updated: ${agents.length} agent(s) online');
    } else if (type == 'command.result') {
      _log('Result: ${payload['action']} -> ${payload['status']} (${payload['output']})');
    } else if (type == 'ack') {
      _log(payload['message'] as String? ?? 'Acknowledged');
    } else if (type == 'error') {
      _log('Error: ${payload['message']}');
    }

    notifyListeners();
  }

  void _send(String type, Map<String, Object?> payload) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    socket.add(jsonEncode({'type': type, 'payload': payload}));
  }

  void _log(String message) {
    logs.insert(0, '${DateTime.now().toIso8601String()}  $message');
    if (logs.length > 20) {
      logs.removeLast();
    }
    notifyListeners();
  }
}
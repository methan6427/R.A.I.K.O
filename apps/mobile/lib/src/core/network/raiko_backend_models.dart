typedef _JsonFactory<T> = T Function(Map<String, dynamic> json);

class RaikoOverviewSnapshot {
  const RaikoOverviewSnapshot({
    required this.devices,
    required this.agents,
    required this.activity,
    required this.commands,
  });

  final List<RaikoDeviceInfo> devices;
  final List<RaikoAgentInfo> agents;
  final List<RaikoActivityInfo> activity;
  final List<RaikoCommandInfo> commands;

  factory RaikoOverviewSnapshot.fromJson(Map<String, dynamic> json) {
    return RaikoOverviewSnapshot(
      devices: _decodeList(json['devices'], RaikoDeviceInfo.fromJson),
      agents: _decodeList(json['agents'], RaikoAgentInfo.fromJson),
      activity: _decodeList(json['activity'], RaikoActivityInfo.fromJson),
      commands: _decodeList(json['commands'], RaikoCommandInfo.fromJson),
    );
  }
}

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
      supportedCommands:
          (json['supportedCommands'] as List<dynamic>? ?? const <dynamic>[])
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

List<T> _decodeList<T>(dynamic source, _JsonFactory<T> factory) {
  final items = source is List ? source : const <dynamic>[];

  return items
      .whereType<Map>()
      .map((Map item) => factory(item.cast<String, dynamic>()))
      .toList(growable: false);
}

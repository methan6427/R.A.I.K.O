import 'dart:async';

import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/config/raiko_backend_config.dart';
import '../../../core/network/raiko_backend_models.dart';
import '../../../core/network/raiko_ws_client.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({
    super.key,
    this.initialBackendConfig = RaikoBackendConfig.defaults,
    this.autoStartBackend = true,
  });

  final RaikoBackendConfig initialBackendConfig;
  final bool autoStartBackend;

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  late final RaikoWsClient client;
  late final TextEditingController baseHttpUrlController;
  late final TextEditingController websocketUrlController;
  late final TextEditingController authTokenController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    client = RaikoWsClient(
      deviceId: 'mobile-android-01',
      deviceName: 'RAIKO Mobile',
      platform: 'android',
      kind: 'mobile',
      initialConfig: widget.initialBackendConfig,
    )..addListener(_onChanged);
    baseHttpUrlController = TextEditingController(text: client.baseHttpUrl);
    websocketUrlController = TextEditingController(text: client.websocketUrl);
    authTokenController = TextEditingController(text: client.authToken);
    if (widget.autoStartBackend) {
      unawaited(client.start());
    }
  }

  @override
  void dispose() {
    baseHttpUrlController.dispose();
    websocketUrlController.dispose();
    authTokenController.dispose();
    client.removeListener(_onChanged);
    client.disconnect();
    client.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (baseHttpUrlController.text != client.baseHttpUrl) {
      baseHttpUrlController.text = client.baseHttpUrl;
    }
    if (websocketUrlController.text != client.websocketUrl) {
      websocketUrlController.text = client.websocketUrl;
    }
    if (authTokenController.text != client.authToken) {
      authTokenController.text = client.authToken;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _connect() async {
    client.updateConnectionSettings(
      baseHttpUrl: baseHttpUrlController.text,
      websocketUrl: websocketUrlController.text,
      authToken: authTokenController.text,
    );
    await client.reconnect();
    await client.loadOverview();
  }

  void _showVoiceConsole() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: RaikoCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Relay',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'The voice path is staged for commands like "lock my PC" and "restart office desktop".',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: RaikoButton(
                        label: 'Lock Agent',
                        icon: Icons.lock_outline_rounded,
                        onPressed: client.selectedAgentId.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                client.sendCommand('lock');
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RaikoButton(
                        label: 'Sleep Agent',
                        icon: Icons.nightlight_round,
                        isSecondary: true,
                        onPressed: client.selectedAgentId.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                client.sendCommand('sleep');
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Suggested phrases',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '• "Raiko lock the office PC"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '• "Raiko restart my workstation"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '• "Raiko put the desktop to sleep"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(client: client, onConnect: _connect),
      _DevicesTab(client: client),
      _ActivityTab(client: client),
      _SettingsTab(
        client: client,
        baseHttpUrlController: baseHttpUrlController,
        websocketUrlController: websocketUrlController,
        authTokenController: authTokenController,
        onApplyConnectionSettings: () {
          client.updateConnectionSettings(
            baseHttpUrl: baseHttpUrlController.text,
            websocketUrl: websocketUrlController.text,
            authToken: authTokenController.text,
          );
        },
        onConnect: _connect,
      ),
    ];

    return RaikoScaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 78,
        height: 78,
        child: RaikoVoiceOrb(
          label: 'AI',
          size: 78,
          isActive: client.isConnected,
          tooltip: 'Open voice relay',
          onPressed: _showVoiceConsole,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: RaikoColors.cardElevated.withValues(
                  alpha: 0.96,
                ),
                indicatorColor: RaikoColors.accent.withValues(alpha: 0.2),
                iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
                  (Set<WidgetState> states) => IconThemeData(
                    color: states.contains(WidgetState.selected)
                        ? RaikoColors.accentStrong
                        : RaikoColors.textSecondary,
                  ),
                ),
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                  (Set<WidgetState> states) =>
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: states.contains(WidgetState.selected)
                            ? RaikoColors.textPrimary
                            : RaikoColors.textSecondary,
                      ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.devices_outlined),
                    label: 'Devices',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timeline_outlined),
                    label: 'Activity',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.client, required this.onConnect});

  final RaikoWsClient client;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final wide = constraints.maxWidth >= 720;

        return ListView(
          children: [
            RaikoHeader(
              eyebrow: 'HOME',
              title: 'Remote Kernel',
              subtitle: 'Mobile orchestration for live Windows endpoints.',
              trailing: RaikoStatusBadge(
                label: client.isConnected ? 'Linked' : 'Offline',
                color: client.isConnected
                    ? RaikoColors.success
                    : RaikoColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SessionCard(client: client, onConnect: onConnect),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _QuickActionsCard(client: client)),
                ],
              )
            else ...[
              _SessionCard(client: client, onConnect: onConnect),
              const SizedBox(height: 16),
              _QuickActionsCard(client: client),
            ],
            const SizedBox(height: 16),
            _RecentCommandsCard(client: client),
          ],
        );
      },
    );
  }
}

class _DevicesTab extends StatelessWidget {
  const _DevicesTab({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        RaikoHeader(
          eyebrow: 'DEVICES',
          title: 'Connected Surfaces',
          subtitle:
              'Agents and client devices currently visible to the control backend.',
          trailing: RaikoStatusBadge(
            label: '${client.agents.length} agents',
            color: client.agents.isEmpty
                ? RaikoColors.warning
                : RaikoColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Agents',
                value: client.agents.length.toString(),
                caption: 'Remote Windows nodes',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Clients',
                value: client.devices.length.toString(),
                caption: 'Connected operators',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EntityListCard<RaikoAgentInfo>(
          title: 'Agents',
          emptyText: 'No agents are registered yet.',
          items: client.agents,
          itemBuilder: (BuildContext context, RaikoAgentInfo agent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RaikoDeviceTile(
                title: agent.name,
                subtitle: '${agent.platform} • ${agent.id}',
                statusLabel: agent.status.toUpperCase(),
                statusColor: _statusColor(agent.status),
                icon: Icons.laptop_windows_rounded,
                trailing: Text(
                  '${agent.supportedCommands.length} cmds',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _EntityListCard<RaikoDeviceInfo>(
          title: 'Client Devices',
          emptyText: 'No client devices are registered yet.',
          items: client.devices,
          itemBuilder: (BuildContext context, RaikoDeviceInfo device) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RaikoDeviceTile(
                title: device.name,
                subtitle: '${device.platform} • ${device.kind}',
                statusLabel: device.status.toUpperCase(),
                statusColor: _statusColor(device.status),
                icon: device.kind == 'mobile'
                    ? Icons.phone_android_rounded
                    : Icons.desktop_windows_rounded,
                trailing: Text(
                  _formatTimestamp(device.lastSeenAt),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        RaikoHeader(
          eyebrow: 'ACTIVITY',
          title: 'Operational Feed',
          subtitle:
              'Recent command results, heartbeats, and registration events.',
          trailing: RaikoStatusBadge(
            label: '${client.activity.length} events',
            color: RaikoColors.accentStrong,
          ),
        ),
        const SizedBox(height: 24),
        _CommandHistoryCard(client: client),
        const SizedBox(height: 16),
        _ActivityFeedCard(client: client),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.client,
    required this.baseHttpUrlController,
    required this.websocketUrlController,
    required this.authTokenController,
    required this.onApplyConnectionSettings,
    required this.onConnect,
  });

  final RaikoWsClient client;
  final TextEditingController baseHttpUrlController;
  final TextEditingController websocketUrlController;
  final TextEditingController authTokenController;
  final VoidCallback onApplyConnectionSettings;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        RaikoHeader(
          eyebrow: 'SETTINGS',
          title: 'Control Preferences',
          subtitle:
              'Tune the mobile relay and connection target before production rollout.',
          trailing: RaikoStatusBadge(
            label: client.lastError == null ? 'Healthy' : 'Needs Attention',
            color: client.lastError == null
                ? RaikoColors.success
                : RaikoColors.warning,
          ),
        ),
        const SizedBox(height: 24),
        RaikoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backend Endpoint',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Point the mobile client at the active HTTP API and websocket gateway.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: baseHttpUrlController,
                decoration: const InputDecoration(labelText: 'Base HTTP URL'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: websocketUrlController,
                decoration: const InputDecoration(labelText: 'WebSocket URL'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authTokenController,
                decoration: const InputDecoration(
                  labelText: 'Auth token (optional)',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RaikoButton(
                      label: 'Apply URL',
                      icon: Icons.save_outlined,
                      isSecondary: true,
                      onPressed: onApplyConnectionSettings,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RaikoButton(
                      label: client.isConnected ? 'Reconnect' : 'Connect',
                      icon: Icons.wifi_tethering_rounded,
                      onPressed: onConnect,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RaikoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Identity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Device ID', value: client.deviceId),
              _InfoRow(label: 'Name', value: client.deviceName),
              _InfoRow(label: 'Platform', value: client.platform),
              _InfoRow(label: 'HTTP API', value: client.baseHttpUrl),
              _InfoRow(label: 'WebSocket', value: client.websocketUrl),
              _InfoRow(
                label: 'Selected Agent',
                value: client.selectedAgentId.isEmpty
                    ? 'none'
                    : client.selectedAgentId,
              ),
              _InfoRow(
                label: 'Auth Token',
                value: client.authToken.isEmpty
                    ? 'not configured'
                    : 'configured',
              ),
              if (client.lastError != null)
                _InfoRow(label: 'Last Error', value: client.lastError!),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.client, required this.onConnect});

  final RaikoWsClient client;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session Link', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Connect the phone to the backend, then route commands to a live Windows agent.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          RaikoButton(
            label: client.isConnected ? 'Disconnect' : 'Connect to Backend',
            icon: client.isConnected
                ? Icons.link_off_rounded
                : Icons.wifi_tethering_rounded,
            onPressed: client.isConnected
                ? client.disconnect
                : () => onConnect(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue:
                client.agents.any(
                  (RaikoAgentInfo agent) => agent.id == client.selectedAgentId,
                )
                ? client.selectedAgentId
                : null,
            decoration: const InputDecoration(labelText: 'Target agent'),
            dropdownColor: RaikoColors.cardElevated,
            items: client.agents
                .map(
                  (RaikoAgentInfo agent) => DropdownMenuItem<String>(
                    value: agent.id,
                    child: Text(agent.name),
                  ),
                )
                .toList(growable: false),
            onChanged: client.agents.isEmpty
                ? null
                : (String? value) {
                    if (value != null) {
                      client.updateSelectedAgent(value);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      RaikoButton(
        label: 'Lock',
        icon: Icons.lock_outline_rounded,
        onPressed: () => client.sendCommand('lock'),
      ),
      RaikoButton(
        label: 'Sleep',
        icon: Icons.nightlight_round,
        onPressed: () => client.sendCommand('sleep'),
      ),
      RaikoButton(
        label: 'Restart',
        icon: Icons.restart_alt_rounded,
        onPressed: () => client.sendCommand('restart'),
      ),
      RaikoButton(
        label: 'Shutdown',
        icon: Icons.power_settings_new_rounded,
        isDanger: true,
        onPressed: () => client.sendCommand('shutdown'),
      ),
    ];

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Touch-first control deck for the currently selected agent.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _RecentCommandsCard extends StatelessWidget {
  const _RecentCommandsCard({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    final recentCommands = client.commands.take(3).toList(growable: false);

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Commands',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (recentCommands.isEmpty)
            Text(
              'No commands have been sent yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          for (final RaikoCommandInfo command in recentCommands)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineRow(
                title: command.action.toUpperCase(),
                subtitle:
                    '${command.targetAgentId} • ${_formatTimestamp(command.createdAt)}',
                badgeLabel: command.status.toUpperCase(),
                badgeColor: _statusColor(command.status),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommandHistoryCard extends StatelessWidget {
  const _CommandHistoryCard({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Command History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (client.commands.isEmpty)
            Text(
              'No command records yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          for (final RaikoCommandInfo command in client.commands.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineRow(
                title: '${command.action} • ${command.targetAgentId}',
                subtitle: command.output ?? command.createdAt,
                badgeLabel: command.status.toUpperCase(),
                badgeColor: _statusColor(command.status),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityFeedCard extends StatelessWidget {
  const _ActivityFeedCard({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Feed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (client.activity.isEmpty)
            Text(
              'No activity has been reported yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          for (final RaikoActivityInfo event in client.activity.take(12))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineRow(
                title: '${event.type} • ${event.actorId}',
                subtitle:
                    '${event.detail} • ${_formatTimestamp(event.createdAt)}',
                badgeLabel: 'LIVE',
                badgeColor: RaikoColors.accentStrong,
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
  });

  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(caption, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EntityListCard<T> extends StatelessWidget {
  const _EntityListCard({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.itemBuilder,
  });

  final String title;
  final String emptyText;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodyMedium),
          for (final T item in items) itemBuilder(context, item),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        RaikoStatusBadge(label: badgeLabel, color: badgeColor),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'success':
    case 'online':
      return RaikoColors.success;
    case 'failed':
    case 'offline':
      return RaikoColors.danger;
    default:
      return RaikoColors.warning;
  }
}

String _formatTimestamp(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.isEmpty ? 'n/a' : value;
  }

  final local = parsed.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

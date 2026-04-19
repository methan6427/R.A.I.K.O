import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_ws_client.dart';
import '../../../core/settings/desktop_settings_store.dart';

class DesktopDashboardScreen extends StatefulWidget {
  const DesktopDashboardScreen({super.key, required this.initialSettings});

  final DesktopSettings initialSettings;

  @override
  State<DesktopDashboardScreen> createState() => _DesktopDashboardScreenState();
}

class _DesktopDashboardScreenState extends State<DesktopDashboardScreen> {
  late final RaikoWsClient client;
  late final TextEditingController backendUrlController;
  late final TextEditingController authTokenController;
  late final TextEditingController deviceNameController;
  late final TextEditingController agentNameController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSettings;
    client = RaikoWsClient(
      deviceId: 'desktop-windows-01',
      deviceName: s.deviceName,
      platform: 'windows',
      kind: 'desktop',
      backendUrl: s.backendUrl,
      agentName: s.agentName,
    )..addListener(_onChanged);
    client.authToken = s.authToken;
    backendUrlController = TextEditingController(text: client.backendUrl);
    authTokenController = TextEditingController(text: client.authToken);
    deviceNameController = TextEditingController(text: client.deviceName);
    agentNameController = TextEditingController(text: client.agentName);
  }

  @override
  void dispose() {
    backendUrlController.dispose();
    authTokenController.dispose();
    deviceNameController.dispose();
    agentNameController.dispose();
    client.removeListener(_onChanged);
    client.disconnect();
    client.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _connect() async {
    client.updateBackendUrl(backendUrlController.text);
    client.updateAuthToken(authTokenController.text);
    await client.connect(backendUrlController.text);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _DashboardTab(client: client, onConnect: _connect),
      _DevicesTab(client: client),
      _ActivityTab(client: client),
      _SettingsTab(
        client: client,
        backendUrlController: backendUrlController,
        authTokenController: authTokenController,
        deviceNameController: deviceNameController,
        agentNameController: agentNameController,
        onApplyConnectionSettings: () {
          client.updateBackendUrl(backendUrlController.text);
          client.updateAuthToken(authTokenController.text);
          DesktopSettingsStore.save(DesktopSettings(
            backendUrl: client.backendUrl,
            authToken: client.authToken,
            deviceName: client.deviceName,
            agentName: client.agentName,
          ));
        },
        onApplyIdentitySettings: () {
          client.updateDeviceName(deviceNameController.text);
          client.updateAgentName(agentNameController.text);
          DesktopSettingsStore.save(DesktopSettings(
            backendUrl: client.backendUrl,
            authToken: client.authToken,
            deviceName: client.deviceName,
            agentName: client.agentName,
          ));
        },
        onConnect: _connect,
      ),
    ];

    return RaikoScaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 280,
            child: _DesktopSidebar(
              client: client,
              currentIndex: currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  currentIndex = index;
                });
              },
              onConnect: _connect,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<int>(currentIndex),
                child: pages[currentIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.client,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onConnect,
  });

  final RaikoWsClient client;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: RaikoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RaikoVoiceOrb(
                label: 'R.A.I.K.O',
                size: 140,
                isActive: client.isConnected,
              ),
            ),
            const SizedBox(height: 20),
            Text('Operations Bridge', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Persistent control surface for backend links, device routing, and command dispatch.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            RaikoStatusBadge(
              label: client.isConnected ? 'Synchronized' : 'Disconnected',
              color: client.isConnected ? RaikoColors.success : RaikoColors.danger,
            ),
            const SizedBox(height: 20),
            RaikoButton(
              label: client.isConnected ? 'Disconnect' : 'Connect',
              icon: client.isConnected ? Icons.link_off_rounded : Icons.wifi_tethering_rounded,
              onPressed: client.isConnected ? client.disconnect : () => onConnect(),
            ),
            const SizedBox(height: 20),
            _SidebarButton(
              label: 'Dashboard',
              icon: Icons.grid_view_rounded,
              selected: currentIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            const SizedBox(height: 8),
            _SidebarButton(
              label: 'Devices',
              icon: Icons.devices_outlined,
              selected: currentIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
            const SizedBox(height: 8),
            _SidebarButton(
              label: 'Activity',
              icon: Icons.timeline_outlined,
              selected: currentIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
            const SizedBox(height: 8),
            _SidebarButton(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selected: currentIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
            const SizedBox(height: 24),
            Text('Selected agent', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              client.selectedAgentId.isEmpty ? 'No agent selected' : client.selectedAgentId,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.client,
    required this.onConnect,
  });

  final RaikoWsClient client;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        RaikoHeader(
          eyebrow: 'DASHBOARD',
          title: 'Desktop Command Console',
          subtitle: 'Command dispatch, route health, and live endpoint visibility.',
          trailing: RaikoStatusBadge(
            label: client.agents.isEmpty ? 'Awaiting Agents' : '${client.agents.length} Ready',
            color: client.agents.isEmpty ? RaikoColors.warning : RaikoColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SessionCard(client: client, onConnect: onConnect)),
            const SizedBox(width: 16),
            Expanded(child: _QuickActionsCard(client: client)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PrimaryAgentCard(client: client)),
            const SizedBox(width: 16),
            Expanded(child: _RecentCommandsCard(client: client)),
          ],
        ),
      ],
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
          title: 'Fleet Overview',
          subtitle: 'View live agents and operator consoles connected to the control plane.',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Agents',
                value: client.agents.length.toString(),
                caption: 'Windows nodes online',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Clients',
                value: client.devices.length.toString(),
                caption: 'Operator surfaces connected',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Commands',
                value: client.commands.length.toString(),
                caption: 'Recorded command entries',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EntityListCard<RaikoAgentInfo>(
          title: 'Agents',
          emptyText: 'No agents are connected.',
          items: client.agents,
          itemBuilder: (BuildContext context, RaikoAgentInfo agent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RaikoDeviceTile(
                title: agent.name,
                subtitle: '${agent.platform} • ${agent.id}',
                statusLabel: agent.status.toUpperCase(),
                statusColor: _statusColor(agent.status),
                icon: Icons.memory_rounded,
                trailing: Text(
                  '${agent.supportedCommands.length} commands',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _EntityListCard<RaikoDeviceInfo>(
          title: 'Client Devices',
          emptyText: 'No client devices are connected.',
          items: client.devices,
          itemBuilder: (BuildContext context, RaikoDeviceInfo device) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RaikoDeviceTile(
                title: device.name,
                subtitle: '${device.platform} • ${device.kind}',
                statusLabel: device.status.toUpperCase(),
                statusColor: _statusColor(device.status),
                icon: device.kind == 'mobile' ? Icons.phone_android_rounded : Icons.desktop_windows_rounded,
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
          title: 'Execution Feed',
          subtitle: 'Review command throughput, acknowledgements, and device-side activity.',
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CommandHistoryCard(client: client)),
            const SizedBox(width: 16),
            Expanded(child: _ActivityFeedCard(client: client)),
          ],
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.client,
    required this.backendUrlController,
    required this.authTokenController,
    required this.deviceNameController,
    required this.agentNameController,
    required this.onApplyConnectionSettings,
    required this.onApplyIdentitySettings,
    required this.onConnect,
  });

  final RaikoWsClient client;
  final TextEditingController backendUrlController;
  final TextEditingController authTokenController;
  final TextEditingController deviceNameController;
  final TextEditingController agentNameController;
  final VoidCallback onApplyConnectionSettings;
  final VoidCallback onApplyIdentitySettings;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        RaikoHeader(
          eyebrow: 'SETTINGS',
          title: 'Desktop Runtime Settings',
          subtitle: 'Adjust the operator endpoint and inspect the active workstation identity.',
        ),
        const SizedBox(height: 24),
        RaikoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backend Endpoint', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Use the production websocket gateway or point to a local backend during validation.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: backendUrlController,
                decoration: const InputDecoration(labelText: 'WebSocket URL'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authTokenController,
                decoration: const InputDecoration(labelText: 'Auth token (optional)'),
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
              Text('Device & Agent Identity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Rename this workstation and the agent it registers as.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deviceNameController,
                decoration: const InputDecoration(labelText: 'Device name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: agentNameController,
                decoration: const InputDecoration(labelText: 'Agent name (shown in target agent list)'),
              ),
              const SizedBox(height: 16),
              RaikoButton(
                label: 'Apply names',
                icon: Icons.check_rounded,
                isSecondary: true,
                onPressed: onApplyIdentitySettings,
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Device ID', value: client.deviceId),
              _InfoRow(label: 'Platform', value: client.platform),
              _InfoRow(label: 'Selected Agent', value: client.selectedAgentId.isEmpty ? 'none' : client.selectedAgentId),
              _InfoRow(label: 'Auth Token', value: client.authToken.isEmpty ? 'not configured' : 'configured'),
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
  const _SessionCard({
    required this.client,
    required this.onConnect,
  });

  final RaikoWsClient client;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session Routing', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Attach the operator console to the backend and choose the active Windows agent.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          RaikoButton(
            label: client.isConnected ? 'Disconnect' : 'Connect to Backend',
            icon: client.isConnected ? Icons.link_off_rounded : Icons.wifi_tethering_rounded,
            onPressed: client.isConnected ? client.disconnect : () => onConnect(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: client.agents.any((RaikoAgentInfo agent) => agent.id == client.selectedAgentId)
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
      RaikoButton(label: 'Lock', icon: Icons.lock_outline_rounded, onPressed: () => client.sendCommand('lock')),
      RaikoButton(label: 'Sleep', icon: Icons.nightlight_round, onPressed: () => client.sendCommand('sleep')),
      RaikoButton(label: 'Restart', icon: Icons.restart_alt_rounded, onPressed: () => client.sendCommand('restart')),
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
          Text('High-priority execution controls for the selected agent.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.3,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _PrimaryAgentCard extends StatelessWidget {
  const _PrimaryAgentCard({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    final agent = client.selectedAgent;

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Primary Agent', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (agent == null)
            Text('No agent selected.', style: Theme.of(context).textTheme.bodyMedium)
          else
            RaikoDeviceTile(
              title: agent.name,
              subtitle: '${agent.platform} • ${agent.id}',
              statusLabel: agent.status.toUpperCase(),
              statusColor: _statusColor(agent.status),
              icon: Icons.hub_rounded,
              trailing: Text(
                _formatTimestamp(agent.lastSeenAt),
                style: Theme.of(context).textTheme.labelMedium,
              ),
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
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Commands', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (client.commands.isEmpty)
            Text('No commands recorded yet.', style: Theme.of(context).textTheme.bodyMedium),
          for (final RaikoCommandInfo command in client.commands.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineRow(
                title: '${command.action} • ${command.targetAgentId}',
                subtitle: command.output ?? _formatTimestamp(command.createdAt),
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
          Text('Command History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (client.commands.isEmpty)
            Text('No command activity yet.', style: Theme.of(context).textTheme.bodyMedium),
          for (final RaikoCommandInfo command in client.commands.take(12))
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
          Text('Backend Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (client.activity.isEmpty)
            Text('No backend events have been received.', style: Theme.of(context).textTheme.bodyMedium),
          for (final RaikoActivityInfo event in client.activity.take(12))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineRow(
                title: '${event.type} • ${event.actorId}',
                subtitle: '${event.detail} • ${_formatTimestamp(event.createdAt)}',
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

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? RaikoColors.accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? RaikoColors.accentStrong.withValues(alpha: 0.42) : RaikoColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? RaikoColors.accentStrong : RaikoColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? RaikoColors.textPrimary : RaikoColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
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
  const _InfoRow({
    required this.label,
    required this.value,
  });

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
            width: 120,
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

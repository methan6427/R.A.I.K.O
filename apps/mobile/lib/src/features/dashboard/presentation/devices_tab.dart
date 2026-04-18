import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_backend_models.dart';
import '../../../core/network/raiko_ws_client.dart';
import 'helpers.dart';

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key, required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        RaikoHeader(
          eyebrow: 'DEVICES',
          title: 'Connected Surfaces',
          subtitle:
              'Agents and client devices currently visible to the control backend.',
          trailing: RaikoStatusBadge(
            label: '${client.agents.length} agent${client.agents.length != 1 ? 's' : ''}',
            color: client.agents.isEmpty
                ? RaikoColors.warning
                : RaikoColors.success,
            pulsate: client.agents.isNotEmpty,
          ),
        ),
        const SizedBox(height: 24),

        // --- Metrics ---
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Agents',
                value: client.agents.length.toString(),
                caption: 'Windows nodes',
                icon: Icons.laptop_windows_rounded,
                color: RaikoColors.accentStrong,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Clients',
                value: client.devices.length.toString(),
                caption: 'Operators',
                icon: Icons.phone_android_rounded,
                color: RaikoColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Agents ---
        if (client.agents.isNotEmpty) ...[
          _SectionLabel(label: 'AGENTS'),
          const SizedBox(height: 10),
          for (final RaikoAgentInfo agent in client.agents)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RaikoDeviceTile(
                title: agent.name,
                subtitle: '${agent.platform} \u2022 ${agent.id}',
                statusLabel: agent.status.toUpperCase(),
                statusColor: statusColor(agent.status),
                icon: Icons.laptop_windows_rounded,
                trailing: Text(
                  '${agent.supportedCommands.length} cmds',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],

        // --- Devices ---
        if (client.devices.isNotEmpty) ...[
          _SectionLabel(label: 'CLIENT DEVICES'),
          const SizedBox(height: 10),
          for (final RaikoDeviceInfo device in client.devices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RaikoDeviceTile(
                title: device.name,
                subtitle: '${device.platform} \u2022 ${device.kind}',
                statusLabel: device.status.toUpperCase(),
                statusColor: statusColor(device.status),
                icon: device.kind == 'mobile'
                    ? Icons.phone_android_rounded
                    : Icons.desktop_windows_rounded,
                trailing: Text(
                  formatTimeAgo(device.lastSeenAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                ),
              ),
            ),
        ],

        if (client.agents.isEmpty && client.devices.isEmpty)
          RaikoCard(
            child: Column(
              children: [
                Icon(
                  Icons.devices_other_rounded,
                  color: RaikoColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No devices connected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start the backend and connect an agent to see devices here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: RaikoColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: RaikoColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: RaikoColors.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

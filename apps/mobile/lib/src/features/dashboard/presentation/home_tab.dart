import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_backend_models.dart';
import '../../../core/network/raiko_ws_client.dart';
import 'helpers.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.client, required this.onConnect});

  final RaikoWsClient client;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // --- Connection header ---
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'R.A.I.K.O',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remote Kernel Operator',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: RaikoColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              RaikoConnectionIndicator(
                state: client.isConnected
                    ? RaikoConnectionState.connected
                    : RaikoConnectionState.offline,
                agentCount: client.agents.length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Session card ---
        _SessionCard(client: client, onConnect: onConnect),
        const SizedBox(height: 16),

        // --- Command center ---
        _CommandCenter(client: client),
        const SizedBox(height: 16),

        // --- Recent commands ---
        _RecentCommandsCard(client: client),
        const SizedBox(height: 100),
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
          Row(
            children: [
              Icon(
                client.isConnected
                    ? Icons.wifi_tethering_rounded
                    : Icons.wifi_tethering_off_rounded,
                color: client.isConnected
                    ? RaikoColors.success
                    : RaikoColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Session',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RaikoButton(
                  label: client.isConnecting
                      ? 'Connecting\u2026'
                      : (client.isConnected ? 'Disconnect' : 'Connect'),
                  icon: client.isConnecting
                      ? Icons.hourglass_top_rounded
                      : (client.isConnected
                          ? Icons.link_off_rounded
                          : Icons.link_rounded),
                  isSecondary: client.isConnected,
                  onPressed: client.isConnecting
                      ? null
                      : (client.isConnected
                          ? client.disconnect
                          : () => onConnect()),
                ),
              ),
            ],
          ),
          if (client.agents.isNotEmpty) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: client.agents.any(
                (RaikoAgentInfo agent) => agent.id == client.selectedAgentId,
              )
                  ? client.selectedAgentId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Target agent',
                isDense: true,
              ),
              dropdownColor: RaikoColors.cardElevated,
              items: client.agents
                  .map(
                    (RaikoAgentInfo agent) => DropdownMenuItem<String>(
                      value: agent.id,
                      child: Text(agent.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String? value) {
                if (value != null) {
                  client.updateSelectedAgent(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CommandCenter extends StatelessWidget {
  const _CommandCenter({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    final disabled = !client.isConnected || client.selectedAgentId.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'COMMAND CENTER',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: RaikoColors.textMuted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            RaikoCommandButton(
              label: 'Lock',
              icon: Icons.lock_outline_rounded,
              isDisabled: disabled,
              onPressed: () => client.sendCommand('lock'),
            ),
            RaikoCommandButton(
              label: 'Sleep',
              icon: Icons.nightlight_round,
              color: RaikoColors.accent,
              isDisabled: disabled,
              onPressed: () => client.sendCommand('sleep'),
            ),
            RaikoCommandButton(
              label: 'Restart',
              icon: Icons.restart_alt_rounded,
              color: RaikoColors.warning,
              isDisabled: disabled,
              onPressed: () => client.sendCommand('restart'),
            ),
            RaikoCommandButton(
              label: 'Shutdown',
              icon: Icons.power_settings_new_rounded,
              isDanger: true,
              isDisabled: disabled,
              onPressed: () => client.sendCommand('shutdown'),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentCommandsCard extends StatelessWidget {
  const _RecentCommandsCard({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    final recent = client.commands.take(5).toList(growable: false);

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: RaikoColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Commands',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Text(
              'No commands sent yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RaikoColors.textMuted,
                  ),
            ),
          for (final RaikoCommandInfo command in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor(command.status),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          command.action.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                        ),
                        Text(
                          '${command.targetAgentId} \u2022 ${formatTimestamp(command.createdAt)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: RaikoColors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  RaikoStatusBadge(
                    label: command.status.toUpperCase(),
                    color: statusColor(command.status),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

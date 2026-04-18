import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_backend_models.dart';
import '../../../core/network/raiko_ws_client.dart';
import 'helpers.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key, required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        RaikoHeader(
          eyebrow: 'ACTIVITY',
          title: 'Operational Feed',
          subtitle: 'Commands, heartbeats, and registration events.',
          trailing: RaikoStatusBadge(
            label: '${client.activity.length} events',
            color: RaikoColors.accentStrong,
            pulsate: client.activity.isNotEmpty,
          ),
        ),
        const SizedBox(height: 24),

        // --- Command History ---
        _CommandHistorySection(client: client),
        const SizedBox(height: 20),

        // --- Live Feed ---
        _LiveFeedSection(client: client),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _CommandHistorySection extends StatelessWidget {
  const _CommandHistorySection({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    final commands = client.commands.take(10).toList(growable: false);

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, color: RaikoColors.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                'Command History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (commands.isEmpty)
            _EmptyState(message: 'No commands recorded yet.'),
          for (final RaikoCommandInfo command in commands)
            _CommandRow(command: command),
        ],
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({required this.command});

  final RaikoCommandInfo command;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
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
                  '${command.action.toUpperCase()} \u2022 ${command.targetAgentId}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  command.output ?? formatTimestamp(command.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RaikoStatusBadge(
            label: command.status.toUpperCase(),
            color: statusColor(command.status),
          ),
        ],
      ),
    );
  }
}

class _LiveFeedSection extends StatelessWidget {
  const _LiveFeedSection({required this.client});

  final RaikoWsClient client;

  @override
  Widget build(BuildContext context) {
    final events = client.activity.take(15).toList(growable: false);

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors_rounded, color: RaikoColors.accentStrong, size: 18),
              const SizedBox(width: 8),
              Text(
                'Live Feed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (events.isNotEmpty)
                RaikoStatusBadge(
                  label: 'LIVE',
                  color: RaikoColors.success,
                  pulsate: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (events.isEmpty) _EmptyState(message: 'No activity yet.'),
          for (final RaikoActivityInfo event in events)
            _ActivityRow(event: event),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final RaikoActivityInfo event;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (event.type) {
      case 'agent.register':
        icon = Icons.laptop_windows_rounded;
        color = RaikoColors.success;
      case 'device.register':
        icon = Icons.phone_android_rounded;
        color = RaikoColors.accentStrong;
      case 'heartbeat':
        icon = Icons.favorite_rounded;
        color = RaikoColors.textMuted;
      case 'command.send':
        icon = Icons.send_rounded;
        color = RaikoColors.accent;
      default:
        icon = Icons.circle_outlined;
        color = RaikoColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.detail,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${event.type} \u2022 ${event.actorId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Text(
            formatTimeAgo(event.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: RaikoColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RaikoColors.textMuted,
              ),
        ),
      ),
    );
  }
}

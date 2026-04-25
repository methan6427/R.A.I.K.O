import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_ws_client.dart';

class ConnectionStatusPanel extends StatefulWidget {
  const ConnectionStatusPanel({
    super.key,
    required this.client,
    required this.onReconnect,
  });

  final RaikoWsClient client;
  final VoidCallback onReconnect;

  @override
  State<ConnectionStatusPanel> createState() => _ConnectionStatusPanelState();
}

class _ConnectionStatusPanelState extends State<ConnectionStatusPanel> {
  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onClientChanged);
  }

  @override
  void dispose() {
    widget.client.removeListener(_onClientChanged);
    super.dispose();
  }

  void _onClientChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.client.isConnected;
    final isConnecting = widget.client.isConnecting;
    final statusColor = isConnected
        ? RaikoColors.success
        : isConnecting
            ? RaikoColors.warning
            : RaikoColors.danger;
    final statusText = isConnected
        ? 'Connected'
        : isConnecting
            ? 'Connecting...'
            : 'Disconnected';

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WebSocket: ${widget.client.websocketUrl}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: RaikoColors.textMuted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isConnected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 32,
                    child: RaikoButton(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      isSecondary: true,
                      expand: false,
                      onPressed: widget.onReconnect,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.client.lastError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RaikoColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: RaikoColors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Error',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: RaikoColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.client.lastError ?? 'Unknown error',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: RaikoColors.textMuted,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          if (widget.client.agents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.devices_rounded,
                  size: 16,
                  color: RaikoColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.client.agents.length} agent${widget.client.agents.length == 1 ? '' : 's'} connected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

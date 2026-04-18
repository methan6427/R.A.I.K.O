import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

enum RaikoConnectionState { offline, connecting, connected }

class RaikoConnectionIndicator extends StatefulWidget {
  const RaikoConnectionIndicator({
    super.key,
    required this.state,
    this.agentCount = 0,
  });

  final RaikoConnectionState state;
  final int agentCount;

  @override
  State<RaikoConnectionIndicator> createState() =>
      _RaikoConnectionIndicatorState();
}

class _RaikoConnectionIndicatorState extends State<RaikoConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(RaikoConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == RaikoConnectionState.connecting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = widget.state == RaikoConnectionState.connected
          ? 1.0
          : 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (widget.state) {
      case RaikoConnectionState.connected:
        color = RaikoColors.success;
        label = widget.agentCount > 0
            ? '${widget.agentCount} agent${widget.agentCount > 1 ? 's' : ''} linked'
            : 'Connected';
        icon = Icons.link_rounded;
      case RaikoConnectionState.connecting:
        color = RaikoColors.warning;
        label = 'Connecting...';
        icon = Icons.sync_rounded;
      case RaikoConnectionState.offline:
        color = RaikoColors.danger;
        label = 'Offline';
        icon = Icons.link_off_rounded;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.withValues(
                alpha: widget.state == RaikoConnectionState.connecting
                    ? 0.2 + (_controller.value * 0.3)
                    : 0.3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'raiko_card.dart';
import 'raiko_status_badge.dart';

class RaikoDeviceTile extends StatelessWidget {
  const RaikoDeviceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    this.icon = Icons.memory_rounded,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final stacked = constraints.maxWidth < 440;

        return RaikoCard(
          padding: const EdgeInsets.all(18),
          child: stacked ? _buildStacked(context) : _buildInline(context),
        );
      },
    );
  }

  Widget _buildInline(BuildContext context) {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 16),
        Expanded(child: _buildText(context)),
        _buildMeta(),
      ],
    );
  }

  Widget _buildStacked(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(child: _buildText(context)),
          ],
        ),
        const SizedBox(height: 14),
        _buildMeta(),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: RaikoColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: RaikoColors.accentStrong),
    );
  }

  Widget _buildText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RaikoStatusBadge(label: statusLabel, color: statusColor),
        if (trailing != null) ...[
          const SizedBox(height: 10),
          trailing!,
        ],
      ],
    );
  }
}

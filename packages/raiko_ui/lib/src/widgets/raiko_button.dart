import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class RaikoButton extends StatelessWidget {
  const RaikoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDanger = false,
    this.isSecondary = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDanger;
  final bool isSecondary;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final background = isDanger
        ? RaikoColors.danger
        : isSecondary
            ? RaikoColors.backgroundRaised
            : RaikoColors.accent;
    final foreground = isDanger || isSecondary ? RaikoColors.textPrimary : RaikoColors.backgroundDeep;
    final side = isSecondary
        ? const BorderSide(color: RaikoColors.borderStrong)
        : BorderSide(color: background.withValues(alpha: 0.2));
    final style = FilledButton.styleFrom(
      backgroundColor: background,
      disabledBackgroundColor: RaikoColors.backgroundRaised,
      foregroundColor: foreground,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: side,
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
    final child = icon == null
        ? FilledButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 22),
            label: Text(label),
          );

    if (!expand) {
      return child;
    }

    return SizedBox(width: double.infinity, child: child);
  }
}

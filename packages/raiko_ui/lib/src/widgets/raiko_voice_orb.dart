import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class RaikoVoiceOrb extends StatelessWidget {
  const RaikoVoiceOrb({
    super.key,
    required this.label,
    this.size = 160,
    this.isActive = true,
    this.onPressed,
    this.tooltip,
  });

  final String label;
  final double size;
  final bool isActive;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final glowColor = isActive ? RaikoColors.accentStrong : RaikoColors.textMuted;
    final orb = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: isActive ? 1.0 : 0.97),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white,
              isActive ? RaikoColors.accentStrong : RaikoColors.accent,
              const Color(0xFF14233F),
            ],
            stops: const [0.0, 0.22, 1.0],
          ),
          border: Border.all(color: glowColor.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(color: glowColor.withValues(alpha: 0.42), blurRadius: 42, spreadRadius: 6),
            const BoxShadow(color: Color(0x66000000), blurRadius: 22, offset: Offset(0, 18)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: RaikoColors.backgroundDeep,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
          ),
        ),
      ),
    );

    if (onPressed == null) {
      return orb;
    }

    return Semantics(
      button: true,
      label: tooltip ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip ?? label,
            child: orb,
          ),
        ),
      ),
    );
  }
}

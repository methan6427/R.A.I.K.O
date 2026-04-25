import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class RaikoVoiceOrb extends StatefulWidget {
  const RaikoVoiceOrb({
    super.key,
    required this.label,
    this.size = 160,
    this.isActive = true,
    this.voiceState,
    this.onPressed,
    this.tooltip,
  });

  final String label;
  final double size;
  final bool isActive;
  final dynamic voiceState;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  State<RaikoVoiceOrb> createState() => _RaikoVoiceOrbState();
}

class _RaikoVoiceOrbState extends State<RaikoVoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RaikoVoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stateStr = widget.voiceState?.toString() ?? '';
    final shouldAnimate = widget.isActive &&
        (stateStr.endsWith('listening') ||
            stateStr.endsWith('processing') ||
            stateStr.endsWith('speaking'));

    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStateColor() {
    final stateStr = widget.voiceState?.toString() ?? '';
    if (stateStr.endsWith('listening')) {
      return RaikoColors.accentStrong;
    } else if (stateStr.endsWith('processing')) {
      return const Color(0xFF6366F1);
    } else if (stateStr.endsWith('confirming')) {
      return RaikoColors.warning;
    } else if (stateStr.endsWith('executing')) {
      return const Color(0xFF8B5CF6);
    } else if (stateStr.endsWith('speaking')) {
      return const Color(0xFF06B6D4);
    } else if (stateStr.endsWith('error')) {
      return RaikoColors.danger;
    }
    return RaikoColors.accent.withValues(alpha: 0.5);
  }

  String _getStateLabel() {
    final stateStr = widget.voiceState?.toString() ?? '';
    if (stateStr.endsWith('listening')) {
      return 'Listening...';
    } else if (stateStr.endsWith('processing')) {
      return 'Processing...';
    } else if (stateStr.endsWith('confirming')) {
      return 'Confirm?';
    } else if (stateStr.endsWith('executing')) {
      return 'Executing...';
    } else if (stateStr.endsWith('speaking')) {
      return 'Speaking...';
    } else if (stateStr.endsWith('error')) {
      return 'Error';
    }
    return widget.label;
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor();
    final glowColor = widget.isActive ? stateColor : RaikoColors.textMuted;
    final stateStr = widget.voiceState?.toString() ?? '';
    final shouldPulse = widget.isActive &&
        (stateStr.endsWith('listening') ||
            stateStr.endsWith('processing') ||
            stateStr.endsWith('speaking'));

    final orb = AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: shouldPulse ? _pulseAnimation.value : 0.97,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  stateColor,
                  const Color(0xFF14233F),
                ],
                stops: const [0.0, 0.25, 1.0],
              ),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: widget.isActive ? _glowAnimation.value : 0.15,
                  ),
                  blurRadius: widget.isActive ? 48 : 20,
                  spreadRadius: widget.isActive ? 8 : 2,
                ),
                const BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        );
      },
      child: Text(
        _getStateLabel(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: RaikoColors.backgroundDeep,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
      ),
    );

    if (widget.onPressed == null) {
      return orb;
    }

    return Semantics(
      button: true,
      label: widget.tooltip ?? widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: widget.tooltip ?? widget.label,
            child: orb,
          ),
        ),
      ),
    );
  }
}

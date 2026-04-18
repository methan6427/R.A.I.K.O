import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_theme/shared_theme.dart';

class RaikoCommandButton extends StatefulWidget {
  const RaikoCommandButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.isDanger = false,
    this.isDisabled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isDanger;
  final bool isDisabled;

  @override
  State<RaikoCommandButton> createState() => _RaikoCommandButtonState();
}

class _RaikoCommandButtonState extends State<RaikoCommandButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.isDisabled) return;
    setState(() => _pressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    setState(() => _pressed = false);
    if (!widget.isDisabled) {
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDanger
        ? RaikoColors.danger
        : widget.color ?? RaikoColors.accentStrong;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.isDisabled ? 0.35 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: _pressed ? 0.25 : 0.12),
                      RaikoColors.card.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accentColor.withValues(
                      alpha: _pressed ? 0.6 : 0.25,
                    ),
                  ),
                  boxShadow: _pressed
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: accentColor,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.label,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: RaikoColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

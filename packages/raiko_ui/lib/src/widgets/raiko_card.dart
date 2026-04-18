import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class RaikoCard extends StatelessWidget {
  const RaikoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.height,
    this.blur = 18.0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RaikoColors.cardElevated.withValues(alpha: 0.55),
                RaikoColors.card.withValues(alpha: 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: RaikoColors.borderStrong.withValues(alpha: 0.40),
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return GestureDetector(onTap: onTap, child: card);
  }
}

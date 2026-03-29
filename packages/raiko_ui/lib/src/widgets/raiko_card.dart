import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class RaikoCard extends StatelessWidget {
  const RaikoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: RaikoColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RaikoColors.borderStrong.withValues(alpha: 0.75)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 28,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

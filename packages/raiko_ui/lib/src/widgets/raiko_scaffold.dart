import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class RaikoScaffold extends StatelessWidget {
  const RaikoScaffold({
    super.key,
    required this.body,
    this.maxContentWidth = 1440,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.bottomBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final Widget body;
  final double maxContentWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;
  final Widget? bottomBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: bottomNavigationBar != null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: RaikoColors.heroGradient),
        child: Stack(
          children: [
            const Positioned(top: -120, left: -80, child: _GlowBlob(size: 280, color: RaikoColors.accentSoft)),
            const Positioned(top: 80, right: -100, child: _GlowBlob(size: 320, color: RaikoColors.accentStrong)),
            const Positioned(bottom: -180, left: 40, child: _GlowBlob(size: 360, color: RaikoColors.accent)),
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final horizontal = math.max(20.0, math.min(40.0, constraints.maxWidth * 0.04));
                  final vertical = constraints.maxWidth < RaikoBreakpoints.compact ? 20.0 : 28.0;
                  final resolvedPadding =
                      padding ?? EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

                  return Align(
                    alignment: alignment,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: resolvedPadding,
                        child: Column(
                          children: [
                            Expanded(child: body),
                            if (bottomBar != null) ...[
                              const SizedBox(height: 16),
                              bottomBar!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.32),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

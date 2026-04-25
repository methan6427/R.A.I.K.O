import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({
    super.key,
    this.isUserSpeaking = false,
    this.isAssistantSpeaking = false,
    this.barCount = 40,
  });

  final bool isUserSpeaking;
  final bool isAssistantSpeaking;
  final int barCount;

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _barControllers;

  @override
  void initState() {
    super.initState();
    _initializeBarAnimations();
  }

  void _initializeBarAnimations() {
    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index % 5) * 50),
        vsync: this,
      ),
    );
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isUserSpeaking || widget.isAssistantSpeaking) {
      for (var controller in _barControllers) {
        controller.repeat(reverse: true);
      }
    } else {
      for (var controller in _barControllers) {
        controller.stop();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isUserSpeaking || widget.isAssistantSpeaking;
    final barColor = widget.isUserSpeaking
        ? RaikoColors.warning
        : widget.isAssistantSpeaking
            ? RaikoColors.accentStrong
            : RaikoColors.accentStrong.withValues(alpha: 0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                widget.barCount,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: AnimatedBuilder(
                    animation: _barControllers[index],
                    builder: (context, child) {
                      final height =
                          12 + (_barControllers[index].value * 20);
                      return Container(
                        width: 2,
                        height: height,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: barColor.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  )
                                ]
                              : [],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isUserSpeaking
              ? 'Listening...'
              : widget.isAssistantSpeaking
                  ? 'Speaking...'
                  : 'Ready',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

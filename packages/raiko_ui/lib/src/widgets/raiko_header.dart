import 'package:flutter/material.dart';

class RaikoHeader extends StatelessWidget {
  const RaikoHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final stacked = constraints.maxWidth < 720;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              Text(eyebrow!, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
            ],
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        );

        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (stacked) content else Expanded(child: content),
            if (trailing != null) ...[
              SizedBox(width: stacked ? 0 : 20, height: stacked ? 16 : 0),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}

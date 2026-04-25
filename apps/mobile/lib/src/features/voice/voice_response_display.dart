import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../core/voice/voice_models.dart';

class VoiceResponseDisplay extends StatelessWidget {
  const VoiceResponseDisplay({
    super.key,
    required this.state,
    this.transcribedText,
    this.parsedIntent,
    this.responseText,
    this.error,
  });

  final RaikoVoiceState state;
  final String? transcribedText;
  final RaikoIntent? parsedIntent;
  final String? responseText;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- State indicator ---
        _buildStateIndicator(context),
        const SizedBox(height: 16),

        // --- Transcribed text ---
        if (transcribedText != null && transcribedText!.isNotEmpty) ...[
          _buildSection(
            context,
            icon: Icons.mic_rounded,
            label: 'You said',
            color: RaikoColors.accentStrong,
            child: Text(
              transcribedText!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // --- Parsed intent ---
        if (parsedIntent != null && state != RaikoVoiceState.listening) ...[
          _buildSection(
            context,
            icon: Icons.psychology_rounded,
            label: 'Parsed Intent',
            color: const Color(0xFF6366F1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parsedIntent!.command,
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: RaikoColors.textMuted,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Target: ${parsedIntent!.targetAgent}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(parsedIntent!.confidence)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(parsedIntent!.confidence * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getConfidenceColor(parsedIntent!.confidence),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // --- Response text ---
        if (responseText != null && responseText!.isNotEmpty) ...[
          _buildSection(
            context,
            icon: Icons.volume_up_rounded,
            label: 'Response',
            color: const Color(0xFF06B6D4),
            child: Text(
              responseText!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // --- Error message ---
        if (error != null && error!.isNotEmpty)
          _buildSection(
            context,
            icon: Icons.error_outline_rounded,
            label: 'Error',
            color: RaikoColors.danger,
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: RaikoColors.danger,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildStateIndicator(BuildContext context) {
    final (label, color, icon) = switch (state) {
      RaikoVoiceState.listening => (
        'Listening...',
        RaikoColors.accentStrong,
        Icons.mic_rounded,
      ),
      RaikoVoiceState.processing => (
        'Processing...',
        const Color(0xFF6366F1),
        Icons.psychology_rounded,
      ),
      RaikoVoiceState.confirming => (
        'Awaiting confirmation...',
        RaikoColors.warning,
        Icons.help_outline_rounded,
      ),
      RaikoVoiceState.executing => (
        'Executing command...',
        const Color(0xFF8B5CF6),
        Icons.flash_on_rounded,
      ),
      RaikoVoiceState.speaking => (
        'Speaking response...',
        const Color(0xFF06B6D4),
        Icons.volume_up_rounded,
      ),
      RaikoVoiceState.error => ('Error occurred', RaikoColors.danger, Icons.error_rounded),
      RaikoVoiceState.idle => ('Ready', RaikoColors.textMuted, Icons.check_circle_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return RaikoColors.success;
    if (confidence >= 0.6) return RaikoColors.warning;
    return RaikoColors.danger;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../core/network/raiko_ws_client.dart';
import '../../core/voice/raiko_voice_engine.dart';
import '../../core/voice/voice_models.dart';
import 'voice_response_display.dart';
import 'waveform_visualizer.dart';

class VoiceRelayModal extends StatefulWidget {
  const VoiceRelayModal({
    super.key,
    required this.voiceEngine,
    required this.client,
  });

  final RaikoVoiceEngine voiceEngine;
  final RaikoWsClient client;

  @override
  State<VoiceRelayModal> createState() => _VoiceRelayModalState();
}

class _VoiceRelayModalState extends State<VoiceRelayModal> {
  late final TextEditingController _textController;
  bool _isUserSpeaking = false;
  bool _isAssistantSpeaking = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    widget.voiceEngine.addListener(_onVoiceStateChanged);
  }

  @override
  void dispose() {
    widget.voiceEngine.removeListener(_onVoiceStateChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onVoiceStateChanged() {
    setState(() {
      _isUserSpeaking = widget.voiceEngine.state == RaikoVoiceState.listening;
      _isAssistantSpeaking = widget.voiceEngine.state == RaikoVoiceState.speaking;
    });
  }

  Future<void> _processTextCommand() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    try {
      await widget.voiceEngine.processTextCommand(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.voiceEngine.state == RaikoVoiceState.idle;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RaikoColors.backgroundRaised.withValues(alpha: 0.95),
            RaikoColors.background.withValues(alpha: 0.98),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: RaikoColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        color: RaikoColors.accentStrong,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Relay',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: RaikoColors.textPrimary,
                                  ),
                            ),
                            if (widget.voiceEngine.lastError != null)
                              Text(
                                'Error: ${widget.voiceEngine.lastError}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: RaikoColors.danger,
                                    ),
                              )
                            else
                              Text(
                                'Control your agents with voice or text',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: RaikoColors.textSecondary,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Waveform Visualizer
            if (!isIdle)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: WaveformVisualizer(
                  isUserSpeaking: _isUserSpeaking,
                  isAssistantSpeaking: _isAssistantSpeaking,
                ),
              ),

            // Voice orb (large) - only show when active or idle, not during processing
            if (isIdle || widget.voiceEngine.state == RaikoVoiceState.listening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: RaikoColors.accentStrong
                                  .withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Orb
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              RaikoColors.accentStrong,
                              RaikoColors.accentSoft,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: RaikoColors.accentStrong
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Content based on state
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isIdle) ...[
                    // Text input
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a command...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: RaikoColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: RaikoColors.accentStrong,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: RaikoButton(
                            label: 'Start Voice',
                            icon: Icons.mic_rounded,
                            onPressed: (widget.client.selectedAgentId.isEmpty ||
                                    !widget.voiceEngine.isInitialized)
                                ? null
                                : () async {
                                    await widget.voiceEngine.activate();
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RaikoButton(
                            label: 'Send',
                            icon: Icons.send_rounded,
                            isSecondary: true,
                            onPressed: (_textController.text.isEmpty ||
                                    widget.client.selectedAgentId.isEmpty ||
                                    !widget.voiceEngine.isInitialized)
                                ? null
                                : _processTextCommand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RaikoButton(
                      label: 'Remote Desktop',
                      icon: Icons.desktop_mac_rounded,
                      isSecondary: true,
                      onPressed: widget.voiceEngine.isInitialized
                          ? () {
                              Navigator.of(context).pop();
                              widget.voiceEngine.openRemoteDesktop();
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Try saying:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: RaikoColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SuggestionChip(
                          label: '"Lock the PC"',
                        ),
                        _SuggestionChip(
                          label: '"Restart my workstation"',
                        ),
                        _SuggestionChip(
                          label: '"Put desktop to sleep"',
                        ),
                      ],
                    ),
                  ] else ...[
                    VoiceResponseDisplay(
                      state: widget.voiceEngine.state,
                      transcribedText: widget.voiceEngine.transcribedText,
                      parsedIntent: widget.voiceEngine.parsedIntent,
                      responseText: widget.voiceEngine.responseText,
                      error: widget.voiceEngine.lastError,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RaikoColors.accentStrong.withValues(alpha: 0.12),
        border: Border.all(
          color: RaikoColors.accentStrong.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: RaikoColors.accentStrong,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

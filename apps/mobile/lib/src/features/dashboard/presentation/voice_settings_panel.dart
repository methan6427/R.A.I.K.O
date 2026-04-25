import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/settings/raiko_settings_store.dart';

class VoiceSettingsPanel extends StatefulWidget {
  const VoiceSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final RaikoSettingsStore settings;
  final VoidCallback onSettingsChanged;

  @override
  State<VoiceSettingsPanel> createState() => _VoiceSettingsPanelState();
}

class _VoiceSettingsPanelState extends State<VoiceSettingsPanel> {
  late final TextEditingController _porcupineKeyController;
  late bool _confirmBeforeExecute;
  late int _listeningTimeout;

  @override
  void initState() {
    super.initState();
    _porcupineKeyController =
        TextEditingController(text: widget.settings.porcupineAccessKey ?? '');
    _confirmBeforeExecute = widget.settings.confirmBeforeExecute ?? true;
    _listeningTimeout = widget.settings.listeningTimeoutSeconds ?? 10;
  }

  @override
  void dispose() {
    _porcupineKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await widget.settings.savePorcupineAccessKey(_porcupineKeyController.text);
    await widget.settings.saveConfirmBeforeExecute(_confirmBeforeExecute);
    await widget.settings.saveListeningTimeout(_listeningTimeout);
    widget.onSettingsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic_rounded,
                color: RaikoColors.accentStrong,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Assistant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'API Keys',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: RaikoColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _porcupineKeyController,
            decoration: const InputDecoration(
              labelText: 'Porcupine Access Key',
              helperText: 'From picovoice.ai for wake word detection',
              prefixIcon: Icon(Icons.vpn_key_rounded, size: 18),
              isDense: true,
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: RaikoColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Confirm Before Execute',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              'Ask for confirmation before sending voice commands',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: RaikoColors.textMuted,
                  ),
            ),
            value: _confirmBeforeExecute,
            onChanged: (bool value) {
              setState(() {
                _confirmBeforeExecute = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Listening Timeout',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${_listeningTimeout}s',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RaikoColors.accentStrong,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Slider(
                min: 5,
                max: 30,
                divisions: 5,
                value: _listeningTimeout.toDouble(),
                onChanged: (double value) {
                  setState(() {
                    _listeningTimeout = value.toInt();
                  });
                },
              ),
              Text(
                'Maximum time to record voice input',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: RaikoColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          RaikoButton(
            label: 'Save Voice Settings',
            icon: Icons.check_rounded,
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }
}

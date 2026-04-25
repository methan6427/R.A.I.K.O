import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_ws_client.dart';
import '../../../core/settings/raiko_settings_store.dart';
import 'voice_settings_panel.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.client,
    required this.settings,
    required this.baseHttpUrlController,
    required this.websocketUrlController,
    required this.authTokenController,
    required this.deviceNameController,
    required this.onApplyConnectionSettings,
    required this.onApplyIdentitySettings,
    required this.onConnect,
    required this.onVoiceSettingsChanged,
  });

  final RaikoWsClient client;
  final RaikoSettingsStore settings;
  final TextEditingController baseHttpUrlController;
  final TextEditingController websocketUrlController;
  final TextEditingController authTokenController;
  final TextEditingController deviceNameController;
  final VoidCallback onApplyConnectionSettings;
  final VoidCallback onApplyIdentitySettings;
  final Future<void> Function() onConnect;
  final VoidCallback onVoiceSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        RaikoHeader(
          eyebrow: 'SETTINGS',
          title: 'Configuration',
          subtitle: 'Backend connection and device identity.',
          trailing: RaikoStatusBadge(
            label: client.lastError == null ? 'Healthy' : 'Error',
            color:
                client.lastError == null ? RaikoColors.success : RaikoColors.danger,
          ),
        ),
        const SizedBox(height: 24),

        // --- Backend endpoint ---
        RaikoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dns_outlined, color: RaikoColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Backend Endpoint',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: baseHttpUrlController,
                decoration: const InputDecoration(
                  labelText: 'HTTP URL',
                  prefixIcon: Icon(Icons.http_rounded, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: websocketUrlController,
                decoration: const InputDecoration(
                  labelText: 'WebSocket URL',
                  prefixIcon: Icon(Icons.cable_rounded, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: authTokenController,
                decoration: const InputDecoration(
                  labelText: 'Auth token',
                  prefixIcon: Icon(Icons.vpn_key_rounded, size: 18),
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: RaikoButton(
                      label: 'Apply',
                      icon: Icons.save_outlined,
                      isSecondary: true,
                      onPressed: onApplyConnectionSettings,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RaikoButton(
                      label: client.isConnecting
                          ? 'Connecting\u2026'
                          : (client.isConnected ? 'Reconnect' : 'Connect'),
                      icon: client.isConnecting
                          ? Icons.hourglass_top_rounded
                          : Icons.wifi_tethering_rounded,
                      onPressed: client.isConnecting ? null : onConnect,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Device identity ---
        RaikoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.badge_outlined, color: RaikoColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Device Identity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Device name',
                  prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              RaikoButton(
                label: 'Apply name',
                icon: Icons.check_rounded,
                isSecondary: true,
                onPressed: onApplyIdentitySettings,
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Device ID', value: client.deviceId),
              _InfoRow(label: 'Platform', value: client.platform),
              _InfoRow(
                label: 'Agent',
                value: client.selectedAgentId.isEmpty
                    ? 'none'
                    : client.selectedAgentId,
              ),
              _InfoRow(
                label: 'Token',
                value: client.authToken.isEmpty ? 'not set' : 'configured',
              ),
              if (client.lastError != null)
                _InfoRow(
                  label: 'Last Error',
                  value: client.lastError!,
                  isError: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Voice settings ---
        VoiceSettingsPanel(
          settings: settings,
          onSettingsChanged: onVoiceSettingsChanged,
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: RaikoColors.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isError ? RaikoColors.danger : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

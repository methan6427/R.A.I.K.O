import 'dart:async';

import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/config/raiko_backend_config.dart';
import '../../../core/identity/raiko_identity.dart';
import '../../../core/network/raiko_ws_client.dart';
import '../../../core/settings/raiko_settings_store.dart';
import 'activity_tab.dart';
import 'devices_tab.dart';
import 'home_tab.dart';
import 'settings_tab.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({
    super.key,
    required this.identity,
    required this.settings,
    this.initialBackendConfig = RaikoBackendConfig.defaults,
    this.autoStartBackend = true,
  });

  final RaikoIdentity identity;
  final RaikoSettingsStore settings;
  final RaikoBackendConfig initialBackendConfig;
  final bool autoStartBackend;

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  late final RaikoWsClient client;
  late final TextEditingController baseHttpUrlController;
  late final TextEditingController websocketUrlController;
  late final TextEditingController authTokenController;
  late final TextEditingController deviceNameController;
  int currentIndex = 0;
  String? _lastShownError;
  DateTime? _lastShownResultAt;

  @override
  void initState() {
    super.initState();
    client = RaikoWsClient(
      deviceId: widget.identity.deviceId,
      deviceName: widget.identity.deviceName,
      platform: widget.identity.platform,
      kind: 'mobile',
      initialConfig: widget.initialBackendConfig,
    )..addListener(_onChanged);
    baseHttpUrlController = TextEditingController(text: client.baseHttpUrl);
    websocketUrlController = TextEditingController(text: client.websocketUrl);
    authTokenController = TextEditingController(text: client.authToken);
    deviceNameController = TextEditingController(text: client.deviceName);
    if (widget.autoStartBackend) {
      unawaited(client.start());
    }
  }

  @override
  void dispose() {
    baseHttpUrlController.dispose();
    websocketUrlController.dispose();
    authTokenController.dispose();
    deviceNameController.dispose();
    client.removeListener(_onChanged);
    client.disconnect();
    client.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (baseHttpUrlController.text != client.baseHttpUrl) {
      baseHttpUrlController.text = client.baseHttpUrl;
    }
    if (websocketUrlController.text != client.websocketUrl) {
      websocketUrlController.text = client.websocketUrl;
    }
    if (authTokenController.text != client.authToken) {
      authTokenController.text = client.authToken;
    }

    if (mounted) {
      setState(() {});
      _maybeShowSnackbars();
    }
  }

  void _maybeShowSnackbars() {
    final currentError = client.lastError;
    if (currentError != null && currentError != _lastShownError) {
      _lastShownError = currentError;
      _showSnack(
        currentError,
        color: RaikoColors.danger,
        icon: Icons.error_outline_rounded,
      );
    } else if (currentError == null) {
      _lastShownError = null;
    }

    final result = client.lastCommandResult;
    if (result != null && result.receivedAt != _lastShownResultAt) {
      _lastShownResultAt = result.receivedAt;
      final isOk = result.status.toLowerCase() == 'success';
      final detail = result.output.trim().isEmpty
          ? ''
          : ' \u2022 ${result.output.trim()}';
      _showSnack(
        '${result.action.toUpperCase()} \u2192 ${result.status}$detail',
        color: isOk ? RaikoColors.success : RaikoColors.danger,
        icon: isOk
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
      );
    }
  }

  void _showSnack(
    String message, {
    required Color color,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color.withValues(alpha: 0.94),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyAndPersistIdentitySettings() async {
    client.updateDeviceName(deviceNameController.text);
    await widget.settings.saveDeviceName(deviceNameController.text);
  }

  Future<void> _applyAndPersistConnectionSettings() async {
    client.updateConnectionSettings(
      baseHttpUrl: baseHttpUrlController.text,
      websocketUrl: websocketUrlController.text,
      authToken: authTokenController.text,
    );
    await widget.settings.save(
      RaikoBackendConfig(
        baseHttpUrl: client.baseHttpUrl,
        websocketUrl: client.websocketUrl,
        authToken: client.authToken,
      ),
    );
  }

  Future<void> _connect() async {
    await _applyAndPersistConnectionSettings();
    await client.reconnect();
    await client.loadOverview();
  }

  void _showVoiceConsole() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: RaikoCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      color: RaikoColors.accentStrong,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice Relay',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Voice commands for agent control.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RaikoColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: RaikoButton(
                        label: 'Lock',
                        icon: Icons.lock_outline_rounded,
                        onPressed: client.selectedAgentId.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                client.sendCommand('lock');
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RaikoButton(
                        label: 'Sleep',
                        icon: Icons.nightlight_round,
                        isSecondary: true,
                        onPressed: client.selectedAgentId.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                client.sendCommand('sleep');
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Try saying:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: RaikoColors.textMuted,
                      ),
                ),
                const SizedBox(height: 8),
                for (final phrase in const [
                  '"Raiko, lock the office PC"',
                  '"Raiko, restart my workstation"',
                  '"Raiko, put the desktop to sleep"',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      phrase,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: RaikoColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeTab(client: client, onConnect: _connect),
      DevicesTab(client: client),
      ActivityTab(client: client),
      SettingsTab(
        client: client,
        baseHttpUrlController: baseHttpUrlController,
        websocketUrlController: websocketUrlController,
        authTokenController: authTokenController,
        deviceNameController: deviceNameController,
        onApplyConnectionSettings: () {
          unawaited(_applyAndPersistConnectionSettings());
        },
        onApplyIdentitySettings: () {
          unawaited(_applyAndPersistIdentitySettings());
        },
        onConnect: _connect,
      ),
    ];

    return RaikoScaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 72,
        height: 72,
        child: RaikoVoiceOrb(
          label: 'AI',
          size: 72,
          isActive: client.isConnected,
          tooltip: 'Open voice relay',
          onPressed: _showVoiceConsole,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: RaikoColors.backgroundDeep.withValues(
                  alpha: 0.85,
                ),
                surfaceTintColor: Colors.transparent,
                indicatorColor: RaikoColors.accentStrong.withValues(alpha: 0.12),
                iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
                  (Set<WidgetState> states) => IconThemeData(
                    color: states.contains(WidgetState.selected)
                        ? RaikoColors.accentStrong
                        : RaikoColors.textMuted,
                    size: 22,
                  ),
                ),
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                  (Set<WidgetState> states) =>
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: states.contains(WidgetState.selected)
                            ? RaikoColors.textPrimary
                            : RaikoColors.textMuted,
                        fontWeight: states.contains(WidgetState.selected)
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                ),
              ),
              child: NavigationBar(
                height: 64,
                selectedIndex: currentIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.devices_outlined),
                    selectedIcon: Icon(Icons.devices_rounded),
                    label: 'Devices',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timeline_outlined),
                    selectedIcon: Icon(Icons.timeline_rounded),
                    label: 'Activity',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

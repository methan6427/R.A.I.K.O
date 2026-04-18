import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import 'core/config/raiko_backend_config.dart';
import 'core/identity/raiko_identity.dart';
import 'core/settings/raiko_settings_store.dart';
import 'features/dashboard/presentation/mobile_dashboard_screen.dart';

class RaikoMobileApp extends StatelessWidget {
  RaikoMobileApp({
    super.key,
    RaikoIdentity? identity,
    RaikoSettingsStore? settings,
    this.initialBackendConfig = RaikoBackendConfig.defaults,
    this.autoStartBackend = true,
  }) : identity = identity ?? RaikoIdentity.fallback,
       settings = settings ?? RaikoSettingsStore.inMemory();

  final RaikoIdentity identity;
  final RaikoSettingsStore settings;
  final RaikoBackendConfig initialBackendConfig;
  final bool autoStartBackend;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'R.A.I.K.O Mobile',
      theme: buildRaikoTheme(),
      home: MobileDashboardScreen(
        identity: identity,
        settings: settings,
        initialBackendConfig: initialBackendConfig,
        autoStartBackend: autoStartBackend,
      ),
    );
  }
}

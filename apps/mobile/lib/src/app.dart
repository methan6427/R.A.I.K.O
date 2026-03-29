import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'core/config/raiko_backend_config.dart';
import 'features/dashboard/presentation/mobile_dashboard_screen.dart';

class RaikoMobileApp extends StatelessWidget {
  const RaikoMobileApp({
    super.key,
    this.initialBackendConfig = RaikoBackendConfig.defaults,
    this.autoStartBackend = true,
  });

  final RaikoBackendConfig initialBackendConfig;
  final bool autoStartBackend;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'R.A.I.K.O Mobile',
      theme: buildRaikoTheme(),
      home: MobileDashboardScreen(
        initialBackendConfig: initialBackendConfig,
        autoStartBackend: autoStartBackend,
      ),
    );
  }
}

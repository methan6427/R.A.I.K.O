import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'core/settings/desktop_settings_store.dart';
import 'features/dashboard/presentation/desktop_dashboard_screen.dart';

class RaikoDesktopApp extends StatelessWidget {
  const RaikoDesktopApp({super.key, required this.initialSettings});

  final DesktopSettings initialSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'R.A.I.K.O Desktop',
      theme: buildRaikoTheme(),
      home: DesktopDashboardScreen(initialSettings: initialSettings),
    );
  }
}

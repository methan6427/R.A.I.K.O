import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'features/dashboard/presentation/desktop_dashboard_screen.dart';

class RaikoDesktopApp extends StatelessWidget {
  const RaikoDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'R.A.I.K.O Desktop',
      theme: buildRaikoTheme(),
      home: const DesktopDashboardScreen(),
    );
  }
}
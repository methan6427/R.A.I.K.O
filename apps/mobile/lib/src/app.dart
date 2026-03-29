import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'features/dashboard/presentation/mobile_dashboard_screen.dart';

class RaikoMobileApp extends StatelessWidget {
  const RaikoMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'R.A.I.K.O Mobile',
      theme: buildRaikoTheme(),
      home: const MobileDashboardScreen(),
    );
  }
}
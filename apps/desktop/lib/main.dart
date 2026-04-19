import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/core/settings/desktop_settings_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = DesktopSettingsStore.load();
  runApp(RaikoDesktopApp(initialSettings: settings));
}

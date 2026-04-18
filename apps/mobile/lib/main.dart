import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/identity/raiko_identity.dart';
import 'src/core/settings/raiko_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final identity = await RaikoIdentity.resolve(prefs);
  final settings = RaikoSettingsStore.wrap(prefs);
  final initialConfig = settings.load();

  runApp(
    RaikoMobileApp(
      identity: identity,
      settings: settings,
      initialBackendConfig: initialConfig,
    ),
  );
}

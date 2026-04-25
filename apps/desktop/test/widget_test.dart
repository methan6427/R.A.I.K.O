import 'package:flutter_test/flutter_test.dart';
import 'package:raiko_desktop/src/app.dart';
import 'package:raiko_desktop/src/core/settings/desktop_settings_store.dart';

void main() {
  testWidgets('renders desktop dashboard shell', (WidgetTester tester) async {
    const settings = DesktopSettings(
      backendUrl: 'ws://localhost:8080/ws',
      authToken: 'test-token',
      deviceName: 'Test Desktop',
      agentName: 'Test Agent',
    );

    await tester.pumpWidget(const RaikoDesktopApp(initialSettings: settings));

    expect(find.text('Operations Bridge'), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:raiko_mobile/src/app.dart';

void main() {
  testWidgets('renders mobile dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(RaikoMobileApp(autoStartBackend: false));

    expect(find.text('R.A.I.K.O'), findsOneWidget);
    expect(find.text('Remote Kernel Operator'), findsOneWidget);
  });
}

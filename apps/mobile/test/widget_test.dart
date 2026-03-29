import 'package:flutter_test/flutter_test.dart';
import 'package:raiko_mobile/src/app.dart';

void main() {
  testWidgets('renders mobile dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const RaikoMobileApp());

    expect(find.text('Remote Kernel'), findsOneWidget);
  });
}
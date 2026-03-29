import 'package:flutter_test/flutter_test.dart';
import 'package:raiko_desktop/src/app.dart';

void main() {
  testWidgets('renders desktop dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const RaikoDesktopApp());

    expect(find.text('Operations Bridge'), findsOneWidget);
  });
}
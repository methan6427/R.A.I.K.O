import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

void main() {
  testWidgets('RaikoButton renders label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRaikoTheme(),
        home: Scaffold(
          body: const RaikoButton(label: 'Execute', onPressed: null),
        ),
      ),
    );

    expect(find.text('Execute'), findsOneWidget);
  });

  testWidgets('RaikoScaffold hosts content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRaikoTheme(),
        home: const RaikoScaffold(
          body: Center(child: Text('System Online')),
        ),
      ),
    );

    expect(find.text('System Online'), findsOneWidget);
  });
}

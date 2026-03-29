import 'package:flutter_test/flutter_test.dart';
import 'package:shared_theme/shared_theme.dart';

void main() {
  test('buildRaikoTheme exposes configured scaffold color', () {
    final theme = buildRaikoTheme();

    expect(theme.scaffoldBackgroundColor, RaikoColors.background);
  });
}
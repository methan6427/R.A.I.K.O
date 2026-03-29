# shared_theme

Shared design tokens and theme configuration for the R.A.I.K.O Flutter apps.

## Includes

- R.A.I.K.O color palette and gradients
- Shared responsive breakpoints
- Material 3 dark theme tuned for the project UI

## Usage

```dart
import 'package:shared_theme/shared_theme.dart';

MaterialApp(
  theme: buildRaikoTheme(),
  home: const Placeholder(),
);
```

Use this package together with `raiko_ui` to keep the mobile and desktop clients visually aligned.

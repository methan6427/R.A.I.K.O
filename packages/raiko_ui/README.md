# raiko_ui

Shared Flutter widgets for the R.A.I.K.O clients.

## Included Widgets

- `RaikoScaffold` for the shared gradient shell and responsive content frame
- `RaikoCard` for elevated content panels
- `RaikoButton` for primary, secondary, and danger actions
- `RaikoHeader` for page-level titles and eyebrow metadata
- `RaikoDeviceTile` for connected device summaries
- `RaikoStatusBadge` for compact online and offline state
- `RaikoVoiceOrb` for the branded voice trigger and status centerpiece

## Usage

```dart
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

MaterialApp(
  theme: buildRaikoTheme(),
  home: const RaikoScaffold(
    body: Center(
      child: RaikoCard(
        child: Text('R.A.I.K.O'),
      ),
    ),
  ),
);
```

Use this package together with `shared_theme`.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'routing/app_router.dart';
import 'theme/theme.dart';

/// Root widget: builds the approved theme (with high-contrast and
/// reduced-motion variants from settings), clamps text scaling at 200%
/// per the accessibility contract, and wires declarative routing.
class TinyCanvasApp extends StatelessWidget {
  const TinyCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.select((AppState s) => s.settings);
    return MaterialApp(
      title: 'TinyCanvas Adventures',
      debugShowCheckedModeBanner: false,
      theme: buildTinyCanvasTheme(
        highContrast: settings.highContrast,
        reduceMotion: settings.reducedMotion,
      ),
      initialRoute: Routes.splash,
      onGenerateRoute: onGenerateRoute,
      builder: (context, child) {
        // Support OS text sizes up to 200% without breaking layouts;
        // larger values are clamped so controls stay reachable.
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 2.0,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

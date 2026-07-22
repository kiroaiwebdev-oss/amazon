import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinycanvas_adventures/app/theme/theme.dart';
import 'package:tinycanvas_adventures/features/onboarding/onboarding_screens.dart';

import 'responsive_test.dart' show kFireSizes;

/// Widget smoke tests across the 8 representative Fire tablet sizes in both
/// orientations, plus 200% text and high-contrast variants.
void main() {
  Widget host(Widget child,
      {bool highContrast = false,
      bool reduceMotion = false,
      double textScale = 1.0}) {
    return MaterialApp(
      theme: buildTinyCanvasTheme(
          highContrast: highContrast, reduceMotion: reduceMotion),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    );
  }

  testWidgets('Welcome renders at all 8 Fire sizes without overflow',
      (tester) async {
    for (final size in kFireSizes) {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      await tester.pumpWidget(host(const WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Make a little world of color.'), findsOneWidget,
          reason: 'welcome headline at $size');
      expect(tester.takeException(), isNull, reason: 'no overflow at $size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Welcome copes with 200% text', (tester) async {
    tester.view.physicalSize = const Size(600, 1024) * 2;
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(host(const WelcomeScreen(), textScale: 2.0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('How to Color renders in portrait and landscape',
      (tester) async {
    for (final size in const [Size(800, 1280), Size(1280, 800)]) {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      await tester.pumpWidget(host(const HowToColorScreen()));
      await tester.pumpAndSettle();
      expect(find.text('One finger colors'), findsOneWidget);
      expect(find.text('Two fingers move & zoom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('high-contrast theme builds and renders', (tester) async {
    await tester
        .pumpWidget(host(const WelcomeScreen(), highContrast: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

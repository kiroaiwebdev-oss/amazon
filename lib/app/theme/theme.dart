import 'package:flutter/material.dart';

import 'tokens.dart';

/// Theme extension carrying the approved TinyCanvas design-system values that
/// don't map onto stock [ThemeData] slots. Widgets read tokens through this
/// so high-contrast mode can adjust them centrally.
class TcThemeX extends ThemeExtension<TcThemeX> {
  const TcThemeX({
    required this.ink,
    required this.muted,
    required this.line,
    required this.highContrast,
    required this.reduceMotion,
  });

  final Color ink;
  final Color muted;
  final Color line;
  final bool highContrast;
  final bool reduceMotion;

  Duration motion(Duration base) => reduceMotion ? Duration.zero : base;

  @override
  TcThemeX copyWith({
    Color? ink,
    Color? muted,
    Color? line,
    bool? highContrast,
    bool? reduceMotion,
  }) =>
      TcThemeX(
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        line: line ?? this.line,
        highContrast: highContrast ?? this.highContrast,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  @override
  TcThemeX lerp(TcThemeX? other, double t) => other ?? this;

  static TcThemeX of(BuildContext context) =>
      Theme.of(context).extension<TcThemeX>()!;
}

ThemeData buildTinyCanvasTheme({
  bool highContrast = false,
  bool reduceMotion = false,
}) {
  final ink = highContrast ? TcColors.hcInk : TcColors.ink;
  final muted = highContrast ? TcColors.hcMuted : TcColors.muted;
  final line = highContrast ? TcColors.hcLine : TcColors.line;

  final base = ThemeData(
    useMaterial3: true,
    fontFamily: TcType.fontFamily,
    scaffoldBackgroundColor: TcColors.canvas,
    colorScheme: ColorScheme.light(
      primary: TcColors.blue,
      secondary: TcColors.coral,
      surface: TcColors.paper,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ink,
      error: TcColors.dangerText,
    ),
    splashFactory: reduceMotion ? NoSplash.splashFactory : null,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .copyWith(
          displaySmall: TcType.h1Hero,
          headlineMedium: TcType.h1.copyWith(color: ink),
          titleLarge: TcType.h2.copyWith(color: ink),
          titleMedium: TcType.h3.copyWith(color: ink),
          bodyMedium: TcType.sub.copyWith(color: muted),
          labelLarge: TcType.button,
        )
        .apply(bodyColor: ink, displayColor: ink),
    dividerColor: line,
    dialogTheme: DialogThemeData(
      backgroundColor: TcColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TcRadius.modal),
      ),
    ),
    extensions: [
      TcThemeX(
        ink: ink,
        muted: muted,
        line: line,
        highContrast: highContrast,
        reduceMotion: reduceMotion,
      ),
    ],
  );
}

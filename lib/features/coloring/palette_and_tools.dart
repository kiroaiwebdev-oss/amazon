import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import 'canvas_painter.dart';
import 'coloring_document.dart';
import 'coloring_engine.dart';

/// Screens 13-15 + canvas dialogs: color palette, tool settings, sticker
/// drawer, clear-canvas confirmation and the save-failure choices.

/// Rounded paper bottom sheet used by the portrait canvas layout.
Future<T?> showCanvasSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: TcColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TcRadius.panel)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 14,
          bottom: 22 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: TcColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(title,
                style:
                    TcType.h3.copyWith(color: TcThemeX.of(context).ink)),
          ),
          const SizedBox(height: 14),
          Flexible(child: SingleChildScrollView(child: child)),
        ]),
      ),
    ),
  );
}

/// Screen 13 - Color palette: 24 named colors + recent colors.
class ColorPalettePanel extends StatelessWidget {
  const ColorPalettePanel({super.key, required this.engine, this.onPicked});

  final ColoringEngine engine;
  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (engine.recentColorValues.isNotEmpty) ...[
              const TcEyebrow('Recent colors'),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final value in engine.recentColorValues)
                  ColorSwatchButton(
                    color: Color(value),
                    name: TcPalette.nameOf(Color(value)),
                    selected: engine.colorValue == value,
                    onTap: () {
                      engine.selectColor(value);
                      onPicked?.call();
                    },
                  ),
              ]),
              const SizedBox(height: 16),
            ],
            const TcEyebrow('All colors'),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final named in TcPalette.colors)
                ColorSwatchButton(
                  color: named.color,
                  name: named.name,
                  selected: engine.colorValue == named.color.value,
                  onTap: () {
                    engine.selectColor(named.color.value);
                    onPicked?.call();
                  },
                ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Every color has a spoken name for screen readers.',
              style: TcType.rowSubtitle.copyWith(color: x.muted),
            ),
          ],
        );
      },
    );
  }
}

/// Approved swatch: 28px rounded square, gold ring when selected, named
/// for TalkBack, with a comfortable 44+ tap target.
class ColorSwatchButton extends StatelessWidget {
  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
    this.size = TcSize.swatch,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$name color',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? TcColors.gold : TcColors.line,
                width: selected ? 3 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22172533),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 14 - Tool settings: size, opacity, fill tolerance.
class ToolSettingsPanel extends StatelessWidget {
  const ToolSettingsPanel({super.key, required this.engine});

  final ColoringEngine engine;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${engine.tool.label} settings',
                style: TcType.rowTitle.copyWith(color: x.ink)),
            const SizedBox(height: 10),
            if (engine.tool != ToolKind.fill) ...[
              const TcEyebrow('Size'),
              Slider(
                value: engine.brushSize,
                min: ColoringEngine.minBrush,
                max: ColoringEngine.maxBrush,
                onChanged: engine.setBrushSize,
                semanticFormatterCallback: (v) =>
                    'Size ${((v - ColoringEngine.minBrush) / (ColoringEngine.maxBrush - ColoringEngine.minBrush) * 100).round()} percent',
              ),
              const TcEyebrow('Opacity'),
              Slider(
                value: engine.opacity,
                min: 0.1,
                max: 1,
                onChanged: engine.setOpacity,
                semanticFormatterCallback: (v) =>
                    'Opacity ${(v * 100).round()} percent',
              ),
            ] else ...[
              const TcEyebrow('Fill tolerance'),
              Slider(
                value: engine.fillTolerance,
                onChanged: engine.setFillTolerance,
                semanticFormatterCallback: (v) =>
                    'Fill tolerance ${(v * 100).round()} percent',
              ),
              Text(
                'Higher tolerance fills a wider area with one tap.',
                style: TcType.rowSubtitle.copyWith(color: x.muted),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Screen 15 - Sticker drawer (star, heart, flower, balloon, cloud,
/// butterfly). After placing, drag moves the sticker; pinch resizes and
/// rotates it while the Stamps tool is active.
class StickerDrawerPanel extends StatelessWidget {
  const StickerDrawerPanel({super.key, required this.engine, this.onPicked});

  final ColoringEngine engine;
  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final id in kStampIds)
                Semantics(
                  button: true,
                  selected: engine.stampId == id,
                  label: '$id sticker',
                  child: GestureDetector(
                    onTap: () {
                      engine.selectStamp(id);
                      onPicked?.call();
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(TcRadius.tool),
                        border: Border.all(
                          color: engine.stampId == id
                              ? TcColors.gold
                              : TcColors.line,
                          width: engine.stampId == id ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: StampPreview(
                          stampId: id,
                          color: engine.color,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Text(
              'Tap the paper to place a sticker. Drag to move it, pinch to '
              'resize and rotate.',
              style: TcType.rowSubtitle.copyWith(color: x.muted),
            ),
          ],
        );
      },
    );
  }
}

/// Clear-canvas confirmation (approved microcopy).
Future<bool> showClearCanvasDialog(BuildContext context) async {
  final result = await showTcModal<bool>(
    context,
    Builder(builder: (context) {
      return TcModalCard(
        icon: 'alert',
        title: 'Clear this picture?',
        body: 'All the coloring on this page will be wiped so you can start '
            'fresh. Your original line art stays safe.',
        actions: [
          TcButton(
            label: 'Yes, clear it',
            kind: TcButtonKind.coral,
            childFacing: true,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
          ),
          TcButton(
            label: 'Keep coloring',
            kind: TcButtonKind.soft,
            childFacing: true,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
          ),
        ],
      );
    }),
  );
  return result ?? false;
}

/// Choices offered by the Save Failed dialog.
enum SaveFailureChoice { tryAgain, keepEditing, leaveAnyway }

/// Save Failed state (approved microcopy). When [leaving] the third option
/// lets the caregiver leave without the last changes.
Future<SaveFailureChoice> showSaveFailureDialog(
  BuildContext context, {
  required bool leaving,
}) async {
  final result = await showTcModal<SaveFailureChoice>(
    context,
    Builder(builder: (context) {
      return TcModalCard(
        icon: 'alert',
        iconBg: TcColors.dangerBg,
        iconColor: TcColors.dangerText,
        title: 'We couldn\u2019t save yet',
        body: 'Your latest strokes are still on the screen, but the tablet '
            'couldn\u2019t store them. This can happen when storage is very '
            'full.',
        actions: [
          TcButton(
            label: 'Try again',
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .pop(SaveFailureChoice.tryAgain),
          ),
          TcButton(
            label: 'Keep coloring',
            kind: TcButtonKind.soft,
            childFacing: true,
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .pop(SaveFailureChoice.keepEditing),
          ),
          if (leaving)
            TcButton(
              label: 'Leave without saving',
              kind: TcButtonKind.danger,
              onPressed: () => Navigator.of(context, rootNavigator: true)
                  .pop(SaveFailureChoice.leaveAnyway),
            ),
        ],
      );
    }),
  );
  return result ?? SaveFailureChoice.keepEditing;
}

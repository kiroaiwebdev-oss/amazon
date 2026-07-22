import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinycanvas_adventures/features/coloring/coloring_document.dart';

void main() {
  ColoringDocument sample() {
    final doc = ColoringDocument.empty('tc_01_01');
    doc.ops.addAll([
      StrokeOp(
        tool: ToolKind.brush,
        colorValue: 0xFFEF6B67,
        size: 0.04,
        opacity: 1,
        points: const [Offset(0.1, 0.1), Offset(0.5, 0.55)],
      ),
      const FillOp(
          point: Offset(0.4, 0.4), colorValue: 0xFFF2BD55, tolerance: 0.5),
      const StampOp(
        stampId: 'star',
        center: Offset(0.7, 0.3),
        scale: 0.16,
        rotation: 0.4,
        colorValue: 0xFF58A678,
      ),
      const SplashOp(
          center: Offset(0.2, 0.8),
          colorValue: 0xFF69B3C8,
          size: 0.06,
          seed: 42),
    ]);
    return doc;
  }

  test('round-trips through JSON without losing any op', () {
    final doc = sample();
    final restored = ColoringDocument.fromJsonString(doc.toJsonString());
    expect(restored.catalogItemId, doc.catalogItemId);
    expect(restored.ops.length, doc.ops.length);
    expect(restored.toJsonString(), doc.toJsonString());
    final stroke = restored.ops.first as StrokeOp;
    expect(stroke.tool, ToolKind.brush);
    expect(stroke.points.length, 2);
  });

  test('normalized coordinates survive serialization (rotation safety)', () {
    final doc = sample();
    final restored = ColoringDocument.fromJsonString(doc.toJsonString());
    final fill = restored.ops[1] as FillOp;
    expect(fill.point.dx, closeTo(0.4, 0.0001));
    expect(fill.point.dy, closeTo(0.4, 0.0001));
  });

  test('corrupted content throws FormatException (recoverable)', () {
    expect(() => ColoringDocument.fromJsonString('not json'),
        throwsFormatException);
    expect(() => ColoringDocument.fromJsonString('{"nope": true}'),
        throwsFormatException);
  });

  test('effectiveOps drops everything before the last clear', () {
    final doc = sample();
    doc.ops.add(const ClearOp());
    expect(doc.effectiveOps, isEmpty);
    doc.ops.add(const SplashOp(
        center: Offset(0.5, 0.5),
        colorValue: 0xFF17253D,
        size: 0.05,
        seed: 7));
    expect(doc.effectiveOps.length, 1);
    // Undoing the clear (removing it) restores earlier ops.
  });

  test('empty document reports isEmpty and paper aspect matches source', () {
    final doc = ColoringDocument.empty('tc_01_01');
    expect(doc.isEmpty, isTrue);
    expect(ColoringDocument.paperAspect, closeTo(1.18, 0.001));
  });
}

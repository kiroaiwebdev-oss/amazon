import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinycanvas_adventures/features/coloring/coloring_document.dart';
import 'package:tinycanvas_adventures/features/coloring/coloring_engine.dart';

void main() {
  ColoringEngine makeEngine(InMemoryDocumentStore store,
          {Duration autosave = const Duration(milliseconds: 40)}) =>
      ColoringEngine(
        document: ColoringDocument.empty('tc_01_01'),
        store: store,
        documentPath: 'artworks/a1.json',
        autosaveDelay: autosave,
      );

  test('strokes commit and undo/redo restore exact history', () {
    final engine = makeEngine(InMemoryDocumentStore());
    engine.startStroke(const Offset(0.1, 0.1));
    engine.addStrokePoint(const Offset(0.3, 0.3));
    engine.endStroke();
    engine.tapFill(const Offset(0.5, 0.5));
    expect(engine.document.ops.length, 2);
    expect(engine.canUndo, isTrue);

    engine.undo();
    expect(engine.document.ops.length, 1);
    expect(engine.canRedo, isTrue);
    engine.redo();
    expect(engine.document.ops.length, 2);
    expect(engine.document.ops.last, isA<FillOp>());
    engine.dispose();
  });

  test('clear is undoable and effectiveOps reflect it', () {
    final engine = makeEngine(InMemoryDocumentStore());
    engine.tapFill(const Offset(0.5, 0.5));
    engine.clearCanvas();
    expect(engine.document.effectiveOps, isEmpty);
    engine.undo();
    expect(engine.document.effectiveOps.length, 1);
    engine.dispose();
  });

  test('stroke points are decimated (memory-aware history)', () {
    final engine = makeEngine(InMemoryDocumentStore());
    engine.startStroke(Offset.zero);
    for (var i = 0; i < 100; i++) {
      engine.addStrokePoint(Offset(0.0001 * i, 0)); // sub-threshold moves
    }
    final live = engine.liveOp as StrokeOp;
    expect(live.points.length, lessThan(10));
    engine.dispose();
  });

  test('idle autosave persists the document', () async {
    final store = InMemoryDocumentStore();
    final engine = makeEngine(store);
    engine.tapFill(const Offset(0.5, 0.5));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(engine.saveState, SaveState.saved);
    expect(store.files['artworks/a1.json'], isNotNull);
    final restored =
        ColoringDocument.fromJsonString(store.files['artworks/a1.json']!);
    expect(restored.ops.length, 1);
    engine.dispose();
  });

  test('failed save surfaces SaveState.failed and can recover', () async {
    final store = InMemoryDocumentStore()..failSaves = true;
    final engine = makeEngine(store);
    engine.tapFill(const Offset(0.5, 0.5));
    expect(await engine.saveNow(), isFalse);
    expect(engine.saveState, SaveState.failed);

    store.failSaves = false;
    expect(await engine.saveNow(), isTrue);
    expect(engine.saveState, SaveState.saved);
    engine.dispose();
  });

  test('zoom clamps between 1x and 4x and pan stays in bounds', () {
    final engine = makeEngine(InMemoryDocumentStore());
    engine.setZoom(9);
    expect(engine.zoom, 4);
    engine.setZoom(0.2);
    expect(engine.zoom, 1);
    expect(engine.pan, Offset.zero); // pan resets at 1x
    engine.setZoom(2);
    engine.panBy(const Offset(9, 9));
    expect(engine.pan.dx, lessThanOrEqualTo(0.25));
    expect(engine.pan.dy, lessThanOrEqualTo(0.25));
    engine.dispose();
  });

  test('recent colors track most-recent-first without duplicates', () {
    final engine = makeEngine(InMemoryDocumentStore());
    engine.selectColor(0xFF111111);
    engine.selectColor(0xFF222222);
    engine.selectColor(0xFF111111);
    expect(engine.recentColorValues.first, 0xFF111111);
    expect(
        engine.recentColorValues.where((c) => c == 0xFF111111).length, 1);
    engine.dispose();
  });

  test('splash ops are deterministic for a given seed', () {
    final engine = makeEngine(InMemoryDocumentStore());
    engine.addSplash(const Offset(0.5, 0.5));
    final splash = engine.document.ops.single as SplashOp;
    final again = ColoringDocument.fromJsonString(
            engine.document.toJsonString())
        .ops
        .single as SplashOp;
    expect(again.seed, splash.seed);
    engine.dispose();
  });
}

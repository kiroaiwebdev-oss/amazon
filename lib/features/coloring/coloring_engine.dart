import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../app/theme/tokens.dart';
import 'coloring_document.dart';

/// Save lifecycle surfaced by the canvas status chip.
enum SaveState { idle, saving, saved, failed }

// ---------------------------------------------------------------------------
// Document storage (atomic, recoverable)
// ---------------------------------------------------------------------------

abstract class DocumentStore {
  /// Returns the raw document, or null when it does not exist.
  Future<String?> load(String path);

  /// Atomic write: never leaves a half-written document behind.
  Future<void> save(String path, String raw);

  Future<void> delete(String path);
}

/// File-backed store. Saves write to a temp file first and then rename over
/// the target, so a crash mid-save leaves the previous good version intact.
class FileDocumentStore implements DocumentStore {
  @override
  Future<String?> load(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> save(String path, String raw) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final tmp = File('$path.tmp');
    await tmp.writeAsString(raw, flush: true);
    await tmp.rename(path);
  }

  @override
  Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final tmp = File('$path.tmp');
      if (await tmp.exists()) await tmp.delete();
    } catch (_) {
      // Best effort cleanup.
    }
  }
}

class InMemoryDocumentStore implements DocumentStore {
  final Map<String, String> files = {};

  /// When true, saves throw - used to exercise the Save Failed state.
  bool failSaves = false;

  @override
  Future<String?> load(String path) async => files[path];

  @override
  Future<void> save(String path, String raw) async {
    if (failSaves) {
      throw const FileSystemException('Simulated save failure');
    }
    files[path] = raw;
  }

  @override
  Future<void> delete(String path) async {
    files.remove(path);
  }
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

/// The coloring engine: tool state, op history with undo/redo, zoom/pan,
/// recent colors and idle autosave. Pure Dart (no widgets) so every behavior
/// is unit-testable.
class ColoringEngine extends ChangeNotifier {
  ColoringEngine({
    required this.document,
    required this.store,
    required this.documentPath,
    this.autosaveDelay = TcDurations.autosaveIdle,
  });

  // Normalized brush sizes (fraction of paper width).
  static const double minBrush = 0.012;
  static const double maxBrush = 0.09;
  static const double defaultBrush = 0.035;

  static const double minZoom = 1;
  static const double maxZoom = 4;

  /// Memory-aware history: redo depth is capped; stroke points are decimated
  /// at input time by [addStrokePoint]'s minimum-distance filter.
  static const int maxRedo = 100;
  static const int maxRecentColors = 8;

  final ColoringDocument document;
  final DocumentStore store;
  final String documentPath;
  final Duration autosaveDelay;

  final List<ColoringOp> _redo = [];

  // Tool state.
  ToolKind tool = ToolKind.brush;
  int colorValue = 0xFFEF6B67; // Coral
  double brushSize = defaultBrush;
  double opacity = 1;
  double fillTolerance = 0.5;
  String stampId = kStampIds.first;

  // View state (zoom 1x-4x, pan in paper-widths).
  double zoom = 1;
  Offset pan = Offset.zero;

  final List<int> recentColorValues = [];

  ColoringOp? liveOp;
  SaveState saveState = SaveState.idle;
  bool _dirty = false;
  Timer? _autosaveTimer;
  bool _disposed = false;

  bool get canUndo => document.ops.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get dirty => _dirty;

  Color get color => Color(colorValue);

  // -- Tool state -----------------------------------------------------------

  void selectTool(ToolKind next) {
    tool = next;
    // Marker is broad and translucent, pencil thin, brush balanced.
    switch (next) {
      case ToolKind.marker:
        opacity = 0.55;
      case ToolKind.pencil:
        opacity = 0.9;
      default:
        opacity = 1;
    }
    notifyListeners();
  }

  void selectColor(int value) {
    colorValue = value;
    _pushRecent(value);
    notifyListeners();
  }

  void setBrushSize(double size) {
    brushSize = size.clamp(minBrush, maxBrush);
    notifyListeners();
  }

  void setOpacity(double value) {
    opacity = value.clamp(0.1, 1.0);
    notifyListeners();
  }

  void setFillTolerance(double value) {
    fillTolerance = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void selectStamp(String id) {
    stampId = id;
    notifyListeners();
  }

  void _pushRecent(int value) {
    recentColorValues.remove(value);
    recentColorValues.insert(0, value);
    if (recentColorValues.length > maxRecentColors) {
      recentColorValues.removeLast();
    }
  }

  // -- Drawing --------------------------------------------------------------

  double get _strokeSize => switch (tool) {
        ToolKind.pencil => brushSize * 0.45,
        ToolKind.marker => brushSize * 1.5,
        ToolKind.eraser => brushSize * 1.3,
        _ => brushSize,
      };

  /// Begins a stroke (brush/marker/pencil/eraser) at a normalized point.
  void startStroke(Offset point) {
    liveOp = StrokeOp(
      tool: tool,
      colorValue: colorValue,
      size: _strokeSize,
      opacity: tool == ToolKind.eraser ? 1 : opacity,
      points: [point],
    );
    notifyListeners();
  }

  /// Adds a point to the live stroke with distance-based decimation, which
  /// keeps documents small and memory stable on long scribbles.
  void addStrokePoint(Offset point) {
    final live = liveOp;
    if (live is! StrokeOp) return;
    final last = live.points.last;
    if ((point - last).distance < 0.004) return;
    liveOp = live.copyWith(points: [...live.points, point]);
    notifyListeners();
  }

  void endStroke() {
    final live = liveOp;
    if (live is! StrokeOp) return;
    liveOp = null;
    _commit(live, countsColor: live.tool != ToolKind.eraser);
  }

  void cancelLiveOp() {
    liveOp = null;
    notifyListeners();
  }

  void tapFill(Offset point) {
    _commit(FillOp(
      point: point,
      colorValue: colorValue,
      tolerance: fillTolerance,
    ));
  }

  void addSplash(Offset point, {math.Random? random}) {
    final rng = random ?? math.Random();
    _commit(SplashOp(
      center: point,
      colorValue: colorValue,
      size: brushSize * 1.6,
      seed: rng.nextInt(1 << 31),
    ));
  }

  void placeStamp(Offset point) {
    _commit(StampOp(
      stampId: stampId,
      center: point,
      scale: 0.16,
      rotation: 0,
      colorValue: colorValue,
    ));
  }

  /// Replaces the most recent stamp (move/resize/rotate while selected).
  void updateLastStamp({Offset? center, double? scale, double? rotation}) {
    if (document.ops.isEmpty) return;
    final last = document.ops.last;
    if (last is! StampOp) return;
    document.ops[document.ops.length - 1] = last.copyWith(
      center: center,
      scale: scale?.clamp(0.06, 0.5),
      rotation: rotation,
    );
    _markDirty();
    notifyListeners();
  }

  /// Clear keeps history (the clear itself is undoable) and the line art.
  void clearCanvas() {
    _commit(const ClearOp(), countsColor: false);
  }

  void _commit(ColoringOp op, {bool countsColor = true}) {
    document.ops.add(op);
    _redo.clear();
    if (countsColor) _pushRecent(colorValue);
    _markDirty();
    notifyListeners();
  }

  // -- Undo / redo ----------------------------------------------------------

  void undo() {
    if (!canUndo) return;
    _redo.add(document.ops.removeLast());
    if (_redo.length > maxRedo) _redo.removeAt(0);
    _markDirty();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    document.ops.add(_redo.removeLast());
    _markDirty();
    notifyListeners();
  }

  // -- Zoom / pan -----------------------------------------------------------

  void setZoom(double next) {
    zoom = next.clamp(minZoom, maxZoom);
    if (zoom == minZoom) pan = Offset.zero;
    _clampPan();
    notifyListeners();
  }

  void zoomBy(double factor) => setZoom(zoom * factor);

  void panBy(Offset normalizedDelta) {
    pan += normalizedDelta;
    _clampPan();
    notifyListeners();
  }

  void _clampPan() {
    final maxPan = (zoom - 1) / (2 * zoom);
    pan = Offset(
      pan.dx.clamp(-maxPan, maxPan),
      pan.dy.clamp(-maxPan, maxPan),
    );
  }

  // -- Saving ---------------------------------------------------------------

  void _markDirty() {
    _dirty = true;
    if (saveState != SaveState.failed) saveState = SaveState.idle;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDelay, saveNow);
  }

  /// Persists the document atomically. Returns true on success. Called on
  /// idle autosave, app background, and before leaving the canvas.
  Future<bool> saveNow() async {
    if (_disposed) return false;
    _autosaveTimer?.cancel();
    if (!_dirty && saveState == SaveState.saved) return true;
    saveState = SaveState.saving;
    notifyListeners();
    try {
      await store.save(documentPath, document.toJsonString());
      if (_disposed) return true;
      _dirty = false;
      saveState = SaveState.saved;
      notifyListeners();
      return true;
    } catch (_) {
      if (_disposed) return false;
      saveState = SaveState.failed;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _autosaveTimer?.cancel();
    super.dispose();
  }
}

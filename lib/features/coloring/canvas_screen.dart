import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import '../../data/models.dart';
import '../badges/badge_service.dart';
import '../badges/badges_screen.dart';
import 'canvas_painter.dart';
import 'coloring_document.dart';
import 'coloring_engine.dart';
import 'palette_and_tools.dart';

/// Route arguments for the canvas.
class CanvasArgs {
  const CanvasArgs({required this.catalogItemId, this.artworkId});

  final String catalogItemId;

  /// When null, a fresh artwork is created for the catalog item.
  final String? artworkId;
}

/// Screen 12 - the coloring canvas, matching the approved layout exactly:
/// landscape shows the dark tool dock on the left, the artwork centered and
/// the color rail on the right; portrait moves tools and colors into a
/// bottom dock. Coordinates are normalized, so rotation never shifts art.
class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key, required this.args});

  final CanvasArgs args;

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

enum _GestureMode { none, drawing, stampDrag, viewport, stampAdjust }

class _CanvasScreenState extends State<CanvasScreen>
    with WidgetsBindingObserver {
  ColoringEngine? _engine;
  CatalogItem? _item;
  Artwork? _artwork;
  bool _loading = true;
  bool _loadFailed = false;
  bool _recovered = false;

  final Set<String> _toolsUsed = {};
  final Set<String> _colorNamesUsed = {};

  _GestureMode _mode = _GestureMode.none;
  double _zoomStart = 1;
  Offset _focalStart = Offset.zero;
  Offset _panStart = Offset.zero;
  double _stampScaleStart = 0.16;
  double _stampRotationStart = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final item = await state.catalog.byId(widget.args.catalogItemId);
    if (item == null) {
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
      return;
    }

    Artwork? artwork;
    if (widget.args.artworkId != null) {
      artwork = await state.artworks.byId(widget.args.artworkId!);
    }
    if (artwork == null) {
      final id = 'art_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      artwork = Artwork(
        id: id,
        catalogItemId: item.id,
        displayName: sanitizeArtworkName(item.title),
        documentPath: state.documentPathFor(id),
        previewPath: '',
        createdAt: now,
        updatedAt: now,
        favorite: false,
        completed: false,
      );
      await state.artworks.upsert(artwork);
    }

    ColoringDocument document;
    var recovered = false;
    try {
      final raw = await state.documentStore.load(artwork.documentPath);
      document = raw == null
          ? ColoringDocument.empty(item.id)
          : ColoringDocument.fromJsonString(raw);
    } catch (_) {
      // Corrupted document: recover with a fresh page, never crash.
      document = ColoringDocument.empty(item.id);
      recovered = true;
    }

    final engine = ColoringEngine(
      document: document,
      store: state.documentStore,
      documentPath: artwork.documentPath,
    );
    await state.catalog.touchProgress(item.id);
    if (!mounted) {
      engine.dispose();
      return;
    }
    setState(() {
      _item = item;
      _artwork = artwork;
      _engine = engine;
      _recovered = recovered;
      _loading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Autosave when the app goes to the background.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _engine?.saveNow();
      _persistArtworkMeta();
    }
  }

  Future<void> _persistArtworkMeta() async {
    final artwork = _artwork;
    final engine = _engine;
    if (artwork == null || engine == null) return;
    final updated = artwork.copyWith(
      updatedAt: DateTime.now(),
      completed: engine.document.effectiveOps.length >= 10,
    );
    _artwork = updated;
    await context.read<AppState>().artworks.upsert(updated);
  }

  Future<void> _leave() async {
    final engine = _engine;
    if (engine == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    var saved = await engine.saveNow();
    while (!saved && mounted) {
      final choice = await showSaveFailureDialog(context, leaving: true);
      if (choice == SaveFailureChoice.keepEditing) return;
      if (choice == SaveFailureChoice.leaveAnyway) break;
      saved = await engine.saveNow();
    }
    if (!mounted) return;
    await _persistArtworkMeta();

    // Badge progress for this coloring session.
    if (_toolsUsed.isNotEmpty && _item != null && mounted) {
      final earned =
          await context.read<AppState>().badgeService.recordColoringSession(
                catalogItemId: _item!.id,
                category: _item!.category,
                toolsUsed: _toolsUsed,
                colorNamesUsed: _colorNamesUsed,
              );
      if (mounted) {
        for (final def in earned) {
          await showBadgeEarnedOverlay(context, def);
        }
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _noteOpCommitted() {
    final engine = _engine!;
    _toolsUsed.add(engine.tool.name);
    if (engine.tool != ToolKind.eraser) {
      _colorNamesUsed.add(TcPalette.nameOf(engine.color));
    }
  }

  // -- Gesture handling (paper-local, normalized) ---------------------------

  Offset _toPaper(Offset local, Size size) {
    final engine = _engine!;
    final c = size.center(Offset.zero);
    final p = (local - c) / engine.zoom +
        c -
        Offset(engine.pan.dx * size.width, engine.pan.dy * size.height);
    return Offset(
      (p.dx / size.width).clamp(0.0, 1.0),
      (p.dy / size.height).clamp(0.0, 1.0),
    );
  }

  bool get _isStrokeTool => switch (_engine!.tool) {
        ToolKind.brush ||
        ToolKind.marker ||
        ToolKind.pencil ||
        ToolKind.eraser =>
          true,
        _ => false,
      };

  void _onScaleStart(ScaleStartDetails details, Size size) {
    final engine = _engine!;
    if (details.pointerCount >= 2) {
      engine.cancelLiveOp();
      if (engine.tool == ToolKind.stamps &&
          engine.document.ops.isNotEmpty &&
          engine.document.ops.last is StampOp) {
        final stamp = engine.document.ops.last as StampOp;
        _mode = _GestureMode.stampAdjust;
        _stampScaleStart = stamp.scale;
        _stampRotationStart = stamp.rotation;
      } else {
        _mode = _GestureMode.viewport;
        _zoomStart = engine.zoom;
        _focalStart = details.localFocalPoint;
        _panStart = engine.pan;
      }
      return;
    }
    final point = _toPaper(details.localFocalPoint, size);
    if (_isStrokeTool) {
      _mode = _GestureMode.drawing;
      engine.startStroke(point);
    } else if (engine.tool == ToolKind.stamps &&
        engine.document.ops.isNotEmpty &&
        engine.document.ops.last is StampOp) {
      _mode = _GestureMode.stampDrag;
    } else {
      _mode = _GestureMode.none;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size size) {
    final engine = _engine!;
    switch (_mode) {
      case _GestureMode.drawing:
        engine.addStrokePoint(_toPaper(details.localFocalPoint, size));
      case _GestureMode.stampDrag:
        engine.updateLastStamp(
            center: _toPaper(details.localFocalPoint, size));
      case _GestureMode.stampAdjust:
        engine.updateLastStamp(
          scale: _stampScaleStart * details.scale,
          rotation: _stampRotationStart + details.rotation,
        );
      case _GestureMode.viewport:
        engine.setZoom(_zoomStart * details.scale);
        final deltaPx = details.localFocalPoint - _focalStart;
        engine
          ..pan = _panStart +
              Offset(
                deltaPx.dx / (size.width * engine.zoom),
                deltaPx.dy / (size.height * engine.zoom),
              )
          ..panBy(Offset.zero); // clamps + notifies
      case _GestureMode.none:
        break;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_mode == _GestureMode.drawing) {
      _engine!.endStroke();
      _noteOpCommitted();
    }
    if (_mode == _GestureMode.stampDrag ||
        _mode == _GestureMode.stampAdjust) {
      _noteOpCommitted();
    }
    _mode = _GestureMode.none;
  }

  void _onTapUp(TapUpDetails details, Size size) {
    final engine = _engine!;
    final point = _toPaper(details.localPosition, size);
    switch (engine.tool) {
      case ToolKind.fill:
        engine.tapFill(point);
      case ToolKind.splash:
        engine.addSplash(point);
      case ToolKind.stamps:
        engine.placeStamp(point);
      default:
        engine.startStroke(point);
        engine.endStroke();
    }
    _noteOpCommitted();
  }

  // -- Sheets ----------------------------------------------------------------

  void _openPalette() {
    showCanvasSheet(context,
        title: 'Colors',
        child: ColorPalettePanel(
            engine: _engine!, onPicked: () => Navigator.of(context).pop()));
  }

  void _openToolSettings() {
    showCanvasSheet(context,
        title: 'Tool settings', child: ToolSettingsPanel(engine: _engine!));
  }

  void _openStickers() {
    showCanvasSheet(context,
        title: 'Stickers',
        child: StickerDrawerPanel(
            engine: _engine!, onPicked: () => Navigator.of(context).pop()));
  }

  Future<void> _clear() async {
    if (await showClearCanvasDialog(context)) {
      _engine!.clearCanvas();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine?.saveNow();
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_loadFailed || _engine == null || _item == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: TcModalCard(
              icon: 'alert',
              title: 'We couldn\u2019t open this picture',
              body: 'Please head back and pick another picture.',
              actions: [
                TcButton(
                    label: 'Go back',
                    onPressed: () => Navigator.of(context).maybePop()),
              ],
            ),
          ),
        ),
      );
    }

    final r = Responsive.of(context);
    final landscape = r.isLandscape;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: TcColors.canvas,
        body: SafeArea(
          child: Column(children: [
            _CanvasTopBar(
              engine: _engine!,
              item: _item!,
              onBack: _leave,
              onToolSettings: _openToolSettings,
            ),
            if (_recovered)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: TcBanner(
                  icon: 'alert',
                  boldText: 'We restored a fresh page.',
                  text:
                      'The previous save could not be read, so this picture starts clean.',
                ),
              ),
            Expanded(
              child: landscape
                  ? Row(children: [
                      _ToolDock(
                        engine: _engine!,
                        vertical: true,
                        onStickers: _openStickers,
                        onClear: _clear,
                      ),
                      Expanded(child: _buildPaper()),
                      _ColorRail(
                          engine: _engine!,
                          vertical: true,
                          onMore: _openPalette),
                    ])
                  : Column(children: [
                      Expanded(child: _buildPaper()),
                      _ColorRail(
                          engine: _engine!,
                          vertical: false,
                          onMore: _openPalette),
                      _ToolDock(
                        engine: _engine!,
                        vertical: false,
                        onStickers: _openStickers,
                        onClear: _clear,
                      ),
                    ]),
            ),
            if (!landscape) const SizedBox(height: 6),
          ]),
        ),
      ),
    );
  }

  Widget _buildPaper() {
    final engine = _engine!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: TcColors.artBoardBg,
          borderRadius: BorderRadius.circular(TcRadius.panel),
        ),
        padding: const EdgeInsets.all(14),
        child: Center(
          child: AspectRatio(
            aspectRatio: ColoringDocument.paperAspect,
            child: LayoutBuilder(builder: (context, constraints) {
              final size = constraints.biggest;
              return Semantics(
                label:
                    'Coloring paper. One finger colors, two fingers move and zoom.',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _onTapUp(d, size),
                    onScaleStart: (d) => _onScaleStart(d, size),
                    onScaleUpdate: (d) => _onScaleUpdate(d, size),
                    onScaleEnd: _onScaleEnd,
                    child: AnimatedBuilder(
                      animation: engine,
                      builder: (context, _) {
                        final c = size.center(Offset.zero);
                        final matrix = Matrix4.identity()
                          ..translate(c.dx, c.dy)
                          ..scale(engine.zoom)
                          ..translate(
                            -c.dx + engine.pan.dx * size.width,
                            -c.dy + engine.pan.dy * size.height,
                          );
                        return Transform(
                          transform: matrix,
                          child: CustomPaint(
                            size: size,
                            painter: CanvasPainter(
                              ops: engine.document.effectiveOps,
                              liveOp: engine.liveOp,
                              lineArtSeed: _item!.assetSeed,
                              repaint: engine,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar: back, title, hint badges, zoom controls, save chip
// ---------------------------------------------------------------------------

class _CanvasTopBar extends StatelessWidget {
  const _CanvasTopBar({
    required this.engine,
    required this.item,
    required this.onBack,
    required this.onToolSettings,
  });

  final ColoringEngine engine;
  final CatalogItem item;
  final VoidCallback onBack;
  final VoidCallback onToolSettings;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);
    final wide = r.layout == FireLayout.expanded;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(children: [
        TcIconButton(
            icon: 'back', semanticLabel: 'Save and go back', onPressed: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TcType.h3.copyWith(color: x.ink)),
                Text('${item.category} \u2022 ${item.difficulty.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TcType.rowSubtitle.copyWith(color: x.muted)),
              ]),
        ),
        if (wide) ...[
          const TcBadge('One finger colors', icon: 'brush'),
          const SizedBox(width: 8),
          const TcBadge('Two fingers move & zoom', icon: 'grid'),
          const SizedBox(width: 12),
        ],
        AnimatedBuilder(
          animation: engine,
          builder: (context, _) => Row(children: [
            TcIconButton(
                icon: 'close',
                semanticLabel: 'Zoom out',
                onPressed: () => engine.zoomBy(1 / 1.25)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TcBadge('${(engine.zoom * 100).round()}% zoom'),
            ),
            TcIconButton(
                icon: 'plus',
                semanticLabel: 'Zoom in',
                onPressed: () => engine.zoomBy(1.25)),
            const SizedBox(width: 8),
            _SaveChip(engine: engine),
          ]),
        ),
        const SizedBox(width: 8),
        TcIconButton(
            icon: 'settings',
            semanticLabel: 'Tool settings',
            onPressed: onToolSettings),
      ]),
    );
  }
}

class _SaveChip extends StatelessWidget {
  const _SaveChip({required this.engine});

  final ColoringEngine engine;

  @override
  Widget build(BuildContext context) {
    final (label, kind, icon) = switch (engine.saveState) {
      SaveState.saving => ('Saving\u2026', TcBadgeKind.normal, 'download'),
      SaveState.saved => ('Saved', TcBadgeKind.gold, 'check'),
      SaveState.failed => ('Save failed', TcBadgeKind.coral, 'alert'),
      SaveState.idle => ('Auto-save on', TcBadgeKind.normal, 'check'),
    };
    final chip = TcBadge(label, kind: kind, icon: icon);
    if (engine.saveState != SaveState.failed) return chip;
    return TcIconGestureTarget(
      semanticLabel: 'Save failed. Tap to try again.',
      onTap: () async {
        final ok = await engine.saveNow();
        if (!ok && context.mounted) {
          final choice = await showSaveFailureDialog(context, leaving: false);
          if (choice == SaveFailureChoice.tryAgain) await engine.saveNow();
        }
      },
      child: chip,
    );
  }
}

// ---------------------------------------------------------------------------
// Tool dock (dark navy, approved styling)
// ---------------------------------------------------------------------------

class _ToolDock extends StatelessWidget {
  const _ToolDock({
    required this.engine,
    required this.vertical,
    required this.onStickers,
    required this.onClear,
  });

  final ColoringEngine engine;
  final bool vertical;
  final VoidCallback onStickers;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final children = <Widget>[
          for (final tool in ToolKind.values)
            _ToolButton(
              icon: tool.icon,
              label: tool.label,
              active: engine.tool == tool,
              onTap: () {
                engine.selectTool(tool);
                if (tool == ToolKind.stamps) onStickers();
              },
            ),
          _dockDivider(),
          _ToolButton(
              icon: 'undo',
              label: 'Undo',
              enabled: engine.canUndo,
              onTap: engine.undo),
          _ToolButton(
              icon: 'forward',
              label: 'Redo',
              enabled: engine.canRedo,
              onTap: engine.redo),
          _ToolButton(icon: 'trash', label: 'Clear picture', onTap: onClear),
        ];
        final dock = Container(
          decoration: BoxDecoration(
            color: const Color(0xF0111C34),
            borderRadius: BorderRadius.circular(TcRadius.card),
            boxShadow: TcShadows.dock,
          ),
          padding: const EdgeInsets.all(8),
          child: vertical
              ? SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final child in children)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: child),
                ]))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final child in children)
                      Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 3),
                          child: child),
                  ])),
        );
        return Padding(
          padding: vertical
              ? const EdgeInsets.fromLTRB(12, 4, 0, 12)
              : const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: vertical ? Center(child: dock) : Center(child: dock),
        );
      },
    );
  }

  Widget _dockDivider() => Container(
        width: vertical ? 30 : 1,
        height: vertical ? 1 : 30,
        color: const Color(0x33FFFFFF),
        margin: const EdgeInsets.all(4),
      );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: TcSize.tool + 8,
          height: TcSize.tool + 8,
          decoration: BoxDecoration(
            color: active ? TcColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(TcRadius.tool),
          ),
          child: Center(
            child: TcIcon(
              icon,
              size: 22,
              color: active
                  ? TcColors.navy
                  : enabled
                      ? Colors.white
                      : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Color rail (right in landscape, above dock in portrait)
// ---------------------------------------------------------------------------

class _ColorRail extends StatelessWidget {
  const _ColorRail({
    required this.engine,
    required this.vertical,
    required this.onMore,
  });

  final ColoringEngine engine;
  final bool vertical;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final swatches = [
          for (final named
              in TcPalette.colors.take(vertical ? 12 : 8))
            ColorSwatchButton(
              color: named.color,
              name: named.name,
              selected: engine.colorValue == named.color.value,
              onTap: () => engine.selectColor(named.color.value),
            ),
          TcIconButton(
              icon: 'plus',
              semanticLabel: 'More colors',
              onPressed: onMore),
        ];
        final rail = Container(
          decoration: BoxDecoration(
            color: TcColors.paper,
            borderRadius: BorderRadius.circular(TcRadius.card),
            border: Border.all(color: TcColors.line),
            boxShadow: TcShadows.card,
          ),
          padding: const EdgeInsets.all(6),
          child: vertical
              ? SingleChildScrollView(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: swatches))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child:
                      Row(mainAxisSize: MainAxisSize.min, children: swatches)),
        );
        return Padding(
          padding: vertical
              ? const EdgeInsets.fromLTRB(0, 4, 12, 12)
              : const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Center(child: rail),
        );
      },
    );
  }
}

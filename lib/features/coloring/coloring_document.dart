import 'dart:convert';
import 'dart:ui';

/// Serializable coloring document model.
///
/// All geometry is stored in *normalized paper coordinates* (0..1 on both
/// axes relative to the art paper), which keeps artwork stable across
/// rotation, window resizes and different Fire tablet screens. The paper
/// itself keeps the approved 1.18 aspect ratio everywhere.

enum ToolKind { fill, brush, marker, pencil, stamps, splash, eraser }

extension ToolKindInfo on ToolKind {
  String get label => switch (this) {
        ToolKind.fill => 'Fill',
        ToolKind.brush => 'Brush',
        ToolKind.marker => 'Marker',
        ToolKind.pencil => 'Pencil',
        ToolKind.stamps => 'Stamps',
        ToolKind.splash => 'Paint Splash',
        ToolKind.eraser => 'Eraser',
      };

  String get icon => switch (this) {
        ToolKind.fill => 'spark',
        ToolKind.brush => 'brush',
        ToolKind.marker => 'edit',
        ToolKind.pencil => 'edit',
        ToolKind.stamps => 'star',
        ToolKind.splash => 'heart',
        ToolKind.eraser => 'close',
      };
}

/// Approved stamp set (Screen 15 sticker drawer).
const List<String> kStampIds = [
  'star',
  'heart',
  'flower',
  'balloon',
  'cloud',
  'butterfly',
];

sealed class ColoringOp {
  const ColoringOp();

  Map<String, dynamic> toJson();

  static ColoringOp fromJson(Map<String, dynamic> json) {
    switch (json['t'] as String?) {
      case 'stroke':
        return StrokeOp.fromJson(json);
      case 'fill':
        return FillOp.fromJson(json);
      case 'stamp':
        return StampOp.fromJson(json);
      case 'splash':
        return SplashOp.fromJson(json);
      case 'clear':
        return const ClearOp();
      default:
        throw const FormatException('Unknown coloring op');
    }
  }
}

/// Brush / marker / pencil / eraser stroke.
class StrokeOp extends ColoringOp {
  const StrokeOp({
    required this.tool,
    required this.colorValue,
    required this.size,
    required this.opacity,
    required this.points,
  });

  final ToolKind tool;
  final int colorValue;

  /// Normalized stroke width (fraction of paper width).
  final double size;
  final double opacity;
  final List<Offset> points;

  Color get color => Color(colorValue);

  StrokeOp copyWith({List<Offset>? points}) => StrokeOp(
        tool: tool,
        colorValue: colorValue,
        size: size,
        opacity: opacity,
        points: points ?? this.points,
      );

  @override
  Map<String, dynamic> toJson() => {
        't': 'stroke',
        'tool': tool.name,
        'color': colorValue,
        'size': size,
        'opacity': opacity,
        'points': [
          for (final p in points) ...[
            _round(p.dx),
            _round(p.dy),
          ]
        ],
      };

  factory StrokeOp.fromJson(Map<String, dynamic> json) {
    final raw = (json['points'] as List).cast<num>();
    if (raw.length.isOdd) {
      throw const FormatException('Stroke points must be x/y pairs');
    }
    return StrokeOp(
      tool: ToolKind.values.firstWhere(
        (t) => t.name == json['tool'],
        orElse: () => ToolKind.brush,
      ),
      colorValue: json['color'] as int,
      size: (json['size'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      points: [
        for (var i = 0; i < raw.length; i += 2)
          Offset(raw[i].toDouble(), raw[i + 1].toDouble()),
      ],
    );
  }
}

/// Tap-to-fill: a soft radial color pool centered on the tapped region.
class FillOp extends ColoringOp {
  const FillOp({
    required this.point,
    required this.colorValue,
    required this.tolerance,
  });

  final Offset point;
  final int colorValue;

  /// 0..1; larger tolerance fills a wider region.
  final double tolerance;

  Color get color => Color(colorValue);

  @override
  Map<String, dynamic> toJson() => {
        't': 'fill',
        'x': _round(point.dx),
        'y': _round(point.dy),
        'color': colorValue,
        'tolerance': tolerance,
      };

  factory FillOp.fromJson(Map<String, dynamic> json) => FillOp(
        point: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
        colorValue: json['color'] as int,
        tolerance: (json['tolerance'] as num?)?.toDouble() ?? 0.5,
      );
}

/// Placed sticker stamp; movable, resizable and rotatable while selected.
class StampOp extends ColoringOp {
  const StampOp({
    required this.stampId,
    required this.center,
    required this.scale,
    required this.rotation,
    required this.colorValue,
  });

  final String stampId;
  final Offset center;

  /// Normalized size (fraction of paper width).
  final double scale;

  /// Radians.
  final double rotation;
  final int colorValue;

  Color get color => Color(colorValue);

  StampOp copyWith({Offset? center, double? scale, double? rotation}) =>
      StampOp(
        stampId: stampId,
        center: center ?? this.center,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        colorValue: colorValue,
      );

  @override
  Map<String, dynamic> toJson() => {
        't': 'stamp',
        'id': stampId,
        'x': _round(center.dx),
        'y': _round(center.dy),
        'scale': scale,
        'rotation': rotation,
        'color': colorValue,
      };

  factory StampOp.fromJson(Map<String, dynamic> json) => StampOp(
        stampId: json['id'] as String,
        center: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
        scale: (json['scale'] as num).toDouble(),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        colorValue: json['color'] as int,
      );
}

/// Playful splash: deterministic droplets from a per-op seed.
class SplashOp extends ColoringOp {
  const SplashOp({
    required this.center,
    required this.colorValue,
    required this.size,
    required this.seed,
  });

  final Offset center;
  final int colorValue;

  /// Normalized splash radius (fraction of paper width).
  final double size;
  final int seed;

  Color get color => Color(colorValue);

  @override
  Map<String, dynamic> toJson() => {
        't': 'splash',
        'x': _round(center.dx),
        'y': _round(center.dy),
        'color': colorValue,
        'size': size,
        'seed': seed,
      };

  factory SplashOp.fromJson(Map<String, dynamic> json) => SplashOp(
        center: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
        colorValue: json['color'] as int,
        size: (json['size'] as num).toDouble(),
        seed: json['seed'] as int? ?? 0,
      );
}

/// Clear-canvas marker. Ops before the latest clear are kept in history so
/// Clear itself stays undoable, but they no longer render.
class ClearOp extends ColoringOp {
  const ClearOp();

  @override
  Map<String, dynamic> toJson() => {'t': 'clear'};
}

class ColoringDocument {
  ColoringDocument({
    required this.catalogItemId,
    List<ColoringOp>? ops,
  }) : ops = ops ?? [];

  static const int formatVersion = 1;

  /// Approved art paper aspect ratio (width / height).
  static const double paperAspect = 1.18;

  final String catalogItemId;
  final List<ColoringOp> ops;

  factory ColoringDocument.empty(String catalogItemId) =>
      ColoringDocument(catalogItemId: catalogItemId);

  /// Ops that actually render: everything after the most recent clear.
  List<ColoringOp> get effectiveOps {
    final lastClear = ops.lastIndexWhere((op) => op is ClearOp);
    return lastClear < 0 ? List.unmodifiable(ops) : ops.sublist(lastClear + 1);
  }

  bool get isEmpty => effectiveOps.isEmpty;

  String toJsonString() => jsonEncode({
        'format_version': formatVersion,
        'catalog_item_id': catalogItemId,
        'ops': [for (final op in ops) op.toJson()],
      });

  /// Parses a stored document. Throws [FormatException] when the payload is
  /// corrupted or from an unknown newer format; callers offer recovery.
  factory ColoringDocument.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Document root must be an object');
    }
    final version = decoded['format_version'] as int? ?? 0;
    if (version < 1 || version > formatVersion) {
      throw FormatException('Unsupported document version $version');
    }
    final id = decoded['catalog_item_id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Missing catalog item id');
    }
    final rawOps = decoded['ops'];
    if (rawOps is! List) {
      throw const FormatException('Missing ops list');
    }
    return ColoringDocument(
      catalogItemId: id,
      ops: [
        for (final op in rawOps)
          ColoringOp.fromJson((op as Map).cast<String, dynamic>()),
      ],
    );
  }
}

double _round(double v) => (v * 10000).roundToDouble() / 10000;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/graphics/scene_painter.dart';
import 'coloring_document.dart';

/// Paints a coloring document onto the art paper.
///
/// All ops are stored in normalized paper coordinates; this painter scales
/// them to the current paper size, so the artwork is identical across
/// rotation, zoom, tablet sizes and PNG export. Color is painted *under*
/// the line art: the ops render first, then the line art layer is
/// multiplied on top (white paper keeps colors, navy outlines stay crisp).
class CanvasPainter extends CustomPainter {
  CanvasPainter({
    required this.ops,
    required this.liveOp,
    required this.lineArtSeed,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final List<ColoringOp> ops;
  final ColoringOp? liveOp;
  final int lineArtSeed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));

    for (final op in ops) {
      _paintOp(canvas, size, op);
    }
    final live = liveOp;
    if (live != null) {
      _paintOp(canvas, size, live);
    }

    // Line art on top via multiply so the outlines always stay visible.
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.multiply);
    LineArtPainter(seed: lineArtSeed).paint(canvas, size);
    canvas.restore();

    canvas.restore();
  }

  void _paintOp(Canvas canvas, Size size, ColoringOp op) {
    switch (op) {
      case StrokeOp():
        _paintStroke(canvas, size, op);
      case FillOp():
        _paintFill(canvas, size, op);
      case StampOp():
        paintStamp(canvas, size, op);
      case SplashOp():
        _paintSplash(canvas, size, op);
      case ClearOp():
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFFFFFFFF),
        );
    }
  }

  void _paintStroke(Canvas canvas, Size size, StrokeOp op) {
    if (op.points.isEmpty) return;
    final isEraser = op.tool == ToolKind.eraser;
    final paint = Paint()
      ..color = isEraser
          ? const Color(0xFFFFFFFF)
          : op.color.withOpacity(op.opacity.clamp(0.05, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (op.size * size.width).clamp(1.0, size.width)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (op.points.length == 1) {
      final p = _scale(op.points.first, size);
      canvas.drawCircle(
        p,
        paint.strokeWidth / 2,
        Paint()..color = paint.color,
      );
      return;
    }
    final path = Path()
      ..moveTo(op.points.first.dx * size.width,
          op.points.first.dy * size.height);
    for (final point in op.points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  /// Fill approximation: a soft-edged color pool centered on the tapped
  /// region (vector radial flood - documented in UI_FIDELITY_EXCEPTIONS).
  /// Tolerance widens the pool.
  void _paintFill(Canvas canvas, Size size, FillOp op) {
    final center = _scale(op.point, size);
    final radius = (0.10 + op.tolerance.clamp(0.0, 1.0) * 0.22) * size.width;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [op.color, op.color, op.color.withOpacity(0)],
          stops: const [0, 0.72, 1],
        ).createShader(rect),
    );
  }

  void _paintSplash(Canvas canvas, Size size, SplashOp op) {
    final center = _scale(op.center, size);
    final radius = (op.size * size.width).clamp(4.0, size.width / 2);
    final paint = Paint()..color = op.color.withOpacity(0.9);
    canvas.drawCircle(center, radius, paint);
    for (final drop in splashDroplets(op.seed)) {
      canvas.drawCircle(
        center + Offset(drop.dx * radius * 2.2, drop.dy * radius * 2.2),
        radius * drop.distance.clamp(0.09, 0.3),
        paint,
      );
    }
  }

  static Offset _scale(Offset normalized, Size size) =>
      Offset(normalized.dx * size.width, normalized.dy * size.height);

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      oldDelegate.ops != ops ||
      oldDelegate.liveOp != liveOp ||
      oldDelegate.lineArtSeed != lineArtSeed;
}

/// Deterministic droplet offsets for a splash seed (also used by tests).
List<Offset> splashDroplets(int seed) {
  final rng = math.Random(seed);
  return [
    for (var i = 0; i < 9; i++)
      Offset.fromDirection(
        rng.nextDouble() * math.pi * 2,
        0.35 + rng.nextDouble() * 0.65,
      ) *
          0.5,
  ];
}

/// Draws a placed stamp: translucent color body with a friendly ink outline
/// in the approved style.
void paintStamp(Canvas canvas, Size size, StampOp op) {
  final center = Offset(op.center.dx * size.width, op.center.dy * size.height);
  final scale = (op.scale * size.width).clamp(8.0, size.width);
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(op.rotation);
  canvas.scale(scale / 2);
  final path = stampPath(op.stampId);
  canvas.drawPath(path, Paint()..color = op.color.withOpacity(0.85));
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0xFF22314C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 / scale * 2
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.restore();
}

/// Stamp glyph paths in a -1..1 design box.
Path stampPath(String stampId) {
  switch (stampId) {
    case 'heart':
      return Path()
        ..moveTo(0, 0.85)
        ..cubicTo(-1.1, 0.1, -0.85, -0.85, 0, -0.35)
        ..cubicTo(0.85, -0.85, 1.1, 0.1, 0, 0.85)
        ..close();
    case 'flower':
      final path = Path();
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        path.addOval(Rect.fromCircle(
          center: Offset(math.cos(angle) * 0.55, math.sin(angle) * 0.55),
          radius: 0.42,
        ));
      }
      path.addOval(Rect.fromCircle(center: Offset.zero, radius: 0.34));
      return path;
    case 'balloon':
      return Path()
        ..addOval(Rect.fromCenter(
            center: const Offset(0, -0.25), width: 1.3, height: 1.5))
        ..moveTo(-0.14, 0.5)
        ..lineTo(0, 0.68)
        ..lineTo(0.14, 0.5)
        ..close();
    case 'cloud':
      return Path()
        ..addOval(Rect.fromCircle(
            center: const Offset(-0.45, 0.15), radius: 0.42))
        ..addOval(
            Rect.fromCircle(center: const Offset(0.05, -0.15), radius: 0.5))
        ..addOval(
            Rect.fromCircle(center: const Offset(0.5, 0.18), radius: 0.38))
        ..addRect(const Rect.fromLTRB(-0.45, 0.15, 0.5, 0.56));
    case 'butterfly':
      return Path()
        ..addOval(Rect.fromCenter(
            center: const Offset(-0.5, -0.35), width: 0.9, height: 0.75))
        ..addOval(Rect.fromCenter(
            center: const Offset(0.5, -0.35), width: 0.9, height: 0.75))
        ..addOval(Rect.fromCenter(
            center: const Offset(-0.45, 0.35), width: 0.75, height: 0.62))
        ..addOval(Rect.fromCenter(
            center: const Offset(0.45, 0.35), width: 0.75, height: 0.62))
        ..addOval(Rect.fromCenter(
            center: Offset.zero, width: 0.26, height: 1.15));
    case 'star':
    default:
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final radius = i.isEven ? 1.0 : 0.45;
        final angle = -math.pi / 2 + i * math.pi / 5;
        final point =
            Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      return path;
  }
}

/// Small preview of a stamp glyph (sticker drawer, Screen 15).
class StampPreview extends StatelessWidget {
  const StampPreview({
    super.key,
    required this.stampId,
    required this.color,
    this.size = 44,
  });

  final String stampId;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StampPreviewPainter(stampId: stampId, color: color),
    );
  }
}

class _StampPreviewPainter extends CustomPainter {
  _StampPreviewPainter({required this.stampId, required this.color});

  final String stampId;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 2.6);
    final path = stampPath(stampId);
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.85));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF22314C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.12
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StampPreviewPainter oldDelegate) =>
      oldDelegate.stampId != stampId || oldDelegate.color != color;
}

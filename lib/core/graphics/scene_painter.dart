import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme/tokens.dart';

/// Procedural decorative scenes and coloring line art, ported from the
/// approved `scene(seed, line)` generator in the UI source (app.js). The
/// same seeds produce the same compositions as the approved thumbnails.
///
/// Decorative variant: soft gradient sky, sun disc, rolling white hills,
/// accent hill and a friendly face circle. Line variant: white paper with
/// bold navy outline paths sized for tap-fill regions.

const List<List<Color>> scenePalettes = [
  [Color(0xFFF7CF75), Color(0xFF69B4C7), Color(0xFFEF7770)],
  [Color(0xFFA99AE0), Color(0xFFF2BD55), Color(0xFF5AA77B)],
  [Color(0xFFE9867B), Color(0xFF9FD1DC), Color(0xFF305F7E)],
  [Color(0xFF72B390), Color(0xFFF6C76B), Color(0xFF8874CB)],
];

class SceneThumb extends StatelessWidget {
  const SceneThumb({super.key, required this.seed, this.line = false});

  final int seed;
  final bool line;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: line ? LineArtPainter(seed: seed) : ScenePainter(seed: seed),
      child: const SizedBox.expand(),
    );
  }
}

class ScenePainter extends CustomPainter {
  ScenePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = scenePalettes[seed % scenePalettes.length];
    final w = size.width, h = size.height;
    // viewBox 420x260 scaled to fit
    final sx = w / 420.0, sy = h / 260.0;
    canvas.save();
    canvas.scale(sx, sy);

    final rect = Rect.fromLTWH(0, 0, 420, 260);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(0)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p[0], p[1]],
        ).createShader(rect),
    );

    // Sun / moon disc
    canvas.drawCircle(
      const Offset(345, 54),
      34,
      Paint()..color = const Color(0xB8FFFFFF),
    );

    // Rolling white foreground
    final hills = Path()
      ..moveTo(0, 218)
      ..cubicTo(72, 138, 142, 148, 204, 206)
      ..cubicTo(254, 129, 349, 135, 420, 208)
      ..lineTo(420, 260)
      ..lineTo(0, 260)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0x9EFFFFFF));

    // Accent hill
    final accent = Path()
      ..moveTo(80, 185)
      ..cubicTo(100, 135, 145, 115, 184, 155)
      ..cubicTo(212, 99, 258, 105, 280, 147)
      ..cubicTo(308, 134, 329, 150, 341, 185)
      ..close();
    canvas.drawPath(accent, Paint()..color = p[2].withOpacity(0.88));

    // Friendly face
    canvas.drawCircle(
      const Offset(129, 112),
      28,
      Paint()..color = const Color(0xCCFFFFFF),
    );
    final face = Paint()
      ..color = const Color(0xFF26364D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final smile = Path()
      ..moveTo(115, 111)
      ..cubicTo(124, 95, 138, 95, 145, 111);
    canvas.drawPath(smile, face);
    final mouth = Path()
      ..moveTo(117, 124)
      ..cubicTo(125, 131, 135, 131, 143, 124);
    canvas.drawPath(mouth, face);

    canvas.restore();
  }

  @override
  bool shouldRepaint(ScenePainter oldDelegate) => oldDelegate.seed != seed;
}

/// Bold, fill-friendly line art on white paper (approved line variant),
/// with per-seed rotation/offset variations so all 120 catalog pages are
/// visually distinct while staying inside the approved style.
class LineArtPainter extends CustomPainter {
  LineArtPainter({required this.seed, this.strokeWidth = 5});

  final int seed;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final sx = w / 420.0, sy = h / 300.0;
    canvas.save();
    canvas.scale(sx, sy);

    final ink = Paint()
      ..color = const Color(0xFF22314C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rng = math.Random(seed);
    final jx = (rng.nextDouble() - 0.5) * 24;
    final jy = (rng.nextDouble() - 0.5) * 14;

    // Rolling landscape line
    final land = Path()
      ..moveTo(40, 230)
      ..cubicTo(85, 145, 130, 128, 175, 176)
      ..cubicTo(210, 101, 263, 96, 296, 161)
      ..cubicTo(324, 136, 354, 150, 380, 230);
    canvas.drawPath(land, ink);

    // Big friendly circle (sun / wheel / face)
    canvas.drawCircle(Offset(126 + jx, 118 + jy), 46, ink);
    canvas.drawLine(
        Offset(101 + jx, 118 + jy), Offset(151 + jx, 118 + jy), ink);
    canvas.drawLine(
        Offset(126 + jx, 93 + jy), Offset(126 + jx, 143 + jy), ink);

    // Kite / sail triangle
    final kite = Path()
      ..moveTo(285, 120)
      ..lineTo(313, 86)
      ..lineTo(341, 120)
      ..lineTo(333, 175)
      ..lineTo(293, 175)
      ..close();
    canvas.drawPath(kite, ink);

    // Ground
    canvas.drawLine(const Offset(57, 230), const Offset(367, 230), ink);

    // Sky accents, varied per seed
    final arc1 = Path()
      ..moveTo(82 + jx, 72)
      ..cubicTo(100 + jx, 50, 125 + jx, 44, 150 + jx, 56);
    canvas.drawPath(arc1, ink);
    final arc2 = Path()
      ..moveTo(241, 62 + jy)
      ..cubicTo(243, 42 + jy, 269 + jx, 42 + jy, 303, 52 + jy);
    canvas.drawPath(arc2, ink);

    // Seed-specific extra detail keeps each page unique.
    switch (seed % 4) {
      case 0:
        canvas.drawCircle(const Offset(350, 60), 18, ink);
        break;
      case 1:
        canvas.drawRect(const Rect.fromLTWH(60, 178, 44, 52), ink);
        break;
      case 2:
        final star = Path()
          ..moveTo(360, 44)
          ..lineTo(366, 62)
          ..lineTo(384, 62)
          ..lineTo(370, 73)
          ..lineTo(375, 90)
          ..lineTo(360, 80)
          ..lineTo(345, 90)
          ..lineTo(350, 73)
          ..lineTo(336, 62)
          ..lineTo(354, 62)
          ..close();
        canvas.drawPath(star, ink);
        break;
      default:
        final cloud = Path()
          ..moveTo(330, 55)
          ..cubicTo(330, 40, 352, 36, 358, 48)
          ..cubicTo(372, 40, 386, 50, 380, 62)
          ..lineTo(334, 62)
          ..close();
        canvas.drawPath(cloud, ink);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(LineArtPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.strokeWidth != strokeWidth;
}

/// Hero artwork wash used in the Home / success heroes.
class HeroArt extends StatelessWidget {
  const HeroArt({super.key, this.seed = 11});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TcRadius.small),
      child: SceneThumb(seed: seed),
    );
  }
}

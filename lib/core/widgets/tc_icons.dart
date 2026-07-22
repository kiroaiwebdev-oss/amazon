import 'package:flutter/widgets.dart';

import '../graphics/svg_path_parser.dart';

/// The approved 26-glyph stroke icon set, path data copied verbatim from the
/// UI source (`app.js` -> ico()). Icons render on a 24x24 viewBox with round
/// caps/joins and stroke width 1.9, exactly like the approved SVG output.
abstract final class TcIconData {
  static const Map<String, String> paths = {
    'home': 'M3 11.5 12 4l9 7.5V21h-6v-6H9v6H3z',
    'grid': 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z',
    'art':
        'M4 19c3-8 5-12 9-12 4 0 7 3 7 7 0 4-3 7-7 7H4zM7 6a2 2 0 1 0 0-4 2 2 0 0 0 0 4z',
    'shield': 'M12 3 20 6v6c0 5-3.5 8-8 10-4.5-2-8-5-8-10V6z',
    'search':
        'M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15zm5-2.5L21 21',
    'heart':
        'M12 21S3 15.8 3 9.5A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 9 2.5C21 15.8 12 21 12 21z',
    'back': 'M15 4 7 12l8 8M8 12h12',
    'forward': 'M9 4l8 8-8 8',
    'play': 'M8 5v14l11-7z',
    'check': 'm5 12 4 4L19 6',
    'lock': 'M7 11V8a5 5 0 0 1 10 0v3M5 11h14v10H5z',
    'star': 'm12 2 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z',
    'settings':
        'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8zm0-6v3m0 14v3M2 12h3m14 0h3M4.9 4.9 7 7m10 10 2.1 2.1M19.1 4.9 17 7M7 17l-2.1 2.1',
    'download': 'M12 3v12m-5-5 5 5 5-5M4 20h16',
    'trash': 'M4 7h16M9 7V4h6v3m-8 0 1 14h8l1-14',
    'edit': 'M4 20l4.5-1 10-10-3.5-3.5-10 10zM14 6l3.5 3.5',
    'sound': 'M4 10h4l5-4v12l-5-4H4zM17 9c2 2 2 4 0 6',
    'info': 'M12 11v7m0-11v.1',
    'wifi': 'M3 9c5-5 13-5 18 0M6 13c3-3 9-3 12 0m-8 4c1-1 3-1 4 0',
    'alert': 'M12 3 22 21H2zM12 9v5m0 3v.1',
    'spark': 'm12 2 2.2 6.8L21 11l-6.8 2.2L12 20l-2.2-6.8L3 11l6.8-2.2z',
    'brush': 'M14 4 20 10l-8 8c-2 2-6 2-8 2 0-2 0-6 2-8z',
    'undo': 'M9 7 4 12l5 5M5 12h8c4 0 7 2 7 6',
    'plus': 'M12 4v16M4 12h16',
    'close': 'M5 5l14 14M19 5 5 19',
    'book':
        'M4 5c4-2 6 0 8 2v14c-2-2-4-3-8-2zm16 0c-4-2-6 0-8 2v14c2-2 4-3 8-2z',
  };
}

/// Stroke icon widget matching the approved `ico()` rendering.
class TcIcon extends StatelessWidget {
  const TcIcon(
    this.name, {
    super.key,
    this.size = 21,
    this.color,
    this.semanticLabel,
    this.mirror = false,
  });

  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF17253D);
    Widget icon = CustomPaint(
      size: Size.square(size),
      painter: _TcIconPainter(name: name, color: resolved),
    );
    if (mirror) {
      icon = Transform.flip(flipX: true, child: icon);
    }
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: SizedBox(width: size, height: size, child: icon),
    );
  }
}

class _TcIconPainter extends CustomPainter {
  _TcIconPainter({required this.name, required this.color});

  final String name;
  final Color color;

  static final Map<String, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final data = TcIconData.paths[name] ?? TcIconData.paths['spark']!;
    final path = _cache.putIfAbsent(name, () => parseSvgPath(data));
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TcIconPainter oldDelegate) =>
      oldDelegate.name != name || oldDelegate.color != color;
}

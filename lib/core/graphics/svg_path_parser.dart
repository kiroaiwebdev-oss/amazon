import 'dart:math' as math;
import 'dart:ui';

/// Minimal SVG path-data parser covering the command subset used by the
/// approved icon set and line-art scenes: M m L l H h V v C c S s A a Z z.
/// Arcs are converted to cubic Bezier segments (standard endpoint->center
/// parameterization, W3C SVG implementation notes B.2.4).
Path parseSvgPath(String data) {
  final path = Path();
  final tokens = _tokenize(data);
  var i = 0;
  var command = '';
  double cx = 0, cy = 0; // current point
  double sx = 0, sy = 0; // subpath start
  double pcx = 0, pcy = 0; // previous cubic control (for S/s)
  var prevWasCubic = false;

  double read() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    final t = tokens[i];
    if (_isCommand(t)) {
      command = t;
      i++;
    } else if (command == 'M') {
      command = 'L';
    } else if (command == 'm') {
      command = 'l';
    }

    switch (command) {
      case 'M':
        cx = read();
        cy = read();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        prevWasCubic = false;
        break;
      case 'm':
        cx += read();
        cy += read();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        prevWasCubic = false;
        break;
      case 'L':
        cx = read();
        cy = read();
        path.lineTo(cx, cy);
        prevWasCubic = false;
        break;
      case 'l':
        cx += read();
        cy += read();
        path.lineTo(cx, cy);
        prevWasCubic = false;
        break;
      case 'H':
        cx = read();
        path.lineTo(cx, cy);
        prevWasCubic = false;
        break;
      case 'h':
        cx += read();
        path.lineTo(cx, cy);
        prevWasCubic = false;
        break;
      case 'V':
        cy = read();
        path.lineTo(cx, cy);
        prevWasCubic = false;
        break;
      case 'v':
        cy += read();
        path.lineTo(cx, cy);
        prevWasCubic = false;
        break;
      case 'C':
        final x1 = read(), y1 = read(), x2 = read(), y2 = read();
        final x = read(), y = read();
        path.cubicTo(x1, y1, x2, y2, x, y);
        pcx = x2;
        pcy = y2;
        cx = x;
        cy = y;
        prevWasCubic = true;
        break;
      case 'c':
        final x1 = cx + read(), y1 = cy + read();
        final x2 = cx + read(), y2 = cy + read();
        final x = cx + read(), y = cy + read();
        path.cubicTo(x1, y1, x2, y2, x, y);
        pcx = x2;
        pcy = y2;
        cx = x;
        cy = y;
        prevWasCubic = true;
        break;
      case 'S':
      case 's':
        final relative = command == 's';
        var x1 = cx, y1 = cy;
        if (prevWasCubic) {
          x1 = 2 * cx - pcx;
          y1 = 2 * cy - pcy;
        }
        var x2 = read(), y2 = read(), x = read(), y = read();
        if (relative) {
          x2 += cx;
          y2 += cy;
          x += cx;
          y += cy;
        }
        path.cubicTo(x1, y1, x2, y2, x, y);
        pcx = x2;
        pcy = y2;
        cx = x;
        cy = y;
        prevWasCubic = true;
        break;
      case 'A':
      case 'a':
        final relative = command == 'a';
        final rx = read(), ry = read(), rot = read();
        final largeArc = read() != 0, sweep = read() != 0;
        var x = read(), y = read();
        if (relative) {
          x += cx;
          y += cy;
        }
        _arcToCubics(path, cx, cy, x, y, rx, ry, rot, largeArc, sweep);
        cx = x;
        cy = y;
        prevWasCubic = false;
        break;
      case 'Z':
      case 'z':
        path.close();
        cx = sx;
        cy = sy;
        prevWasCubic = false;
        break;
      default:
        // Unknown command: stop parsing defensively.
        return path;
    }
  }
  return path;
}

bool _isCommand(String t) =>
    t.length == 1 && 'MmLlHhVvCcSsAaZz'.contains(t);

List<String> _tokenize(String data) {
  final tokens = <String>[];
  final buffer = StringBuffer();
  void flush() {
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
      buffer.clear();
    }
  }

  for (var i = 0; i < data.length; i++) {
    final ch = data[i];
    if ('MmLlHhVvCcSsAaZz'.contains(ch)) {
      flush();
      tokens.add(ch);
    } else if (ch == ' ' || ch == ',' || ch == '\n' || ch == '\t') {
      flush();
    } else if (ch == '-') {
      // '-' starts a new number unless it follows an exponent marker.
      final prev = buffer.toString();
      if (prev.isNotEmpty && !prev.endsWith('e') && !prev.endsWith('E')) {
        flush();
      }
      buffer.write(ch);
    } else if (ch == '.') {
      // A second '.' in one token starts a new number (SVG shorthand).
      if (buffer.toString().contains('.')) {
        flush();
      }
      buffer.write(ch);
    } else {
      buffer.write(ch);
    }
  }
  flush();
  return tokens;
}

void _arcToCubics(
  Path path,
  double x1,
  double y1,
  double x2,
  double y2,
  double rx,
  double ry,
  double rotationDeg,
  bool largeArc,
  bool sweep,
) {
  if (rx == 0 || ry == 0) {
    path.lineTo(x2, y2);
    return;
  }
  rx = rx.abs();
  ry = ry.abs();
  final phi = rotationDeg * math.pi / 180.0;
  final cosPhi = math.cos(phi), sinPhi = math.sin(phi);

  final dx2 = (x1 - x2) / 2.0, dy2 = (y1 - y2) / 2.0;
  final x1p = cosPhi * dx2 + sinPhi * dy2;
  final y1p = -sinPhi * dx2 + cosPhi * dy2;

  var rxSq = rx * rx, rySq = ry * ry;
  final x1pSq = x1p * x1p, y1pSq = y1p * y1p;

  final lambda = x1pSq / rxSq + y1pSq / rySq;
  if (lambda > 1) {
    final scale = math.sqrt(lambda);
    rx *= scale;
    ry *= scale;
    rxSq = rx * rx;
    rySq = ry * ry;
  }

  var sign = (largeArc == sweep) ? -1.0 : 1.0;
  var sq = (rxSq * rySq - rxSq * y1pSq - rySq * x1pSq) /
      (rxSq * y1pSq + rySq * x1pSq);
  sq = sq < 0 ? 0 : sq;
  final coef = sign * math.sqrt(sq);
  final cxp = coef * (rx * y1p / ry);
  final cyp = coef * -(ry * x1p / rx);

  final cx = cosPhi * cxp - sinPhi * cyp + (x1 + x2) / 2.0;
  final cy = sinPhi * cxp + cosPhi * cyp + (y1 + y2) / 2.0;

  double angle(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final len = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
    var ang = math.acos((dot / len).clamp(-1.0, 1.0));
    if (ux * vy - uy * vx < 0) ang = -ang;
    return ang;
  }

  final ux = (x1p - cxp) / rx, uy = (y1p - cyp) / ry;
  final vx = (-x1p - cxp) / rx, vy = (-y1p - cyp) / ry;
  final theta1 = angle(1, 0, ux, uy);
  var deltaTheta = angle(ux, uy, vx, vy);
  if (!sweep && deltaTheta > 0) deltaTheta -= 2 * math.pi;
  if (sweep && deltaTheta < 0) deltaTheta += 2 * math.pi;

  final segments = (deltaTheta.abs() / (math.pi / 2)).ceil().clamp(1, 8);
  final delta = deltaTheta / segments;
  final tFactor = 4 / 3 * math.tan(delta / 4);

  var currentTheta = theta1;
  var px = x1, py = y1;
  for (var s = 0; s < segments; s++) {
    final nextTheta = currentTheta + delta;
    final cos1 = math.cos(currentTheta), sin1 = math.sin(currentTheta);
    final cos2 = math.cos(nextTheta), sin2 = math.sin(nextTheta);

    final ex = cosPhi * rx * cos2 - sinPhi * ry * sin2 + cx;
    final ey = sinPhi * rx * cos2 + cosPhi * ry * sin2 + cy;

    final dx1 = -rx * sin1 * tFactor, dy1 = ry * cos1 * tFactor;
    final dxe = rx * sin2 * tFactor, dye = -ry * cos2 * tFactor;

    final c1x = px + (cosPhi * dx1 - sinPhi * dy1);
    final c1y = py + (sinPhi * dx1 + cosPhi * dy1);
    final c2x = ex + (cosPhi * dxe - sinPhi * dye);
    final c2y = ey + (sinPhi * dxe + cosPhi * dye);

    path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
    px = ex;
    py = ey;
    currentTheta = nextTheta;
  }
}

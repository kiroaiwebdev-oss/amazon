import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinycanvas_adventures/core/responsive/responsive.dart';

/// The 8 representative Amazon Fire tablet logical sizes from the approved
/// device matrix (both orientations of each panel).
const kFireSizes = [
  Size(600, 1024),
  Size(1024, 600),
  Size(800, 1280),
  Size(1280, 800),
  Size(1200, 1920),
  Size(1920, 1200),
  Size(1200, 2000),
  Size(2000, 1200),
];

void main() {
  test('layout classes match the approved breakpoints', () {
    expect(Responsive(const Size(600, 1024), 1.0).layout, FireLayout.compact);
    expect(Responsive(const Size(800, 1280), 1.0).layout, FireLayout.medium);
    expect(
        Responsive(const Size(1024, 600), 1.0).layout, FireLayout.medium);
    expect(
        Responsive(const Size(1920, 1200), 1.0).layout, FireLayout.expanded);
  });

  test('grid columns are 2/3/4 and drop one at very large text', () {
    expect(Responsive(const Size(600, 1024), 1.0).gridColumns(), 2);
    expect(Responsive(const Size(800, 1280), 1.0).gridColumns(), 3);
    expect(Responsive(const Size(1920, 1200), 1.0).gridColumns(), 4);
    expect(Responsive(const Size(1920, 1200), 1.8).gridColumns(), 3);
  });

  test('orientation is detected for every Fire size', () {
    for (final size in kFireSizes) {
      final r = Responsive(size, 1.0);
      expect(r.isLandscape, size.width > size.height,
          reason: 'orientation for $size');
    }
  });

  test('nav rail appears at >=720 width, bottom nav below', () {
    expect(Responsive(const Size(600, 1024), 1.0).useRail, isFalse);
    expect(Responsive(const Size(1024, 600), 1.0).useRail, isTrue);
    expect(Responsive(const Size(800, 1280), 1.0).useRail, isTrue);
  });

  test('split layouts collapse when compact or at 200% text', () {
    expect(Responsive(const Size(600, 1024), 1.0).splitCollapses, isTrue);
    expect(Responsive(const Size(1280, 800), 1.0).splitCollapses, isFalse);
    expect(Responsive(const Size(1280, 800), 2.0).splitCollapses, isTrue);
  });

  test('rail narrows on sub-900 widths per the approved media query', () {
    expect(Responsive(const Size(800, 1280), 1.0).railWidth, 74);
    expect(Responsive(const Size(1920, 1200), 1.0).railWidth, 94);
  });
}

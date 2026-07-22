import 'package:flutter/widgets.dart';

/// Fire-tablet responsive classes. Derived from the approved artboards:
/// 600x1024 / 1024x600 (standard), 800x1280 / 1280x800 (HD 8),
/// 1200x1920 / 1920x1200 (HD 10), 1200x2000 / 2000x1200 (Max 11 class).
enum FireLayout {
  /// < 720 dp wide: portrait standard Fire. Bottom navigation, 2 columns.
  compact,

  /// 720-1080 dp wide: HD portrait / standard landscape. Rail, 3 columns.
  medium,

  /// >= 1080 dp wide: HD/Max landscape. Rail, 4 columns, master-detail.
  expanded,
}

class Responsive {
  Responsive(this.size, this.textScale);

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive(mq.size, mq.textScaler.scale(14) / 14);
  }

  final Size size;
  final double textScale;

  FireLayout get layout {
    if (size.width < 720) return FireLayout.compact;
    if (size.width < 1080) return FireLayout.medium;
    return FireLayout.expanded;
  }

  bool get isLandscape => size.width > size.height;

  /// Grid columns for picture/category shelves (.grid-4 with @media rules).
  int gridColumns({int max = 4}) {
    final cols = switch (layout) {
      FireLayout.compact => 2,
      FireLayout.medium => 3,
      FireLayout.expanded => 4,
    };
    final scaled = textScale >= 1.6 ? cols - 1 : cols;
    return scaled.clamp(1, max);
  }

  /// Whether the split (.split 1.15fr/.85fr) collapses to one column.
  bool get splitCollapses => layout == FireLayout.compact || textScale >= 1.7;

  /// Rail width per @media rule (94px, 74px under 900px width).
  double get railWidth => size.width < 900 ? 74 : 94;

  /// Whether navigation renders as the left rail (approved default) or the
  /// compact bottom bar (approved for the narrowest portrait class).
  bool get useRail => size.width >= 720;

  EdgeInsets get mainPadding => layout == FireLayout.compact
      ? const EdgeInsets.fromLTRB(22, 22, 22, 22)
      : const EdgeInsets.fromLTRB(32, 28, 32, 36);
}

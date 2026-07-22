import '../../data/models.dart';
import '../../data/repositories.dart';

/// Records badge progress from coloring activity.
///
/// Badge rules (approved set):
/// - creative_explorer: color 20 different pictures (key = catalogItemId)
/// - tool_taster: try 4 different tools (key = tool name)
/// - category_adventurer: color in all 8 categories (key = category)
/// - color_collector: use all 24 named colors (key = color name)
///
/// [BadgeRepository.recordProgress] de-duplicates keys, so repeated sessions
/// with the same picture/tool/category/color never double-count.
class BadgeService {
  BadgeService(this._badges);

  final BadgeRepository _badges;

  /// Records one coloring session; returns badges newly earned by it.
  Future<List<BadgeDef>> recordColoringSession({
    required String catalogItemId,
    required String category,
    required Set<String> toolsUsed,
    required Set<String> colorNamesUsed,
  }) async {
    final earned = <BadgeDef>[];
    void collect(BadgeDef? def) {
      if (def != null) earned.add(def);
    }

    collect(await _badges.recordProgress('creative_explorer', catalogItemId));
    collect(await _badges.recordProgress('category_adventurer', category));
    for (final tool in toolsUsed) {
      collect(await _badges.recordProgress('tool_taster', tool));
    }
    for (final color in colorNamesUsed) {
      collect(await _badges.recordProgress('color_collector', color));
    }
    return earned;
  }
}

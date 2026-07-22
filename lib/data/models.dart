/// Core domain models. All data is local-only; no model carries any child
/// identifier, account, or network-facing field.
library;

enum Difficulty { beginner, explorer, creator }

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
        Difficulty.beginner => 'Beginner',
        Difficulty.explorer => 'Explorer',
        Difficulty.creator => 'Creator',
      };

  static Difficulty parse(String raw) => Difficulty.values.firstWhere(
        (d) => d.name == raw,
        orElse: () => Difficulty.beginner,
      );
}

/// The eight approved categories, in approved display order.
const List<String> kCategories = [
  'Going Places',
  'Circus',
  'Tiny Treasures',
  'Home',
  'Beach',
  'City',
  'Nature',
  'Adorable Friends',
];

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.premium,
    required this.assetSeed,
    required this.keywords,
    required this.contentVersion,
  });

  final String id;
  final String title;
  final String category;
  final Difficulty difficulty;
  final bool premium;

  /// Seed for the procedural vector line art / thumbnail (resolution
  /// independent; acts as the asset path in the bundled catalog).
  final int assetSeed;
  final String keywords;
  final int contentVersion;

  Map<String, Object?> toRow() => {
        'id': id,
        'title': title,
        'category': category,
        'difficulty': difficulty.name,
        'premium': premium ? 1 : 0,
        'asset_path': 'procedural://line/$assetSeed',
        'thumbnail_path': 'procedural://thumb/$assetSeed',
        'search_keywords': keywords,
        'content_version': contentVersion,
      };

  static CatalogItem fromRow(Map<String, Object?> row) => CatalogItem(
        id: row['id']! as String,
        title: row['title']! as String,
        category: row['category']! as String,
        difficulty: DifficultyLabel.parse(row['difficulty']! as String),
        premium: (row['premium']! as int) == 1,
        assetSeed: int.parse(
            (row['asset_path']! as String).split('/').last),
        keywords: (row['search_keywords'] ?? '') as String,
        contentVersion: (row['content_version'] ?? 1) as int,
      );
}

class Artwork {
  const Artwork({
    required this.id,
    required this.catalogItemId,
    required this.displayName,
    required this.documentPath,
    required this.previewPath,
    required this.createdAt,
    required this.updatedAt,
    required this.favorite,
    required this.completed,
  });

  final String id;
  final String catalogItemId;
  final String displayName;
  final String documentPath;
  final String previewPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool favorite;
  final bool completed;

  Artwork copyWith({
    String? displayName,
    DateTime? updatedAt,
    bool? favorite,
    bool? completed,
  }) =>
      Artwork(
        id: id,
        catalogItemId: catalogItemId,
        displayName: displayName ?? this.displayName,
        documentPath: documentPath,
        previewPath: previewPath,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        favorite: favorite ?? this.favorite,
        completed: completed ?? this.completed,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'catalog_item_id': catalogItemId,
        'display_name': displayName,
        'document_path': documentPath,
        'preview_path': previewPath,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'favorite': favorite ? 1 : 0,
        'completed': completed ? 1 : 0,
      };

  static Artwork fromRow(Map<String, Object?> row) => Artwork(
        id: row['id']! as String,
        catalogItemId: row['catalog_item_id']! as String,
        displayName: row['display_name']! as String,
        documentPath: row['document_path']! as String,
        previewPath: row['preview_path']! as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
        favorite: (row['favorite']! as int) == 1,
        completed: (row['completed']! as int) == 1,
      );
}

/// Artwork display-name rules (Rename dialog): 1-40 characters after
/// trimming; path/control characters are stripped for safety.
String sanitizeArtworkName(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(RegExp(r'[\x00-\x1f]'), '')
      .trim();
  return cleaned;
}

bool isValidArtworkName(String raw) {
  final s = sanitizeArtworkName(raw);
  return s.isNotEmpty && s.length <= 40;
}

class BadgeState {
  const BadgeState({
    required this.badgeId,
    required this.progress,
    required this.target,
    this.earnedAt,
  });

  final String badgeId;
  final int progress;
  final int target;
  final DateTime? earnedAt;

  bool get earned => earnedAt != null;
  double get fraction => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);
}

class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.target,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int target;
}

/// The approved local badge set. No streaks, no timers, no pressure.
const List<BadgeDef> kBadges = [
  BadgeDef(
    id: 'creative_explorer',
    name: 'Creative Explorer',
    description: 'Color 20 different pictures',
    icon: 'spark',
    target: 20,
  ),
  BadgeDef(
    id: 'tool_taster',
    name: 'Tool Taster',
    description: 'Try four different coloring tools',
    icon: 'brush',
    target: 4,
  ),
  BadgeDef(
    id: 'category_adventurer',
    name: 'Category Adventurer',
    description: 'Visit all 8 worlds',
    icon: 'grid',
    target: 8,
  ),
  BadgeDef(
    id: 'color_collector',
    name: 'Color Collector',
    description: 'Use all 24 named colors',
    icon: 'star',
    target: 24,
  ),
];

enum SoundMode { playful, quiet, silent }

class AppSettings {
  const AppSettings({
    this.onboardingCompleted = false,
    this.voiceEnabled = true,
    this.soundEffectsEnabled = true,
    this.musicEnabled = true,
    this.reducedMotion = false,
    this.highContrast = false,
    this.soundMode = SoundMode.playful,
  });

  final bool onboardingCompleted;
  final bool voiceEnabled;
  final bool soundEffectsEnabled;
  final bool musicEnabled;
  final bool reducedMotion;
  final bool highContrast;
  final SoundMode soundMode;

  AppSettings copyWith({
    bool? onboardingCompleted,
    bool? voiceEnabled,
    bool? soundEffectsEnabled,
    bool? musicEnabled,
    bool? reducedMotion,
    bool? highContrast,
    SoundMode? soundMode,
  }) =>
      AppSettings(
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
        soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        highContrast: highContrast ?? this.highContrast,
        soundMode: soundMode ?? this.soundMode,
      );

  Map<String, String> toMap() => {
        'onboarding_completed': onboardingCompleted ? '1' : '0',
        'voice_enabled': voiceEnabled ? '1' : '0',
        'sound_effects_enabled': soundEffectsEnabled ? '1' : '0',
        'music_enabled': musicEnabled ? '1' : '0',
        'reduced_motion': reducedMotion ? '1' : '0',
        'high_contrast': highContrast ? '1' : '0',
        'sound_mode': soundMode.name,
      };

  static AppSettings fromMap(Map<String, String> map) => AppSettings(
        onboardingCompleted: map['onboarding_completed'] == '1',
        voiceEnabled: map['voice_enabled'] != '0',
        soundEffectsEnabled: map['sound_effects_enabled'] != '0',
        musicEnabled: map['music_enabled'] != '0',
        reducedMotion: map['reduced_motion'] == '1',
        highContrast: map['high_contrast'] == '1',
        soundMode: SoundMode.values.firstWhere(
          (m) => m.name == map['sound_mode'],
          orElse: () => SoundMode.playful,
        ),
      );
}

enum OwnershipState { unknown, notOwned, pending, owned }

class EntitlementCache {
  const EntitlementCache({
    required this.productId,
    required this.state,
    this.verifiedAt,
  });

  final String productId;
  final OwnershipState state;
  final DateTime? verifiedAt;
}

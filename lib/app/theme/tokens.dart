import 'package:flutter/widgets.dart';

/// Design tokens extracted 1:1 from the approved UI source (`styles.css`).
/// Every visual constant in the app must come from this file so the Flutter
/// build stays in lock-step with the approved design system.
abstract final class TcColors {
  // :root custom properties from styles.css
  static const ink = Color(0xFF17253D); // --ink
  static const muted = Color(0xFF667085); // --muted
  static const canvas = Color(0xFFF6F4EF); // --canvas
  static const paper = Color(0xFFFFFDF8); // --paper
  static const navy = Color(0xFF111C34); // --navy
  static const blue = Color(0xFF3E7FA0); // --blue
  static const blue2 = Color(0xFF69B3C8); // --blue2
  static const coral = Color(0xFFED6B67); // --coral
  static const gold = Color(0xFFF2BD55); // --gold
  static const leaf = Color(0xFF58A678); // --leaf
  static const violet = Color(0xFF8C76CF); // --violet
  static const line = Color(0xFFE8E3D8); // --line

  // Rail gradient (.rail)
  static const railTop = Color(0xFF15233F);
  static const railBottom = Color(0xFF111A30);
  static const railIcon = Color(0xFFB7C0D3);

  // Button gradients
  static const primaryGradStart = Color(0xFF397D9D); // .btn-primary
  static const primaryGradEnd = Color(0xFF5AA8BE);
  static const coralGradStart = Color(0xFFE95F61); // .btn-coral
  static const coralGradEnd = Color(0xFFEF8177);
  static const brandGradStart = coral; // .brandmark 135deg coral->gold
  static const brandGradEnd = gold;

  // Hero gradient (.hero)
  static const heroStart = Color(0xFF1A2B4D);
  static const heroMid = Color(0xFF244E68);
  static const heroEnd = Color(0xFF5BAAC0);

  // Status / soft surfaces
  static const dangerText = Color(0xFFAD2D35); // .btn-danger color
  static const dangerBg = Color(0xFFFFF0EF); // .btn-danger background
  static const badgeBg = Color(0xFFEDF6F8); // .badge
  static const badgeText = Color(0xFF2D728D);
  static const badgeGoldBg = Color(0xFFFFF5D9); // .badge.gold
  static const badgeGoldText = Color(0xFF8A5B00);
  static const badgeCoralBg = Color(0xFFFFF0EF); // .badge.coral
  static const badgeCoralText = Color(0xFFB34245);
  static const rowIconBg = Color(0xFFEEF6F8); // .row-icon
  static const tabsBg = Color(0xFFEBE9E3); // .tabs
  static const artBoardBg = Color(0xFFF0EDE5); // .art-board
  static const skeletonBase = Color(0xFFECEAE5); // .skeleton
  static const skeletonHighlight = Color(0xFFF8F7F4);
  static const switchOff = Color(0xFFD5D9E0); // .switch
  static const legalBody = Color(0xFF586174); // .legal p
  static const progressTrack = Color(0xFFE9E7E2); // .progress

  // High-contrast overrides (accessibility setting). Boundaries and states
  // get stronger separation while keeping the approved hue family.
  static const hcInk = Color(0xFF0A1220);
  static const hcLine = Color(0xFF8C8677);
  static const hcMuted = Color(0xFF3D4657);
}

/// The approved 24-color, named, child-friendly studio palette.
/// The first 16 names come directly from Screen 13 (Color Palette); the final
/// 8 extend the same storybook families to reach the required 24 named colors
/// (documented in docs/ASSUMPTIONS.md).
class NamedColor {
  const NamedColor(this.name, this.color);
  final String name;
  final Color color;
}

abstract final class TcPalette {
  static const List<NamedColor> colors = [
    NamedColor('Ink Blue', Color(0xFF17253D)),
    NamedColor('Coral', Color(0xFFEF6B67)),
    NamedColor('Sun Gold', Color(0xFFF2BD55)),
    NamedColor('Leaf', Color(0xFF58A678)),
    NamedColor('Sky', Color(0xFF69B3C8)),
    NamedColor('Lavender', Color(0xFF8C76CF)),
    NamedColor('Rose', Color(0xFFF4A6C0)),
    NamedColor('Cocoa', Color(0xFF8C644F)),
    NamedColor('Mint', Color(0xFFBFE6D1)),
    NamedColor('Ocean', Color(0xFF287DA0)),
    NamedColor('Peach', Color(0xFFFFC6A7)),
    NamedColor('Plum', Color(0xFF6F3B70)),
    NamedColor('Cloud', Color(0xFFE9EEF5)),
    NamedColor('Stone', Color(0xFF8F969D)),
    NamedColor('Sand', Color(0xFFDCC8A8)),
    NamedColor('White', Color(0xFFFFFFFF)),
    NamedColor('Night', Color(0xFF10131C)),
    NamedColor('Berry', Color(0xFFB4436C)),
    NamedColor('Grass', Color(0xFF7FBF62)),
    NamedColor('Honey', Color(0xFFE0A128)),
    NamedColor('Flamingo', Color(0xFFFF8FA3)),
    NamedColor('Sea Glass', Color(0xFF9FD1DC)),
    NamedColor('Butter', Color(0xFFF7E38E)),
    NamedColor('Charcoal', Color(0xFF3E4756)),
  ];

  static String nameOf(Color color) {
    for (final n in colors) {
      if (n.color.value == color.value) return n.name;
    }
    return 'Custom color';
  }
}

abstract final class TcRadius {
  static const double panel = 28; // --radius
  static const double small = 18; // --radius-sm
  static const double card = 22; // .card
  static const double button = 16; // .btn
  static const double chip = 999; // .badge/.chip pill
  static const double modal = 30; // .modal
  static const double device = 34; // .device
  static const double tool = 15; // .tool
  static const double search = 18; // .search
  static const double row = 18; // .row
}

abstract final class TcSpace {
  // Spacing scale observed across the approved screens.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18; // .grid gap
  static const double xl = 22; // .split gap
  static const double xxl = 28; // .main padding top
  static const double mainH = 32; // .main horizontal padding
  static const double mainB = 36; // .main bottom padding
}

abstract final class TcSize {
  static const double railWidth = 94; // .app grid-template-columns
  static const double railWidthCompact = 74; // @media max-width 900
  static const double navItemHeight = 62; // .nav-item
  static const double brandmark = 52; // .brandmark
  static const double iconButton = 48; // .icon-btn (caregiver min target)
  static const double buttonMinHeight = 48; // .btn min-height
  static const double childMinTarget = 56; // child-facing minimum target
  static const double searchHeight = 54; // .search
  static const double tool = 48; // .tool
  static const double swatch = 28; // .swatch
  static const double rowIcon = 46; // .row-icon
  static const double switchWidth = 46; // .switch
  static const double switchHeight = 26;
  static const double progressHeight = 9; // .progress
  static const double thumbHeight = 120; // .thumb
}

abstract final class TcShadows {
  static const panel = [
    BoxShadow(
      color: Color(0x2117253D), // rgba(23,37,61,.13)
      offset: Offset(0, 18),
      blurRadius: 50,
    ),
  ];
  static const card = [
    BoxShadow(
      color: Color(0x1417253D), // rgba(23,37,61,.08)
      offset: Offset(0, 10),
      blurRadius: 30,
    ),
  ];
  static const softButton = [
    BoxShadow(
      color: Color(0x0F17253D), // rgba(23,37,61,.06)
      offset: Offset(0, 5),
      blurRadius: 16,
    ),
  ];
  static const primaryButton = [
    BoxShadow(
      color: Color(0x3D3E7FA0), // rgba(62,127,160,.24)
      offset: Offset(0, 10),
      blurRadius: 24,
    ),
  ];
  static const brandmark = [
    BoxShadow(
      color: Color(0x59ED6B67), // rgba(237,107,103,.35)
      offset: Offset(0, 10),
      blurRadius: 24,
    ),
  ];
  static const dock = [
    BoxShadow(
      color: Color(0x40111C34), // rgba(17,28,52,.25)
      offset: Offset(0, 14),
      blurRadius: 30,
    ),
  ];
  static const modal = [
    BoxShadow(
      color: Color(0x4D111C34), // rgba(17,28,52,.3)
      offset: Offset(0, 30),
      blurRadius: 80,
    ),
  ];
  static const paper = [
    BoxShadow(
      color: Color(0x2917253D), // rgba(23,37,61,.16)
      offset: Offset(0, 18),
      blurRadius: 38,
    ),
  ];
}

abstract final class TcDurations {
  // Reduced-motion setting collapses all of these to Duration.zero.
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const shimmer = Duration(milliseconds: 1700); // .skeleton animation
  static const celebration = Duration(milliseconds: 900);
  static const autosaveIdle = Duration(seconds: 2);
  static const deleteUndoWindow = Duration(seconds: 5);
  static const adultGateHold = Duration(seconds: 3);
  static const adultGateCooldown = Duration(seconds: 30);
  static const eraseHold = Duration(seconds: 5);
  static const curve = Curves.easeOutCubic;
}

abstract final class TcType {
  // Approved family is Inter with system-ui fallback. Inter is not bundled
  // (no redistributable font file in the UI ZIP); Roboto is the documented
  // closest system equivalent on Fire OS - see docs/UI_FIDELITY_EXCEPTIONS.md.
  static const String? fontFamily = null; // platform default (Roboto)

  static const TextStyle h1 = TextStyle(
    fontSize: 31, height: 1.1, letterSpacing: -1.05,
    fontWeight: FontWeight.w800, color: TcColors.ink,
  );
  static const TextStyle h1Hero = TextStyle(
    fontSize: 40, height: 1.1, letterSpacing: -1.4,
    fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF),
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 23, letterSpacing: -0.45,
    fontWeight: FontWeight.w800, color: TcColors.ink,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w800, color: TcColors.ink,
  );
  static const TextStyle sub = TextStyle(
    fontSize: 14, height: 1.5, color: TcColors.muted,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11, letterSpacing: 1.55, fontWeight: FontWeight.w800,
    color: TcColors.blue,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700,
  );
  static const TextStyle badge = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w800,
  );
  static const TextStyle navLabel = TextStyle(
    fontSize: 10, color: TcColors.railIcon,
  );
  static const TextStyle price = TextStyle(
    fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -2.1,
    color: TcColors.ink,
  );
  static const TextStyle metric = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800, color: TcColors.ink,
  );
  static const TextStyle rowTitle = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700, color: TcColors.ink,
  );
  static const TextStyle rowSubtitle = TextStyle(
    fontSize: 12, color: TcColors.muted,
  );
  static const TextStyle legalBody = TextStyle(
    fontSize: 13, height: 1.7, color: TcColors.legalBody,
  );
}

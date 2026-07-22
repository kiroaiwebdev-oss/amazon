import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import 'tc_icons.dart';

/// Reusable widgets mirroring the approved component library in styles.css.
/// Every screen is composed from these instead of screen-specific styling.

enum TcButtonKind { primary, dark, soft, coral, danger, link }

class TcButton extends StatelessWidget {
  const TcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = TcButtonKind.primary,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.childFacing = false,
    this.semanticHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final TcButtonKind kind;
  final String? icon;
  final String? trailingIcon;
  final bool expand;

  /// Child-facing controls get the larger 56dp minimum target.
  final bool childFacing;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final minHeight =
        childFacing ? TcSize.childMinTarget : TcSize.buttonMinHeight;

    Gradient? gradient;
    Color? bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadow;
    switch (kind) {
      case TcButtonKind.primary:
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TcColors.primaryGradStart, TcColors.primaryGradEnd],
        );
        fg = Colors.white;
        shadow = TcShadows.primaryButton;
        break;
      case TcButtonKind.dark:
        bg = TcColors.navy;
        fg = Colors.white;
        break;
      case TcButtonKind.soft:
        bg = Colors.white;
        fg = x.ink;
        border = Border.all(color: x.line);
        shadow = TcShadows.softButton;
        break;
      case TcButtonKind.coral:
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TcColors.coralGradStart, TcColors.coralGradEnd],
        );
        fg = Colors.white;
        break;
      case TcButtonKind.danger:
        bg = TcColors.dangerBg;
        fg = TcColors.dangerText;
        break;
      case TcButtonKind.link:
        bg = Colors.transparent;
        fg = TcColors.blue;
        break;
    }

    final disabled = onPressed == null;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          TcIcon(icon!, size: 19, color: fg),
          const SizedBox(width: 9),
        ],
        Flexible(
          child: Text(
            label,
            style: TcType.button.copyWith(color: fg),
            textAlign: TextAlign.center,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 9),
          TcIcon(trailingIcon!, size: 19, color: fg),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      hint: semanticHint,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              color: bg,
              border: border,
              borderRadius: BorderRadius.circular(TcRadius.button),
              boxShadow: disabled ? null : shadow,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(TcRadius.button),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minHeight,
                  minWidth: childFacing ? TcSize.childMinTarget : 0,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
                  child: Center(widthFactor: 1, child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TcIconButton extends StatelessWidget {
  const TcIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.mirror = false,
  });

  final String icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: TcSize.iconButton,
            height: TcSize.iconButton,
            decoration: BoxDecoration(
              color: const Color(0xDBFFFFFF),
              border: Border.all(color: x.line),
              borderRadius: BorderRadius.circular(16),
              boxShadow: TcShadows.softButton,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: TcIcon(icon, size: 21, color: x.ink, mirror: mirror),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum TcBadgeKind { normal, gold, coral }

class TcBadge extends StatelessWidget {
  const TcBadge(this.label, {super.key, this.kind = TcBadgeKind.normal, this.icon});

  final String label;
  final TcBadgeKind kind;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      TcBadgeKind.normal => (TcColors.badgeBg, TcColors.badgeText),
      TcBadgeKind.gold => (TcColors.badgeGoldBg, TcColors.badgeGoldText),
      TcBadgeKind.coral => (TcColors.badgeCoralBg, TcColors.badgeCoralText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TcRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            TcIcon(icon!, size: 12, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label, style: TcType.badge.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class TcChip extends StatelessWidget {
  const TcChip(
    this.label, {
    super.key,
    this.active = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final fg = active ? Colors.white : x.muted;
    return Semantics(
      button: onTap != null,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: active ? TcColors.navy : Colors.white,
            border: Border.all(color: active ? TcColors.navy : x.line),
            borderRadius: BorderRadius.circular(TcRadius.chip),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TcRadius.chip),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      TcIcon(icon!, size: 14, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(label, style: TcType.badge.copyWith(color: fg)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TcPanel extends StatelessWidget {
  const TcPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = TcRadius.panel,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? const Color(0xE0FFFFFF),
        border: Border.all(color: const Color(0xE6FFFFFF)),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: TcShadows.panel,
      ),
      padding: padding,
      child: child,
    );
  }
}

class TcCard extends StatelessWidget {
  const TcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.onTap,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        border: Border.all(color: const Color(0xF2FFFFFF)),
        borderRadius: BorderRadius.circular(TcRadius.card),
        boxShadow: [
          ...TcShadows.card,
          if (selected)
            const BoxShadow(color: TcColors.navy, spreadRadius: 3),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TcRadius.card),
        child: card,
      ),
    );
  }
}

class TcMetric extends StatelessWidget {
  const TcMetric({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TcType.metric.copyWith(color: x.ink)),
          const SizedBox(height: 5),
          Text(label, style: TcType.rowSubtitle.copyWith(color: x.muted)),
        ],
      ),
    );
  }
}

class TcRowTile extends StatelessWidget {
  const TcRowTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = 'settings',
    this.onTap,
    this.switchValue,
    this.onSwitchChanged,
    this.iconColor,
    this.iconBg,
  });

  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final Color? iconColor;
  final Color? iconBg;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final isSwitch = switchValue != null;
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: x.line),
        borderRadius: BorderRadius.circular(TcRadius.row),
      ),
      child: Row(
        children: [
          Container(
            width: TcSize.rowIcon,
            height: TcSize.rowIcon,
            decoration: BoxDecoration(
              color: iconBg ?? TcColors.rowIconBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: TcIcon(icon, size: 22, color: iconColor ?? TcColors.blue),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TcType.rowTitle.copyWith(color: x.ink)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TcType.rowSubtitle.copyWith(color: x.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSwitch)
            TcSwitch(value: switchValue!, onChanged: onSwitchChanged)
          else
            TcIcon('forward', size: 20, color: x.muted),
        ],
      ),
    );
    if (onTap == null && !isSwitch) return row;
    if (isSwitch) {
      return Semantics(
        toggled: switchValue,
        label: '$title. $subtitle',
        child: GestureDetector(
          onTap: onSwitchChanged == null
              ? null
              : () => onSwitchChanged!(!switchValue!),
          child: row,
        ),
      );
    }
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TcRadius.row),
        child: row,
      ),
    );
  }
}

class TcSwitch extends StatelessWidget {
  const TcSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: x.motion(TcDurations.fast),
        width: TcSize.switchWidth,
        height: TcSize.switchHeight,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? TcColors.blue : TcColors.switchOff,
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: x.motion(TcDurations.fast),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TcProgressBar extends StatelessWidget {
  const TcProgressBar(this.value, {super.key, this.semanticLabel});

  final double value; // 0..1
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: TcSize.progressHeight,
          color: TcColors.progressTrack,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [TcColors.blue, TcColors.blue2],
                ),
                borderRadius: BorderRadius.all(Radius.circular(99)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TcSearchField extends StatelessWidget {
  const TcSearchField({
    super.key,
    this.controller,
    this.hint = 'Find animals, places, or scenes',
    this.onChanged,
    this.onClear,
    this.trailing,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? trailing;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Container(
      height: TcSize.searchHeight,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: x.line),
        borderRadius: BorderRadius.circular(TcRadius.search),
      ),
      child: Row(
        children: [
          TcIcon('search', size: 21, color: x.muted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              readOnly: readOnly,
              onTap: onTap,
              style: TcType.rowTitle.copyWith(color: x.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TcType.sub.copyWith(color: x.muted),
              ),
            ),
          ),
          if (onClear != null)
            TcIconGestureTarget(
              semanticLabel: 'Clear search',
              onTap: onClear!,
              child: TcIcon('close', size: 18, color: x.muted),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Wraps a small glyph in an accessible >=48dp tap target.
class TcIconGestureTarget extends StatelessWidget {
  const TcIconGestureTarget({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 48, height: 48, child: Center(child: child)),
      ),
    );
  }
}

class TcTabs extends StatelessWidget {
  const TcTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: TcColors.tabsBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            Semantics(
              button: true,
              selected: i == selectedIndex,
              label: labels[i],
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? Colors.white : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == selectedIndex
                        ? const [
                            BoxShadow(
                              color: Color(0x1417253D),
                              offset: Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TcType.badge.copyWith(
                      fontSize: 12,
                      color: i == selectedIndex ? x.ink : x.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TcSkeleton extends StatefulWidget {
  const TcSkeleton({super.key, this.height = 14, this.width, this.radius = 15});

  final double height;
  final double? width;
  final double radius;

  @override
  State<TcSkeleton> createState() => _TcSkeletonState();
}

class _TcSkeletonState extends State<TcSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: TcDurations.shimmer);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = TcThemeX.of(context).reduceMotion;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * _controller.value, 0),
              end: Alignment(1 + 2 * (1 - _controller.value), 0),
              colors: const [
                TcColors.skeletonBase,
                TcColors.skeletonHighlight,
                TcColors.skeletonBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

class TcBanner extends StatelessWidget {
  const TcBanner({
    super.key,
    required this.icon,
    required this.boldText,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String icon;
  final String boldText;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$boldText $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: TcColors.ink,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            TcIcon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '$boldText ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: text),
                ]),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              TcButton(
                label: actionLabel!,
                kind: TcButtonKind.soft,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TcBrandmark extends StatelessWidget {
  const TcBrandmark({super.key, this.size = TcSize.brandmark, this.radius = 18});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TcColors.brandGradStart, TcColors.brandGradEnd],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: TcShadows.brandmark,
      ),
      child: Center(
        child: TcIcon('brush', size: size * 0.58, color: Colors.white),
      ),
    );
  }
}

class TcEyebrow extends StatelessWidget {
  const TcEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TcType.eyebrow.copyWith(color: color ?? TcColors.blue),
    );
  }
}

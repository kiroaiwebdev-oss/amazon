import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../responsive/responsive.dart';
import 'tc_icons.dart';
import 'tc_widgets.dart';

enum TcNavSection { home, explore, art, parents }

/// The approved app shell: dark navy navigation rail (Home / Explore /
/// My Art / Parents) on the left, warm-canvas content on the right with
/// storybook radial washes. On the narrowest portrait class the rail becomes
/// an equivalent bottom navigation bar with identical items.
class TcShell extends StatelessWidget {
  const TcShell({
    super.key,
    required this.active,
    required this.child,
    this.onNavigate,
    this.scrollable = true,
  });

  final TcNavSection active;
  final Widget child;
  final void Function(TcNavSection section)? onNavigate;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final content = Container(
      decoration: const BoxDecoration(
        color: TcColors.canvas,
        gradient: RadialGradient(
          center: Alignment(0.7, -0.84),
          radius: 0.9,
          colors: [Color(0x2B69B3C8), Color(0x00000000)],
          stops: [0.0, 0.32],
        ),
      ),
      child: scrollable
          ? SingleChildScrollView(padding: r.mainPadding, child: child)
          : Padding(padding: r.mainPadding, child: child),
    );

    if (r.useRail) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _Rail(active: active, onNavigate: onNavigate, width: r.railWidth),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: content),
      bottomNavigationBar: _BottomNav(active: active, onNavigate: onNavigate),
    );
  }
}

const _navItems = [
  (TcNavSection.home, 'home', 'Home'),
  (TcNavSection.explore, 'grid', 'Explore'),
  (TcNavSection.art, 'art', 'My Art'),
];

class _Rail extends StatelessWidget {
  const _Rail({required this.active, this.onNavigate, required this.width});

  final TcNavSection active;
  final void Function(TcNavSection)? onNavigate;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TcColors.railTop, TcColors.railBottom],
        ),
      ),
      child: Column(
        children: [
          const TcBrandmark(),
          const SizedBox(height: 30),
          for (final (section, icon, label) in _navItems) ...[
            _RailItem(
              icon: icon,
              label: label,
              active: active == section,
              onTap: onNavigate == null ? null : () => onNavigate!(section),
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          _RailItem(
            icon: 'shield',
            label: 'Parents',
            active: active == TcNavSection.parents,
            onTap: onNavigate == null
                ? null
                : () => onNavigate!(TcNavSection.parents),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : TcColors.railIcon;
    return Semantics(
      button: true,
      selected: active,
      label: '$label tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: TcSize.navItemHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: active ? const Color(0x1FFFFFFF) : null,
              borderRadius: BorderRadius.circular(18),
              border: active
                  ? Border.all(color: const Color(0x14FFFFFF))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TcIcon(icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(label, style: TcType.navLabel.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.active, this.onNavigate});

  final TcNavSection active;
  final void Function(TcNavSection)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = [..._navItems, (TcNavSection.parents, 'shield', 'Parents')];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TcColors.railTop, TcColors.railBottom],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final (section, icon, label) in items)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: active == section,
                    label: '$label tab',
                    child: InkWell(
                      onTap: onNavigate == null
                          ? null
                          : () => onNavigate!(section),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TcIcon(icon,
                              size: 22,
                              color: active == section
                                  ? Colors.white
                                  : TcColors.railIcon),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TcType.navLabel.copyWith(
                              color: active == section
                                  ? Colors.white
                                  : TcColors.railIcon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The approved topbar: optional eyebrow + H1 on the left, action cluster
/// (search, parents shield, avatar) on the right.
class TcTopbar extends StatelessWidget {
  const TcTopbar({
    super.key,
    required this.title,
    this.eyebrow,
    this.showActions = true,
    this.leading,
    this.actions,
    this.onSearch,
    this.onParents,
  });

  final String title;
  final String? eyebrow;
  final bool showActions;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onSearch;
  final VoidCallback? onParents;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  TcEyebrow(eyebrow!),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: TcType.h1.copyWith(color: x.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (actions != null)
            ...actions!
          else if (showActions) ...[
            TcIconButton(
              icon: 'search',
              semanticLabel: 'Search pictures',
              onPressed: onSearch,
            ),
            const SizedBox(width: 10),
            TcIconButton(
              icon: 'shield',
              semanticLabel: 'Parent Zone',
              onPressed: onParents,
            ),
          ],
        ],
      ),
    );
  }
}

/// Approved modal: dimmed navy scrim, centered rounded card. Pass any
/// widget (usually a TcModalCard) as the dialog content.
Future<T?> showTcModal<T>(
  BuildContext context,
  Widget child, {
  bool dismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: const Color(0x85111C34),
    builder: (_) => child,
  );
}

class TcModalCard extends StatelessWidget {
  const TcModalCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = 'spark',
    this.iconBg,
    this.iconColor,
    this.customVisual,
    this.content,
    this.showProgress = false,
    this.actions = const [],
  });

  final String title;
  final String body;
  final String icon;
  final Color? iconBg;
  final Color? iconColor;

  /// Replaces the default icon visual when provided (e.g. badge art).
  final Widget? customVisual;
  final Widget? content;
  final bool showProgress;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: TcColors.paper,
            borderRadius: BorderRadius.circular(TcRadius.modal),
            boxShadow: TcShadows.modal,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                customVisual ??
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        gradient: iconBg == null
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE8F4F6),
                                  Color(0xFFFCE9D9),
                                ],
                              )
                            : null,
                        color: iconBg,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child:
                            TcIcon(icon, size: 54, color: iconColor ?? x.ink),
                      ),
                    ),
                const SizedBox(height: 18),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TcType.h2.copyWith(fontSize: 27, color: x.ink),
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TcType.sub.copyWith(color: x.muted),
                  ),
                ),
                if (showProgress) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(
                    color: TcColors.blue,
                    backgroundColor: TcColors.skeletonBase,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    minHeight: 8,
                  ),
                ],
                if (content != null) ...[
                  const SizedBox(height: 20),
                  content!,
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import '../../data/models.dart';
import '../initialization/system_screens.dart';

/// Screens 23 & 24 - Badges & Milestones and the Badge Earned overlay.

BadgeDef _defFor(String badgeId) =>
    kBadges.firstWhere((b) => b.id == badgeId, orElse: () => kBadges.first);

/// Screen 23 - Badges & Milestones.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<BadgeState> _states = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final states = await context.read<AppState>().badges.all();
    if (!mounted) return;
    setState(() {
      _states = states;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return TcShell(
      active: TcNavSection.home,
      onNavigate: (s) => navigateSection(context, s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TcTopbar(
          title: 'Badges & milestones',
          eyebrow: 'Little celebrations',
          leading: TcIconButton(
            icon: 'back',
            semanticLabel: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          showActions: false,
        ),
        if (_loading)
          const LoadingSkeletonState()
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: r.layout == FireLayout.compact ? 1 : 2,
            mainAxisSpacing: TcSpace.lg,
            crossAxisSpacing: TcSpace.lg,
            childAspectRatio: r.layout == FireLayout.compact ? 2.6 : 2.5,
            children: [
              for (final state in _states) _BadgeCard(state: state),
            ],
          ),
      ]),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.state});

  final BadgeState state;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final def = _defFor(state.badgeId);
    final earned = state.earned;
    return TcPanel(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: earned
                ? const LinearGradient(
                    colors: [TcColors.gold, Color(0xFFF7D98C)])
                : null,
            color: earned ? null : TcColors.skeletonBase,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: TcIcon(def.icon,
                size: 30, color: earned ? TcColors.ink : x.muted),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [
                Expanded(
                  child: Text(def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TcType.h3.copyWith(color: x.ink)),
                ),
                if (earned)
                  const TcBadge('Earned',
                      kind: TcBadgeKind.gold, icon: 'check')
                else
                  TcBadge('${state.progress}/${state.target}'),
              ]),
              const SizedBox(height: 6),
              Text(def.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TcType.rowSubtitle.copyWith(color: x.muted)),
              const SizedBox(height: 10),
              TcProgressBar(
                state.fraction,
                semanticLabel:
                    '${def.name}: ${state.progress} of ${state.target}',
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Screen 24 - Badge Earned overlay. Reduced-motion aware: the celebratory
/// scale animation is replaced by a static presentation when reduce-motion
/// is on.
Future<void> showBadgeEarnedOverlay(BuildContext context, BadgeDef def) {
  final reduced = TcThemeX.of(context).reduceMotion;
  return showTcModal<void>(
    context,
    _BadgeEarnedCard(def: def, animate: !reduced),
  );
}

class _BadgeEarnedCard extends StatefulWidget {
  const _BadgeEarnedCard({required this.def, required this.animate});

  final BadgeDef def;
  final bool animate;

  @override
  State<_BadgeEarnedCard> createState() => _BadgeEarnedCardState();
}

class _BadgeEarnedCardState extends State<_BadgeEarnedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TcModalCard(
      customVisual: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [TcColors.gold, Color(0xFFF7D98C)]),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: TcIcon(widget.def.icon, size: 48, color: TcColors.ink),
          ),
        ),
      ),
      title: 'You earned a badge!',
      body: '${widget.def.name} - ${widget.def.description}. '
          'Wonderful work, little artist!',
      actions: [
        TcButton(
          label: 'Hooray!',
          icon: 'star',
          childFacing: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    );
  }
}

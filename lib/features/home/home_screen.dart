import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/graphics/scene_painter.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import '../../data/models.dart';
import '../catalog/catalog_screens.dart';
import '../coloring/canvas_screen.dart';
import '../initialization/system_screens.dart';

/// Screen 5 - Home, with the approved variants: offline banner (Screen 41
/// behavior), low storage state, continue-coloring hero, fresh picks and
/// the badges strip. Fully responsive in portrait and landscape.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CatalogItem>? _items;
  Artwork? _latest;
  List<BadgeState>? _badges;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    await state.refreshConnectivity();
    final items = await state.catalog.all();
    final latest = await state.artworks.latest();
    final badges = await state.badges.all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _latest = latest;
      _badges = badges;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);
    final items = _items;

    return TcShell(
      active: TcNavSection.home,
      onNavigate: (section) => navigateSection(context, section),
      child: Padding(
        padding: r.mainPadding,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: TcTopbar(
              eyebrow: 'TinyCanvas Studio',
              title: 'Hello, little artist!',
              onSearch: () => Navigator.of(context).pushNamed(Routes.search),
              onParents: () =>
                  Navigator.of(context).pushNamed(Routes.parentZone),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (!state.isOnline)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: TcBanner(
                  icon: 'wifi',
                  boldText: 'You\u2019re offline.',
                  text:
                      'Coloring still works. Connect only to unlock or restore.',
                ),
              ),
            ),
          if (state.lowStorageWarning)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: LowStorageState(
                  onManage: () =>
                      Navigator.of(context).pushNamed(Routes.parentZone),
                ),
              ),
            ),
          SliverToBoxAdapter(child: _hero(state, r, x)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Row(children: [
              Expanded(
                  child: Text('Fresh picks',
                      style: TcType.h2.copyWith(color: x.ink))),
              TcButton(
                label: 'Explore all',
                kind: TcButtonKind.link,
                trailingIcon: 'forward',
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.explore),
              ),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (items == null)
            SliverGrid.count(
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 0.92,
              children: [
                for (var i = 0; i < 4; i++)
                  const TcSkeleton(height: 160, radius: 22),
              ],
            )
          else
            SliverGrid.count(
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 0.92,
              children: [
                for (final item in _freshPicks(items))
                  PictureCard(
                    item: item,
                    locked: isLocked(state, item),
                    onTap: () => openPreview(context, item),
                  ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Text('Categories', style: TcType.h2.copyWith(color: x.ink)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final category in kCategories)
                TcChip(category,
                    onTap: () => Navigator.of(context)
                        .pushNamed(Routes.category, arguments: category)),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _badgesStrip(x)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }

  /// Free items first so brand-new artists always land on something they
  /// can open, then a taste of premium.
  List<CatalogItem> _freshPicks(List<CatalogItem> items) {
    final free = items.where((i) => !i.premium).take(5).toList();
    final premium = items.where((i) => i.premium).take(3).toList();
    return [...free, ...premium].take(8).toList();
  }

  Widget _hero(AppState state, Responsive r, TcThemeX x) {
    final latest = _latest;
    final compact = r.layout == FireLayout.compact;
    final heroText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TcEyebrow(latest == null ? 'Welcome' : 'Continue coloring',
            color: const Color(0xCCFFFFFF)),
        const SizedBox(height: 8),
        Text(
          latest == null
              ? 'Pick your first picture!'
              : latest.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TcType.h1Hero.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          latest == null
              ? '120 pictures are waiting on the shelf - 20 are free to '
                  'start right now.'
              : 'Your art shelf saved every stroke. Jump right back in.',
          style: TcType.sub.copyWith(color: const Color(0xCCFFFFFF)),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [
          TcButton(
            label: latest == null ? 'Start coloring' : 'Keep coloring',
            icon: 'play',
            childFacing: true,
            onPressed: () {
              if (latest == null) {
                Navigator.of(context).pushNamed(Routes.explore);
              } else {
                Navigator.of(context).pushNamed(
                  Routes.canvas,
                  arguments: CanvasArgs(
                    catalogItemId: latest.catalogItemId,
                    artworkId: latest.id,
                  ),
                );
              }
            },
          ),
          TcButton(
            label: 'My art shelf',
            icon: 'art',
            kind: TcButtonKind.soft,
            childFacing: true,
            onPressed: () => Navigator.of(context).pushNamed(Routes.myArt),
          ),
        ]),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TcColors.heroStart, TcColors.heroMid, TcColors.heroEnd],
        ),
        borderRadius: BorderRadius.circular(TcRadius.panel),
        boxShadow: TcShadows.panel,
      ),
      padding: const EdgeInsets.all(26),
      child: compact
          ? heroText
          : Row(children: [
              Expanded(child: heroText),
              const SizedBox(width: 22),
              SizedBox(
                width: 250,
                height: 168,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TcRadius.small),
                  child: HeroArt(seed: 11),
                ),
              ),
            ]),
    );
  }

  Widget _badgesStrip(TcThemeX x) {
    final badges = _badges;
    return TcPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child:
                  Text('Badges', style: TcType.h2.copyWith(color: x.ink))),
          TcButton(
            label: 'See all',
            kind: TcButtonKind.link,
            trailingIcon: 'forward',
            onPressed: () => Navigator.of(context).pushNamed(Routes.badges),
          ),
        ]),
        const SizedBox(height: 12),
        if (badges == null)
          const TcSkeleton(height: 40)
        else
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final badge in badges)
              TcBadge(
                badge.earned
                    ? _badgeName(badge.badgeId)
                    : '${_badgeName(badge.badgeId)} \u2022 ${badge.progress}/${badge.target}',
                kind: badge.earned ? TcBadgeKind.gold : TcBadgeKind.normal,
                icon: badge.earned ? 'star' : 'spark',
              ),
          ]),
      ]),
    );
  }

  String _badgeName(String badgeId) =>
      kBadges.firstWhere((def) => def.id == badgeId).name;
}

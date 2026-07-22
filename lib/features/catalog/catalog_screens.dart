import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/graphics/scene_painter.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import '../../data/models.dart';

/// Screens 6-10: Explore, Category Results (with filters + sort), Search
/// (with recent searches). All grids adapt 2/3/4 columns and both
/// orientations per the approved responsive rules.

/// The approved picture card: storybook scene thumb, title, difficulty and
/// free/locked badges.
class PictureCard extends StatelessWidget {
  const PictureCard({
    super.key,
    required this.item,
    required this.locked,
    required this.onTap,
  });

  final CatalogItem item;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcCard(
      onTap: onTap,
      semanticLabel:
          '${item.title}, ${item.difficulty.label}, ${locked ? 'locked, unlock to color' : item.premium ? 'unlocked' : 'free'}',
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(fit: StackFit.expand, children: [
              SceneThumb(seed: item.assetSeed),
              if (locked)
                Container(
                  color: const Color(0x66111C34),
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: TcColors.paper,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                          child: TcIcon('lock',
                              size: 20, color: TcColors.navy)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TcType.rowTitle.copyWith(color: x.ink)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          TcBadge(item.difficulty.label),
          if (!item.premium)
            const TcBadge('Free', kind: TcBadgeKind.gold, icon: 'star')
          else if (locked)
            const TcBadge('Locked', kind: TcBadgeKind.coral, icon: 'lock'),
        ]),
      ]),
    );
  }
}

void openPreview(BuildContext context, CatalogItem item) {
  Navigator.of(context).pushNamed(Routes.preview, arguments: item.id);
}

bool isLocked(AppState state, CatalogItem item) =>
    item.premium && state.ownership != OwnershipState.owned;

// ---------------------------------------------------------------------------
// Screen 6 - Explore
// ---------------------------------------------------------------------------

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<CatalogItem>? _items;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().catalog.all().then((items) {
      if (mounted) setState(() => _items = items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);
    final items = _items;

    return TcShell(
      active: TcNavSection.explore,
      onNavigate: (section) => navigateSection(context, section),
      child: Padding(
        padding: r.mainPadding,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: TcTopbar(
              eyebrow: '120 original pictures',
              title: 'Explore pictures',
              onSearch: () => Navigator.of(context).pushNamed(Routes.search),
              onParents: () =>
                  Navigator.of(context).pushNamed(Routes.parentZone),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: Text('Categories', style: TcType.h2.copyWith(color: x.ink)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (items == null)
            SliverToBoxAdapter(
                child: Row(children: [
              for (var i = 0; i < 4; i++)
                const Expanded(
                    child: Padding(
                        padding: EdgeInsets.all(6),
                        child: TcSkeleton(height: 110, radius: 22))),
            ]))
          else
            SliverGrid.count(
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 1.35,
              children: [
                for (final (index, category) in kCategories.indexed)
                  _CategoryCard(
                    category: category,
                    seed: 20 + index,
                    freeCount: items
                        .where((i) => i.category == category && !i.premium)
                        .length,
                    onTap: () => Navigator.of(context)
                        .pushNamed(Routes.category, arguments: category),
                  ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child:
                Text('New & lovely', style: TcType.h2.copyWith(color: x.ink)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (items != null)
            SliverGrid.count(
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 0.92,
              children: [
                for (final item in items.take(8))
                  PictureCard(
                    item: item,
                    locked: isLocked(state, item),
                    onTap: () => openPreview(context, item),
                  ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.seed,
    required this.freeCount,
    required this.onTap,
  });

  final String category;
  final int seed;
  final int freeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcCard(
      onTap: onTap,
      semanticLabel: '$category category, 15 pictures, $freeCount free',
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SceneThumb(seed: seed),
          ),
        ),
        const SizedBox(height: 8),
        Text(category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TcType.rowTitle.copyWith(color: x.ink)),
        Text('15 pictures \u2022 $freeCount free',
            style: TcType.rowSubtitle.copyWith(color: x.muted)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 7/8 - Category results + filter & sort
// ---------------------------------------------------------------------------

enum _CatalogFilter { all, free, beginner, explorer, creator }

enum _CatalogSort { curated, alphabetical, freeFirst }

class CategoryResultsScreen extends StatefulWidget {
  const CategoryResultsScreen({super.key, required this.category});

  final String category;

  @override
  State<CategoryResultsScreen> createState() => _CategoryResultsScreenState();
}

class _CategoryResultsScreenState extends State<CategoryResultsScreen> {
  List<CatalogItem>? _items;
  _CatalogFilter _filter = _CatalogFilter.all;
  _CatalogSort _sort = _CatalogSort.curated;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().catalog.byCategory(widget.category).then((items) {
      if (mounted) setState(() => _items = items);
    });
  }

  List<CatalogItem> get _visible {
    var items = List<CatalogItem>.of(_items ?? const []);
    items = switch (_filter) {
      _CatalogFilter.all => items,
      _CatalogFilter.free => items.where((i) => !i.premium).toList(),
      _CatalogFilter.beginner =>
        items.where((i) => i.difficulty == Difficulty.beginner).toList(),
      _CatalogFilter.explorer =>
        items.where((i) => i.difficulty == Difficulty.explorer).toList(),
      _CatalogFilter.creator =>
        items.where((i) => i.difficulty == Difficulty.creator).toList(),
    };
    switch (_sort) {
      case _CatalogSort.alphabetical:
        items.sort((a, b) => a.title.compareTo(b.title));
      case _CatalogSort.freeFirst:
        items.sort((a, b) => (a.premium ? 1 : 0) - (b.premium ? 1 : 0));
      case _CatalogSort.curated:
        break;
    }
    return items;
  }

  Future<void> _openSort() async {
    final picked = await showTcModal<_CatalogSort>(
      context,
      Builder(builder: (context) {
        return TcModalCard(
          icon: 'grid',
          title: 'Sort pictures',
          body: 'Choose how this shelf is arranged.',
          actions: [
            for (final (sort, label) in const [
              (_CatalogSort.curated, 'Curated order'),
              (_CatalogSort.alphabetical, 'A to Z'),
              (_CatalogSort.freeFirst, 'Free first'),
            ])
              TcButton(
                label: label,
                kind: TcButtonKind.soft,
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(sort),
              ),
          ],
        );
      }),
    );
    if (picked != null && mounted) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);
    final items = _items;
    final visible = _visible;
    final freeCount =
        (items ?? const <CatalogItem>[]).where((i) => !i.premium).length;

    return TcShell(
      active: TcNavSection.explore,
      onNavigate: (section) => navigateSection(context, section),
      child: Padding(
        padding: r.mainPadding,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: TcTopbar(
              eyebrow: items == null
                  ? 'Loading\u2026'
                  : '15 pictures \u2022 $freeCount free',
              title: widget.category,
              leading: TcIconButton(
                  icon: 'back',
                  semanticLabel: 'Back',
                  onPressed: () => Navigator.of(context).maybePop()),
              onSearch: () => Navigator.of(context).pushNamed(Routes.search),
              onParents: () =>
                  Navigator.of(context).pushNamed(Routes.parentZone),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (filter, label) in const [
                (_CatalogFilter.all, 'All'),
                (_CatalogFilter.free, 'Free'),
                (_CatalogFilter.beginner, 'Beginner'),
                (_CatalogFilter.explorer, 'Explorer'),
                (_CatalogFilter.creator, 'Creator'),
              ])
                TcChip(label,
                    active: _filter == filter,
                    onTap: () => setState(() => _filter = filter)),
              TcChip('Sort', icon: 'grid', onTap: _openSort),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (items == null)
            SliverGrid.count(
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 0.92,
              children: [
                for (var i = 0; i < 8; i++)
                  const TcSkeleton(height: 160, radius: 22),
              ],
            )
          else if (visible.isEmpty)
            SliverToBoxAdapter(
              child: TcPanel(
                child: Column(children: [
                  Text('No pictures match this filter',
                      style: TcType.h3.copyWith(color: x.ink)),
                  const SizedBox(height: 6),
                  Text('Try another difficulty, or show all pictures.',
                      style: TcType.rowSubtitle.copyWith(color: x.muted)),
                  const SizedBox(height: 12),
                  TcButton(
                      label: 'Show all',
                      kind: TcButtonKind.soft,
                      childFacing: true,
                      onPressed: () =>
                          setState(() => _filter = _CatalogFilter.all)),
                ]),
              ),
            )
          else
            SliverGrid.count(
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 0.92,
              children: [
                for (final item in visible)
                  PictureCard(
                    item: item,
                    locked: isLocked(state, item),
                    onTap: () => openPreview(context, item),
                  ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screens 9/10 - Search + results/empty + recent searches
// ---------------------------------------------------------------------------

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<CatalogItem> _results = const [];
  List<String> _recent = const [];
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await context.read<AppState>().recentSearches.recent();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _search(String query) async {
    final state = context.read<AppState>();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    final results = await state.catalog.search(trimmed);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  Future<void> _submit(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await context.read<AppState>().recentSearches.record(trimmed);
    await _search(trimmed);
    await _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);

    return TcShell(
      active: TcNavSection.explore,
      onNavigate: (section) => navigateSection(context, section),
      child: Padding(
        padding: r.mainPadding,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: TcTopbar(
              eyebrow: 'Find a picture',
              title: 'Search',
              showActions: false,
              leading: TcIconButton(
                  icon: 'back',
                  semanticLabel: 'Back',
                  onPressed: () => Navigator.of(context).maybePop()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: TcSearchField(
              controller: _controller,
              hint: 'Try \u201crocket\u201d, \u201ckitten\u201d or \u201cbeach\u201d',
              autofocus: true,
              onChanged: _search,
              onClear: () {
                _controller.clear();
                _search('');
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (!_searched) ...[
            if (_recent.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Row(children: [
                  Expanded(
                      child: Text('Recent searches',
                          style: TcType.h3.copyWith(color: x.ink))),
                  TcButton(
                    label: 'Clear',
                    kind: TcButtonKind.link,
                    onPressed: () async {
                      await context.read<AppState>().recentSearches.clear();
                      await _loadRecent();
                    },
                  ),
                ]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final term in _recent)
                    TcChip(term, icon: 'search', onTap: () {
                      _controller.text = term;
                      _submit(term);
                    }),
                ]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ],
            SliverToBoxAdapter(
              child: Text('Browse a category instead',
                  style: TcType.h3.copyWith(color: x.ink)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final category in kCategories)
                  TcChip(category,
                      onTap: () => Navigator.of(context)
                          .pushNamed(Routes.category, arguments: category)),
              ]),
            ),
          ] else if (_results.isEmpty)
            SliverToBoxAdapter(
              child: TcPanel(
                child: Column(children: [
                  Text('No matches yet', style: TcType.h3.copyWith(color: x.ink)),
                  const SizedBox(height: 6),
                  Text(
                      'Try a shorter word, or explore a category below.',
                      textAlign: TextAlign.center,
                      style: TcType.rowSubtitle.copyWith(color: x.muted)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final category in kCategories.take(4))
                      TcChip(category,
                          onTap: () => Navigator.of(context).pushNamed(
                              Routes.category,
                              arguments: category)),
                  ]),
                ]),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Text(
                  '${_results.length} ${_results.length == 1 ? 'picture' : 'pictures'} found',
                  style: TcType.h3.copyWith(color: x.ink)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverGrid.count(
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 0.92,
              children: [
                for (final item in _results)
                  PictureCard(
                    item: item,
                    locked: isLocked(state, item),
                    onTap: () => openPreview(context, item),
                  ),
              ],
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }
}

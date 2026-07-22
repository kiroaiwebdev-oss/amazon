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
import '../adult_gate/adult_gate_dialog.dart';
import '../coloring/canvas_screen.dart';

/// Screen 11 - Page Preview with its approved variants: free, locked
/// (premium without unlock) and existing-draft (continue or start fresh).
/// Split layout (1.15fr / 0.85fr) that stacks when compact, per the source.
class PagePreviewScreen extends StatefulWidget {
  const PagePreviewScreen({super.key, required this.catalogItemId});

  final String catalogItemId;

  @override
  State<PagePreviewScreen> createState() => _PagePreviewScreenState();
}

class _PagePreviewScreenState extends State<PagePreviewScreen> {
  CatalogItem? _item;
  Artwork? _draft;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final item = await state.catalog.byId(widget.catalogItemId);
    final draft = item == null
        ? null
        : await state.artworks.latestForCatalogItem(item.id);
    if (!mounted) return;
    setState(() {
      _item = item;
      _draft = draft;
      _loading = false;
    });
  }

  void _startColoring({String? artworkId}) {
    Navigator.of(context).pushNamed(
      Routes.canvas,
      arguments:
          CanvasArgs(catalogItemId: _item!.id, artworkId: artworkId),
    );
  }

  /// Purchases sit behind the adult gate.
  Future<void> _goUnlock() async {
    final passed = await showAdultGate(context,
        reason: 'Unlocking pictures is a grown-up job.');
    if (passed && mounted) {
      Navigator.of(context).pushNamed(Routes.paywall);
    }
  }

  String get _difficultyBlurb => switch (_item!.difficulty) {
        Difficulty.beginner =>
          'Big friendly shapes - perfect for little hands.',
        Difficulty.explorer =>
          'A comfy mix of shapes with a few fun details.',
        Difficulty.creator =>
          'Lots of lovely details for confident little artists.',
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final r = Responsive.of(context);

    return TcShell(
      active: TcNavSection.explore,
      onNavigate: (section) => navigateSection(context, section),
      child: Padding(
        padding: r.mainPadding,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _item == null
                ? _MissingItem(
                    onBack: () => Navigator.of(context).maybePop())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TcTopbar(
                          eyebrow: _item!.category,
                          title: 'Picture preview',
                          leading: TcIconButton(
                              icon: 'back',
                              semanticLabel: 'Back',
                              onPressed: () =>
                                  Navigator.of(context).maybePop()),
                          onSearch: () => Navigator.of(context)
                              .pushNamed(Routes.search),
                          onParents: () => Navigator.of(context)
                              .pushNamed(Routes.parentZone),
                        ),
                        const SizedBox(height: 18),
                        if (r.splitCollapses)
                          Column(children: [
                            _paper(),
                            const SizedBox(height: 18),
                            _details(state),
                          ])
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 115, child: _paper()),
                              const SizedBox(width: TcSpace.lg),
                              Expanded(flex: 85, child: _details(state)),
                            ],
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _paper() {
    return Container(
      decoration: BoxDecoration(
        color: TcColors.artBoardBg,
        borderRadius: BorderRadius.circular(TcRadius.panel),
      ),
      padding: const EdgeInsets.all(18),
      child: AspectRatio(
        aspectRatio: 1.18,
        child: Semantics(
          label: '${_item!.title} line art preview',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SceneThumb(seed: _item!.assetSeed, line: true),
          ),
        ),
      ),
    );
  }

  Widget _details(AppState state) {
    final x = TcThemeX.of(context);
    final locked =
        _item!.premium && state.ownership != OwnershipState.owned;
    final draft = _draft;

    return TcPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TcEyebrow(_item!.category),
          const SizedBox(height: 6),
          Text(_item!.title, style: TcType.h1.copyWith(color: x.ink)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            TcBadge(_item!.difficulty.label, icon: 'brush'),
            if (!_item!.premium)
              const TcBadge('Free', kind: TcBadgeKind.gold, icon: 'star')
            else if (locked)
              const TcBadge('Locked', kind: TcBadgeKind.coral, icon: 'lock')
            else
              const TcBadge('Unlocked', kind: TcBadgeKind.gold, icon: 'check'),
            if (draft != null) const TcBadge('In progress', icon: 'edit'),
          ]),
          const SizedBox(height: 12),
          Text(_difficultyBlurb,
              style: TcType.sub.copyWith(color: x.muted)),
          const SizedBox(height: 18),
          if (locked) ...[
            Text(
              'This picture is part of the one-time unlock. One purchase '
              'opens all 100 premium pictures - no subscriptions, no ads.',
              style: TcType.rowSubtitle.copyWith(color: x.muted),
            ),
            const SizedBox(height: 14),
            TcButton(
              label: 'Unlock all pictures',
              icon: 'lock',
              kind: TcButtonKind.coral,
              expand: true,
              semanticHint: 'Opens the grown-up gate before checkout',
              onPressed: _goUnlock,
            ),
            const SizedBox(height: 10),
            TcButton(
              label: 'Back to explore',
              kind: TcButtonKind.soft,
              expand: true,
              childFacing: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ] else if (draft != null) ...[
            TcButton(
              label: 'Continue coloring',
              icon: 'play',
              expand: true,
              childFacing: true,
              onPressed: () => _startColoring(artworkId: draft.id),
            ),
            const SizedBox(height: 10),
            TcButton(
              label: 'Start a fresh copy',
              icon: 'plus',
              kind: TcButtonKind.soft,
              expand: true,
              childFacing: true,
              onPressed: () => _startColoring(),
            ),
          ] else
            TcButton(
              label: 'Start coloring',
              icon: 'play',
              expand: true,
              childFacing: true,
              onPressed: () => _startColoring(),
            ),
        ],
      ),
    );
  }
}

class _MissingItem extends StatelessWidget {
  const _MissingItem({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Center(
      child: TcPanel(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('This picture wandered off',
              style: TcType.h2.copyWith(color: x.ink)),
          const SizedBox(height: 8),
          Text('Head back to Explore to pick another one.',
              style: TcType.rowSubtitle.copyWith(color: x.muted)),
          const SizedBox(height: 14),
          TcButton(label: 'Back to explore', childFacing: true, onPressed: onBack),
        ]),
      ),
    );
  }
}

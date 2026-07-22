import 'dart:async';

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
import '../adult_gate/adult_gate_dialog.dart';
import '../coloring/canvas_screen.dart';
import '../export/export_flow.dart';
import '../initialization/system_screens.dart';

/// Screens 18-21: My Art Library, Artwork Detail, Rename dialog, Delete
/// dialog (with the required 5-second undo window).

enum ArtSort { newest, oldest, name }

/// Screen 18 - My Art Library.
class MyArtScreen extends StatefulWidget {
  const MyArtScreen({super.key});

  @override
  State<MyArtScreen> createState() => _MyArtScreenState();
}

class _MyArtScreenState extends State<MyArtScreen> {
  List<Artwork> _artworks = const [];
  Map<String, CatalogItem> _items = const {};
  bool _loading = true;
  bool _favoritesOnly = false;
  ArtSort _sort = ArtSort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final artworks = await state.artworks.all();
    final catalog = await state.catalog.all();
    if (!mounted) return;
    setState(() {
      _artworks = artworks;
      _items = {for (final i in catalog) i.id: i};
      _loading = false;
    });
  }

  List<Artwork> get _visible {
    var out = _favoritesOnly
        ? _artworks.where((a) => a.favorite).toList()
        : List.of(_artworks);
    switch (_sort) {
      case ArtSort.newest:
        out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case ArtSort.oldest:
        out.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case ArtSort.name:
        out.sort((a, b) => a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase()));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);
    final visible = _visible;

    return TcShell(
      active: TcNavSection.art,
      onNavigate: (s) => navigateSection(context, s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TcTopbar(
            title: 'My Art shelf',
            eyebrow:
                '${_artworks.length} ${_artworks.length == 1 ? 'creation' : 'creations'}',
            onSearch: () => Navigator.of(context).pushNamed(Routes.search),
            onParents: () =>
                Navigator.of(context).pushNamed(Routes.parentZone),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            TcChip('All',
                active: !_favoritesOnly,
                onTap: () => setState(() => _favoritesOnly = false)),
            TcChip('Favorites',
                icon: 'heart',
                active: _favoritesOnly,
                onTap: () => setState(() => _favoritesOnly = true)),
            TcChip('Newest first',
                active: _sort == ArtSort.newest,
                onTap: () => setState(() => _sort = ArtSort.newest)),
            TcChip('Oldest first',
                active: _sort == ArtSort.oldest,
                onTap: () => setState(() => _sort = ArtSort.oldest)),
            TcChip('A to Z',
                active: _sort == ArtSort.name,
                onTap: () => setState(() => _sort = ArtSort.name)),
          ]),
          const SizedBox(height: 20),
          if (_loading)
            const LoadingSkeletonState()
          else if (visible.isEmpty && _favoritesOnly)
            TcPanel(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Text('No favorites yet.',
                    style: TcType.h3.copyWith(color: x.ink)),
                const SizedBox(height: 6),
                Text('Tap the heart on any artwork to keep it here.',
                    style: TcType.sub.copyWith(color: x.muted)),
              ]),
            )
          else if (visible.isEmpty)
            EmptyState(
                onAction: () =>
                    Navigator.of(context).pushNamed(Routes.explore))
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: r.gridColumns(),
              mainAxisSpacing: TcSpace.lg,
              crossAxisSpacing: TcSpace.lg,
              childAspectRatio: 1.05,
              children: [
                for (final art in visible)
                  _ArtworkCard(
                    artwork: art,
                    item: _items[art.catalogItemId],
                    onTap: () => Navigator.of(context)
                        .pushNamed(Routes.artworkDetail, arguments: art.id)
                        .then((_) => _load()),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.artwork,
    required this.item,
    required this.onTap,
  });

  final Artwork artwork;
  final CatalogItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcCard(
      onTap: onTap,
      semanticLabel:
          '${artwork.displayName}${artwork.favorite ? ', favorite' : ''}'
          '${artwork.completed ? ', finished' : ', in progress'}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TcRadius.small),
            child: Stack(fit: StackFit.expand, children: [
              // Thumbnail: procedural scene render for the source page;
              // regenerated preview files are used when present.
              SceneThumb(seed: item?.assetSeed ?? 1),
              if (artwork.favorite)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: TcBadge('Fav', kind: TcBadgeKind.coral, icon: 'heart'),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(artwork.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TcType.rowTitle.copyWith(color: x.ink)),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Wrap(spacing: 6, children: [
            TcBadge(artwork.completed ? 'Finished' : 'In progress',
                kind:
                    artwork.completed ? TcBadgeKind.gold : TcBadgeKind.normal),
            if (item != null) TcBadge(item!.category),
          ]),
        ),
      ]),
    );
  }
}

/// Screen 19 - Artwork Detail (+ rename 20, delete 21, export 22 entry).
class ArtworkDetailScreen extends StatefulWidget {
  const ArtworkDetailScreen({super.key, required this.artworkId});

  final String artworkId;

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  Artwork? _artwork;
  CatalogItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final artwork = await state.artworks.byId(widget.artworkId);
    final item = artwork == null
        ? null
        : await state.catalog.byId(artwork.catalogItemId);
    if (!mounted) return;
    setState(() {
      _artwork = artwork;
      _item = item;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final state = context.read<AppState>();
    await state.artworks.setFavorite(_artwork!.id, !_artwork!.favorite);
    await _load();
  }

  Future<void> _duplicate() async {
    final state = context.read<AppState>();
    final src = _artwork!;
    final id = 'art_${DateTime.now().millisecondsSinceEpoch}';
    final copyName = sanitizeArtworkName('${src.displayName} copy');
    final raw = await state.documentStore.load(src.documentPath);
    final newPath = state.documentPathFor(id);
    if (raw != null) {
      await state.documentStore.save(newPath, raw);
    }
    await state.artworks.upsert(Artwork(
      id: id,
      catalogItemId: src.catalogItemId,
      displayName: copyName.isEmpty ? 'My picture copy' : copyName,
      documentPath: newPath,
      previewPath: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      favorite: false,
      completed: src.completed,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Made a copy on your art shelf.')),
    );
    Navigator.of(context).maybePop();
  }

  Future<void> _rename() async {
    final newName =
        await showRenameArtworkDialog(context, _artwork!.displayName);
    if (newName == null) return;
    final state = context.read<AppState>();
    await state.artworks.rename(_artwork!.id, newName);
    await _load();
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    final confirmed = await showDeleteArtworkDialog(context);
    if (!confirmed || !mounted) return;
    final deleted = await state.artworks.delete(_artwork!.id);
    if (!mounted || deleted == null) return;

    // 5-second undo window per approved microcopy. The document file is
    // only removed after the window closes without an undo.
    var undone = false;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: TcDurations.deleteUndoWindow,
        content: const Text('Artwork deleted.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            undone = true;
            await state.artworks.restore(deleted);
          },
        ),
      ),
    );
    Navigator.of(context).maybePop();
    final path = deleted.documentPath;
    unawaited(Future<void>.delayed(TcDurations.deleteUndoWindow).then((_) {
      if (!undone && path.isNotEmpty) {
        state.documentStore.delete(path);
      }
    }));
  }

  Future<void> _export() async {
    final unlocked = await showAdultGate(context,
        reason: 'Saving to the photo gallery is a grown-up job.');
    if (unlocked && mounted) {
      await runExportFlow(context, artwork: _artwork!, item: _item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);

    if (_loading || _artwork == null) {
      return TcShell(
        active: TcNavSection.art,
        onNavigate: (s) => navigateSection(context, s),
        child: _loading
            ? const LoadingSkeletonState()
            : ErrorState(onRetry: _load),
      );
    }

    final artwork = _artwork!;
    final paper = TcPanel(
      padding: const EdgeInsets.all(18),
      color: TcColors.artBoardBg,
      child: AspectRatio(
        aspectRatio: 1.18,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: TcShadows.paper,
          ),
          clipBehavior: Clip.antiAlias,
          child: SceneThumb(seed: _item?.assetSeed ?? 1),
        ),
      ),
    );

    final details =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TcEyebrow(_item?.category ?? 'My Art'),
      const SizedBox(height: 8),
      Text(artwork.displayName, style: TcType.h1.copyWith(color: x.ink)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        TcBadge(artwork.completed ? 'Finished' : 'In progress',
            kind: artwork.completed ? TcBadgeKind.gold : TcBadgeKind.normal),
        if (artwork.favorite)
          const TcBadge('Favorite', kind: TcBadgeKind.coral, icon: 'heart'),
      ]),
      const SizedBox(height: 16),
      Text('Last colored ${_friendlyDate(artwork.updatedAt)}',
          style: TcType.sub.copyWith(color: x.muted)),
      const SizedBox(height: 22),
      Wrap(spacing: 12, runSpacing: 12, children: [
        TcButton(
          label: 'Keep coloring',
          icon: 'play',
          childFacing: true,
          onPressed: () => Navigator.of(context)
              .pushNamed(Routes.canvas,
                  arguments: CanvasArgs(
                      catalogItemId: artwork.catalogItemId,
                      artworkId: artwork.id))
              .then((_) => _load()),
        ),
        TcButton(
          label: artwork.favorite ? 'Un-favorite' : 'Favorite',
          icon: 'heart',
          kind: TcButtonKind.soft,
          childFacing: true,
          onPressed: _toggleFavorite,
        ),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        TcButton(
            label: 'Rename',
            icon: 'edit',
            kind: TcButtonKind.soft,
            onPressed: _rename),
        TcButton(
            label: 'Duplicate',
            icon: 'plus',
            kind: TcButtonKind.soft,
            onPressed: _duplicate),
        TcButton(
            label: 'Save to gallery',
            icon: 'download',
            kind: TcButtonKind.soft,
            onPressed: _export),
        TcButton(
            label: 'Delete',
            icon: 'trash',
            kind: TcButtonKind.danger,
            onPressed: _delete),
      ]),
    ]);

    return TcShell(
      active: TcNavSection.art,
      onNavigate: (s) => navigateSection(context, s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TcTopbar(
          title: 'Artwork',
          eyebrow: 'My Art shelf',
          leading: TcIconButton(
            icon: 'back',
            semanticLabel: 'Back to My Art',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          showActions: false,
        ),
        if (r.splitCollapses)
          Column(children: [paper, const SizedBox(height: 22), details])
        else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 115, child: paper),
            const SizedBox(width: 22),
            Expanded(flex: 85, child: details),
          ]),
      ]),
    );
  }

  static String _friendlyDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}

/// Screen 20 - Rename Artwork dialog (1-40 chars, live counter).
Future<String?> showRenameArtworkDialog(
    BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);
  return showTcModal<String>(
    context,
    StatefulBuilder(builder: (context, setState) {
      final sanitized = sanitizeArtworkName(controller.text);
      final valid = isValidArtworkName(sanitized);
      return TcModalCard(
        icon: 'edit',
        title: 'Rename this artwork',
        body: 'Choose a friendly name between 1 and 40 characters.',
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            counterText: '${controller.text.characters.length}/40',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TcRadius.small),
              borderSide: const BorderSide(color: TcColors.line),
            ),
          ),
        ),
        actions: [
          TcButton(
            label: 'Save name',
            icon: 'check',
            onPressed: valid
                ? () =>
                    Navigator.of(context, rootNavigator: true).pop(sanitized)
                : null,
          ),
          TcButton(
            label: 'Cancel',
            kind: TcButtonKind.soft,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      );
    }),
  );
}

/// Screen 21 - Delete Artwork dialog.
Future<bool> showDeleteArtworkDialog(BuildContext context) async {
  final result = await showTcModal<bool>(
    context,
    Builder(builder: (context) {
      return TcModalCard(
        icon: 'trash',
        iconBg: TcColors.dangerBg,
        iconColor: TcColors.dangerText,
        title: 'Delete this artwork?',
        body: 'The colored picture will be removed from your art shelf. '
            'You\u2019ll have five seconds to undo. The original coloring '
            'page stays in the studio.',
        actions: [
          TcButton(
            label: 'Delete artwork',
            kind: TcButtonKind.danger,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
          ),
          TcButton(
            label: 'Keep it',
            kind: TcButtonKind.soft,
            childFacing: true,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
          ),
        ],
      );
    }),
  );
  return result ?? false;
}

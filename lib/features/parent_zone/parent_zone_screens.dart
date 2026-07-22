import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/platform/platform_services.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

/// Screens 32-34: Parent Zone, Sound & Motion, Storage & Erase Data.
/// The Parent Zone route is guarded by the Adult Gate (see app_router).
class ParentZoneScreen extends StatelessWidget {
  const ParentZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final x = TcThemeX.of(context);
    final owned = state.ownership == OwnershipState.owned;

    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    TcIconButton(
                      icon: 'back',
                      semanticLabel: 'Return to child mode',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TcEyebrow('Grown-ups only'),
                          Text('Parent Zone',
                              style: TcType.h1.copyWith(color: x.ink)),
                        ],
                      ),
                    ),
                    const TcIcon('shield', size: 26, color: TcColors.blue),
                  ]),
                  const SizedBox(height: 22),

                  // Unlock status + purchase / restore.
                  TcPanel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text('Studio unlock',
                                style: TcType.h3.copyWith(color: x.ink)),
                          ),
                          if (owned)
                            const TcBadge('Unlocked',
                                kind: TcBadgeKind.gold, icon: 'check')
                          else if (state.ownership == OwnershipState.pending)
                            const TcBadge('Pending', kind: TcBadgeKind.gold)
                          else
                            const TcBadge('20 free of 120'),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          owned
                              ? 'All 120 pictures are unlocked on this Amazon '
                                  'account.'
                              : 'The 20 free pictures are always available. One '
                                  'purchase unlocks the other 100.',
                          style: TcType.rowSubtitle.copyWith(color: x.muted),
                        ),
                        const SizedBox(height: 16),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          if (!owned)
                            TcButton(
                              label: 'Unlock all pictures',
                              icon: 'lock',
                              kind: TcButtonKind.coral,
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(Routes.paywall),
                            ),
                          TcButton(
                            label: 'Restore purchase',
                            icon: 'undo',
                            kind: TcButtonKind.soft,
                            onPressed: () => Navigator.of(context)
                                .pushNamed(Routes.restore),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Settings rows.
                  TcPanel(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      TcRowTile(
                        icon: 'sound',
                        title: 'Sound & motion',
                        subtitle:
                            'Sound mode, voice hints, music, reduced motion, '
                            'high contrast',
                        onTap: () => Navigator.of(context)
                            .pushNamed(Routes.soundMotion),
                      ),
                      TcRowTile(
                        icon: 'download',
                        title: 'Storage & erase data',
                        subtitle:
                            'See space used, clear thumbnails, erase creations',
                        onTap: () => Navigator.of(context)
                            .pushNamed(Routes.storageErase),
                      ),
                      TcRowTile(
                        icon: 'shield',
                        title: 'Privacy Policy',
                        subtitle: 'What stays on the tablet (everything)',
                        onTap: () =>
                            Navigator.of(context).pushNamed(Routes.privacy),
                      ),
                      TcRowTile(
                        icon: 'book',
                        title: 'Terms of Use',
                        subtitle: 'The friendly fine print',
                        onTap: () =>
                            Navigator.of(context).pushNamed(Routes.terms),
                      ),
                      TcRowTile(
                        icon: 'info',
                        title: 'About, help & licenses',
                        subtitle: 'Version, support, open-source licenses',
                        onTap: () =>
                            Navigator.of(context).pushNamed(Routes.about),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  TcButton(
                    label: 'Return to child mode',
                    icon: 'play',
                    childFacing: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 33 - Sound & Motion.
class SoundMotionScreen extends StatelessWidget {
  const SoundMotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings;
    final x = TcThemeX.of(context);

    Future<void> update(AppSettings next) => state.updateSettings(next);

    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    TcIconButton(
                      icon: 'back',
                      semanticLabel: 'Back to Parent Zone',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TcEyebrow('Parent Zone'),
                          Text('Sound & motion',
                              style: TcType.h1.copyWith(color: x.ink)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  Text('SOUND MODE', style: TcType.eyebrow),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final mode in SoundMode.values)
                      TcChip(
                        switch (mode) {
                          SoundMode.playful => 'Playful',
                          SoundMode.quiet => 'Quiet',
                          SoundMode.silent => 'Silent',
                        },
                        active: s.soundMode == mode,
                        onTap: () => update(s.copyWith(
                          soundMode: mode,
                          soundEffectsEnabled: mode != SoundMode.silent,
                          musicEnabled: mode == SoundMode.playful,
                          voiceEnabled: mode == SoundMode.playful,
                        )),
                      ),
                  ]),
                  const SizedBox(height: 20),
                  TcPanel(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      TcRowTile(
                        icon: 'sound',
                        title: 'Voice hints',
                        subtitle: 'A friendly voice explains tools',
                        switchValue: s.voiceEnabled,
                        onSwitchChanged: (v) =>
                            update(s.copyWith(voiceEnabled: v)),
                      ),
                      TcRowTile(
                        icon: 'spark',
                        title: 'Sound effects',
                        subtitle: 'Gentle pops and chimes while coloring',
                        switchValue: s.soundEffectsEnabled,
                        onSwitchChanged: (v) =>
                            update(s.copyWith(soundEffectsEnabled: v)),
                      ),
                      TcRowTile(
                        icon: 'sound',
                        title: 'Background music',
                        subtitle: 'Soft storybook melodies',
                        switchValue: s.musicEnabled,
                        onSwitchChanged: (v) =>
                            update(s.copyWith(musicEnabled: v)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text('MOTION & CONTRAST', style: TcType.eyebrow),
                  const SizedBox(height: 10),
                  TcPanel(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      TcRowTile(
                        icon: 'play',
                        title: 'Reduce motion',
                        subtitle:
                            'Calms animations and celebrations everywhere',
                        switchValue: s.reducedMotion,
                        onSwitchChanged: (v) =>
                            update(s.copyWith(reducedMotion: v)),
                      ),
                      TcRowTile(
                        icon: 'info',
                        title: 'High contrast',
                        subtitle: 'Stronger text and outline colors',
                        switchValue: s.highContrast,
                        onSwitchChanged: (v) =>
                            update(s.copyWith(highContrast: v)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 34 - Storage & Erase Data (with the 5-second erase hold).
class StorageEraseScreen extends StatefulWidget {
  const StorageEraseScreen({super.key});

  @override
  State<StorageEraseScreen> createState() => _StorageEraseScreenState();
}

class _StorageEraseScreenState extends State<StorageEraseScreen> {
  StorageSummary? _summary;
  int _artworkCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final summary = await state.mediaExport.storageSummary(
        documentsDir: state.documentsDir);
    final count = await state.artworks.count();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _artworkCount = count;
      _loading = false;
    });
  }

  Future<void> _clearThumbnails() async {
    final state = context.read<AppState>();
    await state.mediaExport.clearThumbnailCache(
        documentsDir: state.documentsDir);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thumbnail cache cleared. Previews will be redrawn.')));
    await _load();
  }

  Future<void> _eraseAll() async {
    final confirmed = await showTcModal<bool>(
      context,
      _EraseHoldCard(artworkCount: _artworkCount),
      dismissible: false,
    );
    if (confirmed != true || !mounted) return;
    final state = context.read<AppState>();
    await eraseLocalCreations(state.db);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'All local creations were erased. The coloring pages and any '
            'Amazon purchase are untouched.')));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final summary = _summary;
    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    TcIconButton(
                      icon: 'back',
                      semanticLabel: 'Back to Parent Zone',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TcEyebrow('Parent Zone'),
                          Text('Storage & erase data',
                              style: TcType.h1.copyWith(color: x.ink)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  if (_loading || summary == null)
                    const Center(
                        child: CircularProgressIndicator(
                            color: TcColors.blue))
                  else ...[
                    TcPanel(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Space on this tablet',
                              style: TcType.h3.copyWith(color: x.ink)),
                          const SizedBox(height: 16),
                          Wrap(spacing: 22, runSpacing: 14, children: [
                            TcMetric(
                                value: formatBytes(summary.appBytes),
                                label: 'used by TinyCanvas'),
                            TcMetric(
                                value: formatBytes(summary.artworkBytes),
                                label:
                                    '$_artworkCount saved creation${_artworkCount == 1 ? '' : 's'}'),
                            TcMetric(
                                value: formatBytes(summary.freeBytes),
                                label: 'free on tablet'),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TcPanel(
                      padding: const EdgeInsets.all(10),
                      child: Column(children: [
                        TcRowTile(
                          icon: 'undo',
                          title: 'Clear thumbnail cache',
                          subtitle:
                              'Frees space; previews are redrawn as needed',
                          onTap: _clearThumbnails,
                        ),
                        TcRowTile(
                          icon: 'trash',
                          title: 'Erase all local creations',
                          subtitle:
                              'Removes saved artwork, progress, and badges '
                              'from this tablet only',
                          iconColor: TcColors.coral,
                          onTap: _eraseAll,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Erasing never touches an Amazon purchase. An unlock '
                      'can always be restored with the same Amazon account.',
                      style: TcType.rowSubtitle.copyWith(color: x.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The deliberate five-second erase hold dialog.
class _EraseHoldCard extends StatefulWidget {
  const _EraseHoldCard({required this.artworkCount});

  final int artworkCount;

  @override
  State<_EraseHoldCard> createState() => _EraseHoldCardState();
}

class _EraseHoldCardState extends State<_EraseHoldCard> {
  Timer? _timer;
  double _progress = 0;

  void _startHold() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        _progress += 50 / TcDurations.eraseHold.inMilliseconds;
        if (_progress >= 1) {
          t.cancel();
          Navigator.of(context, rootNavigator: true).pop(true);
        }
      });
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    setState(() => _progress = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TcModalCard(
      icon: 'trash',
      iconBg: TcColors.dangerBg,
      iconColor: TcColors.dangerText,
      title: 'Erase all local creations?',
      body: 'This removes ${widget.artworkCount} saved '
          'creation${widget.artworkCount == 1 ? '' : 's'}, coloring progress, '
          'and badges from this tablet. The 120 coloring pages stay, and any '
          'Amazon purchase is never erased. This cannot be undone.',
      content: Column(children: [
        Semantics(
          button: true,
          label: 'Hold to erase everything. Keep holding for five seconds.',
          child: GestureDetector(
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: TcColors.dangerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TcColors.dangerText, width: 2),
              ),
              child: Stack(children: [
                FractionallySizedBox(
                  widthFactor: _progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: TcColors.dangerText.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    _progress > 0
                        ? 'Keep holding\u2026 ${(5 - _progress * 5).ceil()}'
                        : 'Press and hold for 5 seconds to erase',
                    style: TcType.rowTitle
                        .copyWith(color: TcColors.dangerText),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
      actions: [
        TcButton(
          label: 'Cancel - keep everything',
          kind: TcButtonKind.soft,
          childFacing: true,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
      ],
    );
  }
}

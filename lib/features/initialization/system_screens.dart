import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_widgets.dart';

/// Screens 1, 2, 39, 40, 42, 43, 44, 45, 46 - initialization and shared
/// system states. The reusable inline states (LoadingSkeletonState,
/// EmptyState, ErrorState, LowStorageState) live here too and are embedded
/// by Home / catalog / library screens.

/// Screen 1 - Splash / Initialization.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final state = context.read<AppState>();
    // Keep the splash visible long enough to feel calm, never flashy.
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 900));
    InitResult result;
    try {
      result = await state.loadInitialState();
    } catch (_) {
      result = InitResult.repairNeeded;
    }
    await minDelay;
    if (!mounted) return;
    switch (result) {
      case InitResult.ready:
        Navigator.of(context).pushReplacementNamed(
          state.settings.onboardingCompleted ? Routes.home : Routes.welcome,
        );
      case InitResult.repairNeeded:
        Navigator.of(context).pushReplacementNamed(Routes.localRepair);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TcColors.heroStart, TcColors.heroMid, TcColors.heroEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TcBrandmark(size: 96, radius: 28),
                const SizedBox(height: 26),
                Text('TinyCanvas Adventures',
                    style: TcType.h1Hero.copyWith(fontSize: 34)),
                const SizedBox(height: 10),
                const Text('Getting your colors ready\u2026',
                    style:
                        TextStyle(color: Color(0xD9FFFFFF), fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Restoring your art shelf and creative tools',
                    style:
                        TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
                const SizedBox(height: 26),
                const SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    color: TcColors.gold,
                    backgroundColor: Color(0x33FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 30),
                const TcBadge('Fire OS Tablet \u2022 Offline ready',
                    kind: TcBadgeKind.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 2 - Local Repair (database/catalog integrity recovery).
class LocalRepairScreen extends StatefulWidget {
  const LocalRepairScreen({super.key});

  @override
  State<LocalRepairScreen> createState() => _LocalRepairScreenState();
}

class _LocalRepairScreenState extends State<LocalRepairScreen> {
  bool _repairing = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _repair();
  }

  Future<void> _repair() async {
    setState(() {
      _repairing = true;
      _failed = false;
    });
    final state = context.read<AppState>();
    final ok = await state.repairLocalData();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(
        state.settings.onboardingCompleted ? Routes.home : Routes.welcome,
      );
    } else {
      setState(() {
        _repairing = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: TcPanel(
              padding: const EdgeInsets.all(30),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE8F4F6), Color(0xFFFCE9D9)]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                      child: TcIcon(_failed ? 'alert' : 'spark',
                          size: 44, color: x.ink)),
                ),
                const SizedBox(height: 20),
                Text(
                  _failed
                      ? 'The tidy-up needs another try'
                      : 'Tidying the art shelf\u2026',
                  textAlign: TextAlign.center,
                  style: TcType.h1.copyWith(color: x.ink),
                ),
                const SizedBox(height: 10),
                Text(
                  _failed
                      ? 'Some local files couldn\u2019t be repaired yet. Your '
                          'coloring pages are safe - let\u2019s try once more.'
                      : 'A quick check found something to fix. Your saved '
                          'artwork is being looked after - this only takes a '
                          'moment.',
                  textAlign: TextAlign.center,
                  style: TcType.sub.copyWith(color: x.muted),
                ),
                const SizedBox(height: 22),
                if (_repairing)
                  const LinearProgressIndicator(
                    color: TcColors.blue,
                    backgroundColor: TcColors.skeletonBase,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    minHeight: 8,
                  )
                else
                  TcButton(
                      label: 'Try the repair again',
                      icon: 'undo',
                      onPressed: _repair),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 39 - Update Required / Optional Update.
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, this.required = false});

  final bool required;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: TcPanel(
                padding: const EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE8F4F6), Color(0xFFFCE9D9)]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child:
                        Center(child: TcIcon('download', size: 44, color: x.ink)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    required
                        ? 'A quick update is needed'
                        : 'A fresh update is ready',
                    textAlign: TextAlign.center,
                    style: TcType.h1.copyWith(color: x.ink),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    required
                        ? 'This version needs an update from the Amazon '
                            'Appstore before coloring can continue. Saved '
                            'artwork stays safe on the tablet.'
                        : 'A newer TinyCanvas is available in the Amazon '
                            'Appstore with fixes and polish. You can update '
                            'now or keep coloring and update later.',
                    textAlign: TextAlign.center,
                    style: TcType.sub.copyWith(color: x.muted),
                  ),
                  const SizedBox(height: 22),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    TcButton(
                      label: 'Open Amazon Appstore',
                      icon: 'download',
                      onPressed: () {
                        // Appstore deep link is wired at release time; in
                        // development this simply acknowledges the tap.
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'The Amazon Appstore listing opens here '
                                    'in the released app.')));
                      },
                    ),
                    if (!required)
                      TcButton(
                        label: 'Keep coloring',
                        kind: TcButtonKind.soft,
                        childFacing: true,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 40 - Unsupported Device.
class UnsupportedDeviceScreen extends StatelessWidget {
  const UnsupportedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: TcPanel(
                padding: const EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: TcColors.dangerBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                        child: TcIcon('alert',
                            size: 44, color: TcColors.dangerText)),
                  ),
                  const SizedBox(height: 20),
                  Text('This tablet can\u2019t run TinyCanvas',
                      textAlign: TextAlign.center,
                      style: TcType.h1.copyWith(color: x.ink)),
                  const SizedBox(height: 10),
                  Text(
                    'TinyCanvas Adventures needs Fire OS 7 or newer '
                    '(Android 9 equivalent) and a tablet-sized screen. This '
                    'device doesn\u2019t meet those needs, so the studio '
                    'can\u2019t open here.',
                    textAlign: TextAlign.center,
                    style: TcType.sub.copyWith(color: x.muted),
                  ),
                  const SizedBox(height: 18),
                  const TcBadge('Supported: Fire HD 8, HD 10, Max 11 families',
                      kind: TcBadgeKind.normal),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 42 - Loading / Skeleton (embedded by Home, catalog, library).
class LoadingSkeletonState extends StatelessWidget {
  const LoadingSkeletonState({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final columns = r.gridColumns();
    return Semantics(
      label: 'Loading pictures',
      child: Column(children: [
        const TcSkeleton(height: 120, radius: TcRadius.panel),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: TcSpace.lg,
          crossAxisSpacing: TcSpace.lg,
          childAspectRatio: 1.08,
          children: [
            for (var i = 0; i < columns * 2; i++)
              const TcSkeleton(radius: TcRadius.card),
          ],
        ),
      ]),
    );
  }
}

/// Screen 43 - Empty State (\u201cYour art shelf is ready.\u201d).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcPanel(
      padding: const EdgeInsets.all(36),
      child: Column(children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFE8F4F6), Color(0xFFFCE9D9)]),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(child: TcIcon('art', size: 44, color: x.ink)),
        ),
        const SizedBox(height: 20),
        Text('Your art shelf is ready.',
            textAlign: TextAlign.center,
            style: TcType.h1.copyWith(color: x.ink)),
        const SizedBox(height: 8),
        Text(
          'Every picture you color will live here, saved all by itself. '
          'Pick your first picture to begin!',
          textAlign: TextAlign.center,
          style: TcType.sub.copyWith(color: x.muted),
        ),
        const SizedBox(height: 22),
        TcButton(
            label: 'Find a picture',
            icon: 'grid',
            childFacing: true,
            onPressed: onAction),
      ]),
    );
  }
}

/// Screen 44 - Error State (\u201cThis shelf needs a quick refresh.\u201d).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcPanel(
      padding: const EdgeInsets.all(36),
      child: Column(children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: TcColors.badgeGoldBg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
              child:
                  TcIcon('alert', size: 44, color: TcColors.badgeGoldText)),
        ),
        const SizedBox(height: 20),
        Text('This shelf needs a quick refresh.',
            textAlign: TextAlign.center,
            style: TcType.h1.copyWith(color: x.ink)),
        const SizedBox(height: 8),
        Text(
          'Something didn\u2019t load the way it should. Nothing is lost - '
          'one tap usually fixes it.',
          textAlign: TextAlign.center,
          style: TcType.sub.copyWith(color: x.muted),
        ),
        const SizedBox(height: 22),
        TcButton(
            label: 'Refresh', icon: 'undo', childFacing: true, onPressed: onRetry),
      ]),
    );
  }
}

/// Screen 45 - Low Storage banner/state (embedded on Home; also shown from
/// export flow as a dialog).
class LowStorageState extends StatelessWidget {
  const LowStorageState({super.key, required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return TcBanner(
      icon: 'alert',
      boldText: 'Your tablet is running low on space.',
      text: 'Saving might pause soon. A grown-up can free space in '
          'Storage & erase data.',
      actionLabel: 'Manage storage',
      onAction: onManage,
    );
  }
}

/// Screen 46 - OS Settings Guidance (photos & media permission path).
class OsSettingsGuidanceScreen extends StatelessWidget {
  const OsSettingsGuidanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    const steps = [
      ('settings', 'Open the tablet\u2019s Settings app'),
      ('grid', 'Choose Apps & Notifications'),
      ('art', 'Find TinyCanvas Adventures'),
      ('shield', 'Tap Permissions'),
      ('check', 'Allow Photos and media'),
    ];
    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    TcIconButton(
                      icon: 'back',
                      semanticLabel: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TcEyebrow('Grown-ups \u2022 One-time setup'),
                          Text('Allow saving to the gallery',
                              style: TcType.h1.copyWith(color: x.ink)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text(
                    'Saving PNG copies was switched off earlier, so the '
                    'tablet needs the permission turned back on in its own '
                    'settings. Follow these five little steps:',
                    style: TcType.sub.copyWith(color: x.muted),
                  ),
                  const SizedBox(height: 20),
                  TcPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      for (var i = 0; i < steps.length; i++)
                        TcRowTile(
                          icon: steps[i].$1,
                          title: 'Step ${i + 1}',
                          subtitle: steps[i].$2,
                        ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Path: Apps & Notifications \u2192 TinyCanvas Adventures '
                    '\u2192 Permissions \u2192 Allow Photos and media',
                    style: TcType.rowSubtitle.copyWith(color: x.muted),
                  ),
                  const SizedBox(height: 20),
                  TcButton(
                    label: 'Done - back to my art',
                    icon: 'check',
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/graphics/scene_painter.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_widgets.dart';
import '../../data/models.dart';

/// Screens 2-4: Welcome, How to Color, Sound Choice. Fully responsive in
/// portrait and landscape; content is centered at a friendly max width.

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: r.mainPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 2 - Welcome (first launch).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return _OnboardingScaffold(
      child: Column(children: [
        const TcBrandmark(size: 74, radius: 22),
        const SizedBox(height: 22),
        const TcEyebrow('TinyCanvas Adventures'),
        const SizedBox(height: 8),
        Text(
          'Make a little world of color.',
          textAlign: TextAlign.center,
          style: TcType.h1.copyWith(color: x.ink),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'A calm coloring studio for little artists aged 3-12. '
            'Everything works offline, right on this tablet.',
            textAlign: TextAlign.center,
            style: TcType.sub.copyWith(color: x.muted),
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 190,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TcRadius.panel),
            child: const SceneThumb(seed: 11),
          ),
        ),
        const SizedBox(height: 26),
        TcButton(
          label: 'Let\u2019s get coloring',
          icon: 'play',
          childFacing: true,
          onPressed: () =>
              Navigator.of(context).pushNamed(Routes.howToColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            TcBadge('Offline ready', icon: 'check'),
            TcBadge('No accounts', icon: 'shield'),
            TcBadge('No ads', icon: 'heart'),
          ],
        ),
      ]),
    );
  }
}

/// Screen 3 - How to Color.
class HowToColorScreen extends StatelessWidget {
  const HowToColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);
    final cards = [
      const _HowCard(
        icon: 'brush',
        title: 'One finger colors',
        body: 'Draw, fill and stamp with a single fingertip.',
      ),
      const _HowCard(
        icon: 'grid',
        title: 'Two fingers move & zoom',
        body: 'Pinch to zoom up to 4x and slide to look around.',
      ),
      const _HowCard(
        icon: 'undo',
        title: 'Oops-proof',
        body: 'Undo, redo and clear are always one tap away.',
      ),
    ];
    return _OnboardingScaffold(
      child: Column(children: [
        const TcEyebrow('How to color'),
        const SizedBox(height: 8),
        Text('Three tiny things to know',
            textAlign: TextAlign.center,
            style: TcType.h1.copyWith(color: x.ink)),
        const SizedBox(height: 24),
        if (r.splitCollapses)
          Column(children: [
            for (final card in cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: card,
              ),
          ])
        else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final card in cards)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: card,
                ),
              ),
          ]),
        const SizedBox(height: 26),
        Wrap(spacing: 12, runSpacing: 12, children: [
          TcButton(
            label: 'Back',
            icon: 'back',
            kind: TcButtonKind.soft,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          TcButton(
            label: 'Next: sounds',
            trailingIcon: 'forward',
            childFacing: true,
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.soundChoice),
          ),
        ]),
      ]),
    );
  }
}

class _HowCard extends StatelessWidget {
  const _HowCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcPanel(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: TcColors.rowIconBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(child: TcIcon(icon, size: 28, color: TcColors.blue)),
        ),
        const SizedBox(height: 14),
        Text(title,
            textAlign: TextAlign.center,
            style: TcType.h3.copyWith(color: x.ink)),
        const SizedBox(height: 6),
        Text(body,
            textAlign: TextAlign.center,
            style: TcType.rowSubtitle.copyWith(color: x.muted)),
      ]),
    );
  }
}

/// Screen 4 - Sound Choice, completes onboarding.
class SoundChoiceScreen extends StatefulWidget {
  const SoundChoiceScreen({super.key});

  @override
  State<SoundChoiceScreen> createState() => _SoundChoiceScreenState();
}

class _SoundChoiceScreenState extends State<SoundChoiceScreen> {
  SoundMode _mode = SoundMode.playful;
  bool _saving = false;

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    await state.updateSettings(state.settings.copyWith(
      soundMode: _mode,
      soundEffectsEnabled: _mode != SoundMode.silent,
      musicEnabled: _mode == SoundMode.playful,
      onboardingCompleted: true,
    ));
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final r = Responsive.of(context);
    final options = [
      (SoundMode.playful, 'sound', 'Playful', 'Music, effects and voice hints.'),
      (SoundMode.quiet, 'sound', 'Quiet', 'Gentle effects only - no music.'),
      (SoundMode.silent, 'close', 'Silent', 'A completely quiet studio.'),
    ];
    return _OnboardingScaffold(
      child: Column(children: [
        const TcEyebrow('One last thing'),
        const SizedBox(height: 8),
        Text('How should the studio sound?',
            textAlign: TextAlign.center,
            style: TcType.h1.copyWith(color: x.ink)),
        const SizedBox(height: 10),
        Text('You can change this anytime in the Parent Zone.',
            textAlign: TextAlign.center,
            style: TcType.sub.copyWith(color: x.muted)),
        const SizedBox(height: 24),
        Flex(
          direction: r.splitCollapses ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (mode, icon, title, body) in options)
              Flexible(
                flex: 1,
                fit: r.splitCollapses ? FlexFit.loose : FlexFit.tight,
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: TcCard(
                    selected: _mode == mode,
                    semanticLabel: '$title sound mode',
                    onTap: () => setState(() => _mode = mode),
                    child: Column(children: [
                      TcIcon(icon,
                          size: 28,
                          color: _mode == mode
                              ? TcColors.blue
                              : x.muted),
                      const SizedBox(height: 10),
                      Text(title, style: TcType.h3.copyWith(color: x.ink)),
                      const SizedBox(height: 4),
                      Text(body,
                          textAlign: TextAlign.center,
                          style:
                              TcType.rowSubtitle.copyWith(color: x.muted)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        TcButton(
          label: _saving ? 'Getting ready\u2026' : 'Start my studio',
          icon: 'star',
          childFacing: true,
          onPressed: _saving ? null : _finish,
        ),
      ]),
    );
  }
}

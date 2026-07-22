import 'package:flutter/material.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_widgets.dart';

/// Screens 35-38: Privacy Policy, Terms, Open-source Licenses,
/// About / Help.
///
/// Privacy Policy and Terms are clearly marked DEVELOPMENT PLACEHOLDERS and
/// are release blockers until legally reviewed content is supplied
/// (docs/RELEASE_CHECKLIST.md).
class _LegalShell extends StatelessWidget {
  const _LegalShell({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
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
                      semanticLabel: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TcEyebrow(eyebrow),
                          Text(title,
                              style: TcType.h1.copyWith(color: x.ink)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderNotice extends StatelessWidget {
  const _PlaceholderNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TcColors.badgeGoldBg,
        borderRadius: BorderRadius.circular(TcRadius.small),
        border: Border.all(color: TcColors.gold),
      ),
      child: Text(
        'DEVELOPMENT PLACEHOLDER - this text must be replaced with legally '
        'reviewed content before release. See docs/RELEASE_CHECKLIST.md.',
        style: TcType.rowSubtitle.copyWith(
            color: TcColors.badgeGoldText, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody(this.sections);

  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcPanel(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (heading, body) in sections) ...[
            Text(heading, style: TcType.h3.copyWith(color: x.ink)),
            const SizedBox(height: 6),
            Text(body,
                style: TcType.sub.copyWith(color: x.muted, height: 1.55)),
            if ((heading, body) != sections.last) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

/// Screen 35 - Privacy Policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalShell(
      eyebrow: 'Legal',
      title: 'Privacy Policy',
      child: Column(children: const [
        _PlaceholderNotice(),
        _LegalBody([
          (
            'Everything stays on this tablet',
            'TinyCanvas Adventures works completely offline. Artwork, '
                'progress, favorites, badges, and settings are stored only in '
                'this app\u2019s private storage on this device. Nothing is '
                'uploaded, synced, or shared.'
          ),
          (
            'No accounts, no tracking',
            'The app has no accounts, no advertising, no analytics, and no '
                'social features. It never collects names, emails, ages, '
                'locations, contacts, advertising identifiers, or behavioral '
                'profiles of children.'
          ),
          (
            'Purchases are handled by Amazon',
            'The optional one-time unlock is processed entirely by the '
                'Amazon Appstore. TinyCanvas never sees or stores payment '
                'details. Only a local record of whether the unlock is owned '
                'is kept on the device so premium pictures work offline.'
          ),
          (
            'Exported pictures',
            'When a caregiver chooses \u201cSave to gallery\u201d, a PNG copy '
                'of the artwork is written to this tablet\u2019s Pictures '
                'folder. That is the only time content leaves the app\u2019s '
                'private storage, and it stays on the device.'
          ),
          (
            'Questions',
            'Support contact details will appear here in the final, '
                'legally reviewed policy.'
          ),
        ]),
      ]),
    );
  }
}

/// Screen 36 - Terms of Use.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalShell(
      eyebrow: 'Legal',
      title: 'Terms of Use',
      child: Column(children: const [
        _PlaceholderNotice(),
        _LegalBody([
          (
            'The app and its content',
            'TinyCanvas Adventures and its 120 original coloring pages are '
                'provided for personal, non-commercial creative fun on this '
                'device. The line art, illustrations, and design remain the '
                'property of the app\u2019s owner.'
          ),
          (
            'The one-time unlock',
            'The optional unlock is a single Amazon In-App purchase tied to '
                'the Amazon account used at checkout. It is not a '
                'subscription and never renews. Amazon\u2019s own terms '
                'govern billing, refunds, and account questions.'
          ),
          (
            'Caregiver responsibilities',
            'Purchases, exports, data erasure, and external links are '
                'protected behind a grown-up gate. Caregivers are responsible '
                'for actions taken after passing that gate.'
          ),
          (
            'No warranty',
            'The final reviewed terms will describe warranty, liability, and '
                'governing law here.'
          ),
        ]),
      ]),
    );
  }
}

/// Screen 37 - Open-source Licenses. Uses Flutter's built-in license
/// registry so every bundled package (Flutter engine, sqflite, provider,
/// path_provider, ...) is listed accurately and automatically.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return _LegalShell(
      eyebrow: 'Legal',
      title: 'Open-source licenses',
      child: TcPanel(
        padding: const EdgeInsets.all(26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'TinyCanvas is built with the Flutter framework and a small set '
            'of open-source packages. Their license texts are bundled inside '
            'the app and always available offline.',
            style: TcType.sub.copyWith(color: x.muted),
          ),
          const SizedBox(height: 18),
          TcButton(
            label: 'View all license texts',
            icon: 'book',
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'TinyCanvas Adventures',
              applicationVersion: '1.0.0 (1)',
            ),
          ),
        ]),
      ),
    );
  }
}

/// Screen 38 - About / Help.
class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return _LegalShell(
      eyebrow: 'Parent Zone',
      title: 'About & help',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TcPanel(
          padding: const EdgeInsets.all(26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const TcBrandmark(size: 56, radius: 18),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TinyCanvas Adventures',
                        style: TcType.h2.copyWith(color: x.ink)),
                    Text('Version 1.0.0 (build 1) \u2022 Fire OS tablets',
                        style: TcType.rowSubtitle.copyWith(color: x.muted)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text(
              'An offline-first coloring studio for little artists aged 3 to '
              '12. 120 original pictures, gentle tools, and everything saved '
              'safely on this tablet.',
              style: TcType.sub.copyWith(color: x.muted),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        TcPanel(
          padding: const EdgeInsets.all(26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quick help', style: TcType.h3.copyWith(color: x.ink)),
            const SizedBox(height: 12),
            for (final (q, a) in const [
              (
                'How do I color?',
                'One finger colors. Two fingers move and zoom the picture. '
                    'Pick tools from the dark dock and colors from the '
                    'palette.'
              ),
              (
                'Where are saved pictures?',
                'Everything saves automatically to My Art. Tap any artwork '
                    'to keep coloring, rename, favorite, or save a PNG copy.'
              ),
              (
                'How do I unlock all pictures?',
                'A grown-up can pass the two-star hold in the top corner, '
                    'then choose Unlock all. It\u2019s one Amazon purchase - '
                    'no subscription.'
              ),
              (
                'My purchase is missing',
                'Open Parent Zone \u2192 Restore purchase while online with '
                    'the same Amazon account. Nothing is charged again.'
              ),
            ]) ...[
              Text(q, style: TcType.rowTitle.copyWith(color: x.ink)),
              const SizedBox(height: 4),
              Text(a,
                  style: TcType.sub.copyWith(color: x.muted, height: 1.5)),
              const SizedBox(height: 14),
            ],
            Text(
              'Support contact: placeholder \u2014 the final support email '
              'and website (opened outside the app, behind the grown-up '
              'gate) will be added before release.',
              style: TcType.rowSubtitle.copyWith(color: x.muted),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        TcButton(
          label: 'Open-source licenses',
          icon: 'book',
          kind: TcButtonKind.soft,
          onPressed: () => Navigator.of(context).pushNamed(Routes.licenses),
        ),
      ]),
    );
  }
}

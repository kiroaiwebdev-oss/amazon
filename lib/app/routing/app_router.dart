import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/tc_scaffold.dart';
import '../../features/adult_gate/adult_gate_dialog.dart';
import '../../features/artwork_library/library_screens.dart';
import '../../features/badges/badges_screen.dart';
import '../../features/catalog/catalog_screens.dart';
import '../../features/coloring/canvas_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/initialization/system_screens.dart';
import '../../features/legal/legal_screens.dart';
import '../../features/onboarding/onboarding_screens.dart';
import '../../features/parent_zone/parent_zone_screens.dart';
import '../../features/preview/page_preview_screen.dart';
import '../../features/purchase/purchase_screens.dart';
import '../app_state.dart';

/// All named routes. Every route has a valid return path: pushes always
/// arrive on screens with a back affordance, and guard failures fall back
/// to safe screens instead of dead ends.
abstract final class Routes {
  static const splash = '/';
  static const localRepair = '/repair';
  static const welcome = '/welcome';
  static const howToColor = '/welcome/how-to-color';
  static const soundChoice = '/welcome/sound';
  static const home = '/home';
  static const explore = '/explore';
  static const category = '/explore/category';
  static const search = '/search';
  static const preview = '/preview';
  static const canvas = '/canvas';
  static const myArt = '/my-art';
  static const artworkDetail = '/my-art/detail';
  static const badges = '/badges';
  static const paywall = '/unlock';
  static const restore = '/unlock/restore';
  static const parentZone = '/parent-zone';
  static const soundMotion = '/parent-zone/sound-motion';
  static const storageErase = '/parent-zone/storage';
  static const privacy = '/legal/privacy';
  static const terms = '/legal/terms';
  static const licenses = '/legal/licenses';
  static const about = '/about';
  static const update = '/system/update';
  static const updateRequired = '/system/update-required';
  static const unsupportedDevice = '/system/unsupported';
  static const osSettingsGuidance = '/system/os-settings';
}

/// Bottom-nav / rail section navigation used by TcShell.
void navigateSection(BuildContext context, TcNavSection section) {
  switch (section) {
    case TcNavSection.home:
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.home, (r) => false);
    case TcNavSection.explore:
      Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.explore, (r) => r.settings.name == Routes.home);
    case TcNavSection.art:
      Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.myArt, (r) => r.settings.name == Routes.home);
    case TcNavSection.parents:
      Navigator.of(context).pushNamed(Routes.parentZone);
  }
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case Routes.splash:
      page = const SplashScreen();
    case Routes.localRepair:
      page = const LocalRepairScreen();
    case Routes.welcome:
      page = const WelcomeScreen();
    case Routes.howToColor:
      page = const HowToColorScreen();
    case Routes.soundChoice:
      page = const SoundChoiceScreen();
    case Routes.home:
      page = const _OnboardingGuard(child: HomeScreen());
    case Routes.explore:
      page = const _OnboardingGuard(child: ExploreScreen());
    case Routes.category:
      final category = settings.arguments as String? ?? 'Going Places';
      page = _OnboardingGuard(
          child: CategoryResultsScreen(category: category));
    case Routes.search:
      page = const _OnboardingGuard(child: SearchScreen());
    case Routes.preview:
      final id = settings.arguments as String?;
      page = id == null
          ? const _OnboardingGuard(child: ExploreScreen())
          : _OnboardingGuard(child: PagePreviewScreen(catalogItemId: id));
    case Routes.canvas:
      final args = settings.arguments;
      page = args is CanvasArgs
          ? _OnboardingGuard(
              child: _EntitlementGuard(
                  catalogItemId: args.catalogItemId,
                  child: CanvasScreen(args: args)))
          : const _OnboardingGuard(child: ExploreScreen());
    case Routes.myArt:
      page = const _OnboardingGuard(child: MyArtScreen());
    case Routes.artworkDetail:
      final id = settings.arguments as String?;
      page = id == null
          ? const _OnboardingGuard(child: MyArtScreen())
          : _OnboardingGuard(child: ArtworkDetailScreen(artworkId: id));
    case Routes.badges:
      page = const _OnboardingGuard(child: BadgesScreen());
    case Routes.paywall:
      page = const PaywallScreen();
    case Routes.restore:
      page = const RestorePurchaseScreen();
    case Routes.parentZone:
      page = const _AdultGateGuard(child: ParentZoneScreen());
    case Routes.soundMotion:
      page = const SoundMotionScreen();
    case Routes.storageErase:
      page = const StorageEraseScreen();
    case Routes.privacy:
      page = const PrivacyPolicyScreen();
    case Routes.terms:
      page = const TermsScreen();
    case Routes.licenses:
      page = const LicensesScreen();
    case Routes.about:
      page = const AboutHelpScreen();
    case Routes.update:
      page = const UpdateScreen();
    case Routes.updateRequired:
      page = const UpdateScreen(required: true);
    case Routes.unsupportedDevice:
      page = const UnsupportedDeviceScreen();
    case Routes.osSettingsGuidance:
      page = const OsSettingsGuidanceScreen();
    default:
      // Unknown routes are never dead ends - land on Home.
      page = const _OnboardingGuard(child: HomeScreen());
  }
  return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
}

/// Route guard: content screens require completed onboarding; otherwise
/// the child is redirected to Welcome.
class _OnboardingGuard extends StatelessWidget {
  const _OnboardingGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.initialized) return const SplashScreen();
    if (!state.settings.onboardingCompleted) return const WelcomeScreen();
    return child;
  }
}

/// Route guard: the Canvas refuses to open premium content without
/// ownership, redirecting to the preview (which offers the unlock path).
class _EntitlementGuard extends StatelessWidget {
  const _EntitlementGuard({
    required this.catalogItemId,
    required this.child,
  });

  final String catalogItemId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return FutureBuilder<bool>(
      future: state.canOpenById(catalogItemId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return PagePreviewScreen(catalogItemId: catalogItemId);
        }
        return child;
      },
    );
  }
}

/// Route guard: Parent Zone requires passing the Adult Gate every time it
/// is opened. Failing or dismissing the gate returns to the previous
/// screen (child mode) safely.
class _AdultGateGuard extends StatefulWidget {
  const _AdultGateGuard({required this.child});

  final Widget child;

  @override
  State<_AdultGateGuard> createState() => _AdultGateGuardState();
}

class _AdultGateGuardState extends State<_AdultGateGuard> {
  bool _unlocked = false;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  Future<void> _ask() async {
    if (_asked) return;
    _asked = true;
    final ok = await showAdultGate(context,
        reason: 'The Parent Zone is for grown-ups.');
    if (!mounted) return;
    if (ok) {
      setState(() => _unlocked = true);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return const Scaffold(body: SizedBox.expand());
    }
    return widget.child;
  }
}

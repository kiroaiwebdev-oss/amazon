import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_widgets.dart';
import 'purchase_controller.dart';
import 'purchase_service.dart';

/// Screens 26-31: Unlock All Paywall, Amazon Checkout Handoff, Purchase
/// Pending, Purchase Success, Purchase Failure / Cancelled, Restore
/// Purchase. The paywall drives all purchase phases from a single
/// controller so no state combination is unreachable.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late final PurchaseController _controller;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _controller = PurchaseController(
      service: state.purchaseService,
      connectivity: state.connectivity,
      entitlements: state.entitlements,
      onOwnershipChanged: state.setOwnership,
    );
    _controller.addListener(_onChanged);
    _controller.loadPaywall();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
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
                    const TcEyebrow('Grown-ups \u2022 Unlock the studio'),
                  ]),
                  const SizedBox(height: 18),
                  _buildPhase(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context) {
    switch (_controller.phase) {
      case PurchasePhase.unknown:
      case PurchasePhase.loading:
        return const PhaseCard(
          icon: 'spark',
          title: 'Checking with Amazon\u2026',
          body: 'Fetching the current product details and price.',
          progress: true,
        );
      case PurchasePhase.offline:
        return PhaseCard(
          icon: 'wifi',
          title: 'You\u2019re offline right now',
          body: 'Unlocking needs a quick internet connection so Amazon can '
              'show the price and complete the purchase. Coloring the 20 free '
              'pictures still works offline.',
          actions: [
            TcButton(
                label: 'Try again',
                icon: 'undo',
                onPressed: _controller.loadPaywall),
            _backButton(context),
          ],
        );
      case PurchasePhase.productUnavailable:
        return PhaseCard(
          icon: 'alert',
          title: 'The shop shelf is being restocked',
          body: 'Amazon couldn\u2019t show this product right now. Please try '
              'again in a little while - nothing is wrong with your tablet.',
          actions: [
            TcButton(
                label: 'Try again',
                icon: 'undo',
                onPressed: _controller.loadPaywall),
            _backButton(context),
          ],
        );
      case PurchasePhase.notOwned:
        return _OfferCard(controller: _controller);
      case PurchasePhase.checkoutHandoff:
        // Screen 27 - Amazon Checkout Handoff.
        return const PhaseCard(
          icon: 'lock',
          title: 'Opening secure Amazon checkout\u2026',
          body: 'Amazon handles the payment on its own secure screen. '
              'TinyCanvas never sees or stores payment details.',
          progress: true,
        );
      case PurchasePhase.pending:
        // Screen 28 - Purchase Pending.
        return PhaseCard(
          icon: 'spark',
          title: 'Amazon is processing your purchase',
          body: 'This can take a moment. You can keep coloring - the premium '
              'pictures will unlock automatically once Amazon confirms.',
          progress: true,
          actions: [_backButton(context, label: 'Keep coloring')],
        );
      case PurchasePhase.owned:
        // Screen 29 - Purchase Success.
        return PhaseCard(
          icon: 'star',
          iconGold: true,
          title: 'All 120 pictures are ready!',
          body: 'The whole studio is unlocked. Thank you for supporting '
              'TinyCanvas - happy coloring, little artist!',
          actions: [
            TcButton(
              label: 'Start exploring',
              icon: 'play',
              childFacing: true,
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(Routes.explore, (r) => false),
            ),
          ],
        );
      case PurchasePhase.alreadyOwned:
        return PhaseCard(
          icon: 'check',
          iconGold: true,
          title: 'Already unlocked!',
          body: 'This Amazon account already owns the full studio. All 120 '
              'pictures are available on this tablet.',
          actions: [
            TcButton(
              label: 'Back to pictures',
              icon: 'play',
              childFacing: true,
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(Routes.explore, (r) => false),
            ),
          ],
        );
      case PurchasePhase.cancelled:
        // Screen 30 (cancelled variant).
        return PhaseCard(
          icon: 'info',
          title: 'Purchase cancelled',
          body: 'No problem - nothing was charged. The 20 free pictures are '
              'always here to color.',
          actions: [
            TcButton(
                label: 'Try again',
                icon: 'undo',
                onPressed: _controller.loadPaywall),
            _backButton(context),
          ],
        );
      case PurchasePhase.failed:
        // Screen 30 (failure variant).
        return PhaseCard(
          icon: 'alert',
          title: 'Purchase wasn\u2019t completed',
          body: 'No charge was confirmed. This can happen when the '
              'connection hiccups. You can safely try again, and Amazon '
              'will never charge twice for one unlock.',
          actions: [
            TcButton(
                label: 'Try again',
                icon: 'undo',
                onPressed: _controller.loadPaywall),
            _backButton(context),
          ],
        );
      case PurchasePhase.restoreSuccess:
      case PurchasePhase.noPurchaseFound:
      case PurchasePhase.restoreError:
        // Restore phases render on the dedicated Restore screen; if reached
        // here, show the offer again.
        return _OfferCard(controller: _controller);
    }
  }

  Widget _backButton(BuildContext context, {String label = 'Not now'}) =>
      TcButton(
        label: label,
        kind: TcButtonKind.soft,
        onPressed: () => Navigator.of(context).maybePop(),
      );
}

/// Screen 26 - the paywall offer itself (not-owned, online).
class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.controller});

  final PurchaseController controller;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    final product = controller.product;
    final price = product?.price ?? kReferencePrice;
    final isReference = product == null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TcColors.heroStart, TcColors.heroMid, TcColors.heroEnd],
          ),
          borderRadius: BorderRadius.circular(TcRadius.panel),
          boxShadow: TcShadows.panel,
        ),
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TcBadge('One-time unlock \u2022 No subscription',
              kind: TcBadgeKind.gold),
          const SizedBox(height: 14),
          Text('Unlock all 100 pictures',
              style: TcType.h1Hero.copyWith(fontSize: 34)),
          const SizedBox(height: 8),
          const Text(
            'Open every little world in the studio - forever, on this '
            'Amazon account.',
            style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 14),
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 18, runSpacing: 12, children: const [
            TcMetric(value: '120', label: 'pictures in total'),
            TcMetric(value: '20', label: 'always free'),
            TcMetric(value: '100', label: 'premium unlocked'),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      TcPanel(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price, style: TcType.price.copyWith(color: x.ink)),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  isReference ? 'reference price' : 'from Amazon',
                  style: TcType.rowSubtitle.copyWith(color: x.muted)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            isReference
                ? '\$4.99 reference price. The final localized price appears '
                    'from Amazon before checkout.'
                : 'This localized price comes from Amazon. Checkout happens '
                    'on Amazon\u2019s own secure screen.',
            style: TcType.rowSubtitle.copyWith(color: x.muted),
          ),
          const SizedBox(height: 18),
          const _CheckRow('One purchase, no subscription, no ads'),
          const _CheckRow('Works offline after unlocking'),
          const _CheckRow('Shared with Amazon household on this account'),
          const _CheckRow('Restore anytime with the same Amazon account'),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            TcButton(
              label: 'Unlock with Amazon',
              icon: 'lock',
              kind: TcButtonKind.coral,
              onPressed:
                  controller.busy ? null : controller.startPurchase,
            ),
            TcButton(
              label: 'Restore a purchase',
              kind: TcButtonKind.soft,
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.restore),
            ),
            TcButton(
              label: 'Not now',
              kind: TcButtonKind.link,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        const TcIcon('check', size: 18, color: TcColors.leaf),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text, style: TcType.sub.copyWith(color: x.ink))),
      ]),
    );
  }
}

/// Shared purchase/system phase card used by paywall + restore flows.
class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.progress = false,
    this.iconGold = false,
    this.actions = const [],
  });

  final String icon;
  final String title;
  final String body;
  final bool progress;
  final bool iconGold;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);
    return TcPanel(
      padding: const EdgeInsets.all(30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: iconGold
                ? const LinearGradient(
                    colors: [TcColors.gold, Color(0xFFF7D98C)])
                : const LinearGradient(
                    colors: [Color(0xFFE8F4F6), Color(0xFFFCE9D9)]),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(child: TcIcon(icon, size: 44, color: x.ink)),
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text(title, style: TcType.h1.copyWith(color: x.ink)),
        ),
        const SizedBox(height: 10),
        Text(body, style: TcType.sub.copyWith(color: x.muted)),
        if (progress) ...[
          const SizedBox(height: 20),
          const LinearProgressIndicator(
            color: TcColors.blue,
            backgroundColor: TcColors.skeletonBase,
            borderRadius: BorderRadius.all(Radius.circular(99)),
            minHeight: 8,
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(spacing: 12, runSpacing: 12, children: actions),
        ],
      ]),
    );
  }
}

/// Screen 31 - Restore Purchase (with offline / no-purchase / error
/// variants).
class RestorePurchaseScreen extends StatefulWidget {
  const RestorePurchaseScreen({super.key});

  @override
  State<RestorePurchaseScreen> createState() => _RestorePurchaseScreenState();
}

class _RestorePurchaseScreenState extends State<RestorePurchaseScreen> {
  late final PurchaseController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _controller = PurchaseController(
      service: state.purchaseService,
      connectivity: state.connectivity,
      entitlements: state.entitlements,
      onOwnershipChanged: state.setOwnership,
    );
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _restore() async {
    setState(() => _started = true);
    await _controller.restore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TcColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
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
                    const TcEyebrow('Grown-ups \u2022 Restore purchase'),
                  ]),
                  const SizedBox(height: 18),
                  _buildPhase(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context) {
    if (!_started) {
      return PhaseCard(
        icon: 'undo',
        title: 'Bring your unlock back',
        body: 'If this Amazon account already purchased the full studio - '
            'maybe on another Fire tablet - restoring brings all 100 premium '
            'pictures back here. Nothing is purchased again.',
        actions: [
          TcButton(
              label: 'Restore from Amazon',
              icon: 'undo',
              onPressed: _restore),
          TcButton(
            label: 'Cancel',
            kind: TcButtonKind.soft,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      );
    }
    switch (_controller.phase) {
      case PurchasePhase.loading:
      case PurchasePhase.unknown:
        return const PhaseCard(
          icon: 'spark',
          title: 'Checking with Amazon\u2026',
          body: 'Looking for a purchase on this Amazon account.',
          progress: true,
        );
      case PurchasePhase.offline:
        return PhaseCard(
          icon: 'wifi',
          title: 'You\u2019re offline right now',
          body: 'Restoring needs a quick connection so Amazon can check this '
              'account. Everything already on the tablet keeps working.',
          actions: [
            TcButton(label: 'Try again', icon: 'undo', onPressed: _restore),
            TcButton(
              label: 'Back',
              kind: TcButtonKind.soft,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        );
      case PurchasePhase.restoreSuccess:
      case PurchasePhase.owned:
      case PurchasePhase.alreadyOwned:
        return PhaseCard(
          icon: 'star',
          iconGold: true,
          title: 'Welcome back - it\u2019s all here!',
          body: 'Your unlock was found and all 100 premium pictures are '
              'ready again on this tablet.',
          actions: [
            TcButton(
              label: 'Start exploring',
              icon: 'play',
              childFacing: true,
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(Routes.explore, (r) => false),
            ),
          ],
        );
      case PurchasePhase.noPurchaseFound:
        return PhaseCard(
          icon: 'info',
          title: 'No purchase found',
          body: 'Amazon didn\u2019t find an unlock on this account. If you '
              'purchased on another account, switch to it in the tablet '
              'settings and try again.',
          actions: [
            TcButton(label: 'Try again', icon: 'undo', onPressed: _restore),
            TcButton(
              label: 'See unlock options',
              kind: TcButtonKind.soft,
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(Routes.paywall),
            ),
          ],
        );
      case PurchasePhase.restoreError:
      default:
        return PhaseCard(
          icon: 'alert',
          title: 'Restore hit a bump',
          body: 'Amazon couldn\u2019t finish checking right now. Nothing was '
              'changed - please try again in a moment.',
          actions: [
            TcButton(label: 'Try again', icon: 'undo', onPressed: _restore),
            TcButton(
              label: 'Back',
              kind: TcButtonKind.soft,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        );
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/tc_icons.dart';
import '../../core/widgets/tc_scaffold.dart';
import '../../core/widgets/tc_widgets.dart';
import 'adult_gate_controller.dart';

/// Screen 25 - Adult Gate.
/// Primary: hold both stars together for 3 seconds. Accessible alternative:
/// an arithmetic question with keyboard/switch access. Three failures start
/// a calm 30-second cooldown with a safe return to child mode.
Future<bool> showAdultGate(BuildContext context,
    {required String reason}) async {
  final result = await showTcModal<bool>(
    context,
    _AdultGateCard(reason: reason),
    dismissible: false,
  );
  return result ?? false;
}

class _AdultGateCard extends StatefulWidget {
  const _AdultGateCard({required this.reason});

  final String reason;

  @override
  State<_AdultGateCard> createState() => _AdultGateCardState();
}

class _AdultGateCardState extends State<_AdultGateCard> {
  final _controller = AdultGateController();
  final _answerController = TextEditingController();
  bool _useQuestion = false;
  bool _leftHeld = false;
  bool _rightHeld = false;
  Timer? _ticker;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    // Lightweight ticker keeps the hold progress and cooldown countdown
    // fresh without a full AnimationController.
    _ticker = Timer.periodic(
        const Duration(milliseconds: 250), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_controller.unlocked) {
      Navigator.of(context, rootNavigator: true).pop(true);
      return;
    }
    setState(() {});
  }

  void _updateHold() {
    if (_leftHeld && _rightHeld) {
      _controller.startHold();
    } else {
      final wasHolding = _controller.holdProgress > 0;
      _controller.cancelHold();
      if (wasHolding && !_controller.unlocked) {
        _feedback = 'Almost! Hold both stars all the way.';
      }
    }
    setState(() {});
  }

  void _submitAnswer() {
    final ok = _controller.submitAnswer(_answerController.text.trim());
    if (!ok) {
      _answerController.clear();
      setState(() =>
          _feedback = 'Not quite - that\u2019s okay. Try the new question.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = TcThemeX.of(context);

    if (_controller.inCooldown) {
      final seconds = _controller.cooldownRemaining.inSeconds + 1;
      return TcModalCard(
        icon: 'shield',
        title: 'Let\u2019s take a little break',
        body: 'The grown-up check will be ready again in $seconds seconds. '
            'No worries - the coloring fun continues!',
        actions: [
          TcButton(
            label: 'Back to coloring',
            kind: TcButtonKind.soft,
            childFacing: true,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
          ),
        ],
      );
    }

    return TcModalCard(
      icon: 'shield',
      title: 'Grown-ups only',
      body: '${widget.reason} Touch and hold both stars together for three '
          'seconds\u2014or use the accessible question.',
      content: Column(children: [
        if (_feedback != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(_feedback!,
                textAlign: TextAlign.center,
                style: TcType.rowSubtitle
                    .copyWith(color: TcColors.badgeGoldText)),
          ),
          const SizedBox(height: 12),
        ],
        if (!_useQuestion) ...[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _HoldStar(
              held: _leftHeld,
              label: 'Left star',
              onChanged: (held) {
                _leftHeld = held;
                _updateHold();
              },
            ),
            const SizedBox(width: 26),
            _HoldStar(
              held: _rightHeld,
              label: 'Right star',
              onChanged: (held) {
                _rightHeld = held;
                _updateHold();
              },
            ),
          ]),
          const SizedBox(height: 16),
          TcProgressBar(
            _controller.holdProgress,
            semanticLabel:
                'Hold progress ${(_controller.holdProgress * 100).round()} percent',
          ),
        ] else ...[
          Text(_controller.question, style: TcType.h2.copyWith(color: x.ink)),
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitAnswer(),
            decoration: InputDecoration(
              hintText: 'Type the answer',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TcRadius.small),
                borderSide: const BorderSide(color: TcColors.line),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TcButton(
              label: 'Check answer', icon: 'check', onPressed: _submitAnswer),
        ],
      ]),
      actions: [
        TcButton(
          label: _useQuestion
              ? 'Use the two-star hold instead'
              : 'Use the accessible question instead',
          kind: TcButtonKind.link,
          onPressed: () => setState(() {
            _useQuestion = !_useQuestion;
            _feedback = null;
            _controller.cancelHold();
            _leftHeld = false;
            _rightHeld = false;
          }),
        ),
        TcButton(
          label: 'Back to coloring',
          kind: TcButtonKind.soft,
          childFacing: true,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
      ],
    );
  }
}

class _HoldStar extends StatelessWidget {
  const _HoldStar({
    required this.held,
    required this.label,
    required this.onChanged,
  });

  final bool held;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, touch and hold',
      child: GestureDetector(
        onTapDown: (_) => onChanged(true),
        onTapUp: (_) => onChanged(false),
        onTapCancel: () => onChanged(false),
        child: AnimatedContainer(
          duration: TcThemeX.of(context).motion(TcDurations.fast),
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: held
                ? const LinearGradient(
                    colors: [TcColors.gold, Color(0xFFF7D98C)])
                : null,
            color: held ? null : TcColors.rowIconBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: held ? TcColors.gold : TcColors.line, width: 2),
          ),
          child: Center(
            child: TcIcon('star',
                size: 38, color: held ? TcColors.ink : TcColors.blue),
          ),
        ),
      ),
    );
  }
}

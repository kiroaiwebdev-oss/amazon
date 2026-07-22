import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../app/theme/tokens.dart';

/// State machine for the Adult Gate (Screen 25).
///
/// Primary path: both stars held together for [TcDurations.adultGateHold]
/// (3 seconds). Accessible path: a simple arithmetic question. Three failed
/// attempts start a calm [TcDurations.adultGateCooldown] (30 seconds)
/// cooldown during which the gate cannot be attempted.
class AdultGateController extends ChangeNotifier {
  AdultGateController({DateTime Function()? clock, math.Random? random})
      : _clock = clock ?? DateTime.now,
        _random = random ?? math.Random() {
    _newQuestion();
  }

  final DateTime Function() _clock;
  final math.Random _random;

  bool _unlocked = false;
  int _failures = 0;
  DateTime? _holdStart;
  DateTime? _cooldownUntil;
  Timer? _holdTimer;
  late int _a;
  late int _b;

  bool get unlocked => _unlocked;

  int get failures => _failures;

  bool get inCooldown {
    final until = _cooldownUntil;
    if (until == null) return false;
    if (_clock().isBefore(until)) return true;
    return false;
  }

  Duration get cooldownRemaining {
    final until = _cooldownUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  /// 0..1 progress of the current two-star hold.
  double get holdProgress {
    final start = _holdStart;
    if (start == null) return _unlocked ? 1 : 0;
    final elapsed = _clock().difference(start).inMilliseconds /
        TcDurations.adultGateHold.inMilliseconds;
    return elapsed.clamp(0.0, 1.0);
  }

  String get question => 'What is $_a + $_b?';

  void _newQuestion() {
    _a = 6 + _random.nextInt(7); // 6..12
    _b = 3 + _random.nextInt(6); // 3..8
  }

  /// Begin the two-star hold. No-op while unlocked or cooling down.
  void startHold() {
    if (_unlocked || inCooldown || _holdStart != null) return;
    _holdStart = _clock();
    _holdTimer = Timer(TcDurations.adultGateHold, _completeHold);
    notifyListeners();
  }

  void _completeHold() {
    if (_holdStart == null) return;
    _holdStart = null;
    _unlocked = true;
    notifyListeners();
  }

  /// Cancel an in-flight hold (finger lifted). A hold released after
  /// meaningful progress counts as a failed attempt.
  void cancelHold() {
    if (_holdStart == null) return;
    final progressed = holdProgress > 0.3;
    _holdStart = null;
    _holdTimer?.cancel();
    _holdTimer = null;
    if (progressed) {
      _registerFailure();
    }
    notifyListeners();
  }

  /// Check the accessible arithmetic answer. Wrong answers count toward the
  /// three-failure cooldown and rotate the question.
  bool submitAnswer(String answer) {
    if (_unlocked || inCooldown) return _unlocked;
    final value = int.tryParse(answer.trim());
    if (value == _a + _b) {
      _unlocked = true;
      notifyListeners();
      return true;
    }
    _newQuestion();
    _registerFailure();
    notifyListeners();
    return false;
  }

  void _registerFailure() {
    _failures += 1;
    if (_failures >= 3) {
      _failures = 0;
      _cooldownUntil = _clock().add(TcDurations.adultGateCooldown);
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }
}

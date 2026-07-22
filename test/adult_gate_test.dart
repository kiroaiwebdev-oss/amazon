import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tinycanvas_adventures/features/adult_gate/adult_gate_controller.dart';

/// A controllable clock so hold/cooldown timing is deterministic.
class _FakeClock {
  DateTime now = DateTime(2026, 1, 1, 12);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

void main() {
  test('two-star hold unlocks after three full seconds', () async {
    final gate = AdultGateController();
    gate.startHold();
    expect(gate.unlocked, isFalse);
    await Future<void>.delayed(
        const Duration(seconds: 3, milliseconds: 100));
    expect(gate.unlocked, isTrue);
    gate.dispose();
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('releasing early does not unlock', () {
    final clock = _FakeClock();
    final gate = AdultGateController(clock: clock.call);
    gate.startHold();
    clock.advance(const Duration(seconds: 1));
    gate.cancelHold();
    expect(gate.unlocked, isFalse);
    gate.dispose();
  });

  test('hold progress reports 0..1 against the 3 second target', () {
    final clock = _FakeClock();
    final gate = AdultGateController(clock: clock.call);
    gate.startHold();
    clock.advance(const Duration(milliseconds: 1500));
    expect(gate.holdProgress, closeTo(0.5, 0.05));
    gate.dispose();
  });

  test('accessible question accepts the correct sum', () {
    final gate = AdultGateController(random: math.Random(7));
    final parts = RegExp(r'What is (\d+) \+ (\d+)\?')
        .firstMatch(gate.question)!;
    final answer =
        int.parse(parts.group(1)!) + int.parse(parts.group(2)!);
    expect(gate.submitAnswer('$answer'), isTrue);
    expect(gate.unlocked, isTrue);
    gate.dispose();
  });

  test('wrong answers rotate the question and count as failures', () {
    final gate = AdultGateController(random: math.Random(7));
    expect(gate.submitAnswer('1'), isFalse);
    expect(gate.failures, 1);
    expect(gate.unlocked, isFalse);
    gate.dispose();
  });

  test('three failures start a 30 second cooldown that then expires', () {
    final clock = _FakeClock();
    final gate = AdultGateController(clock: clock.call, random: math.Random(3));
    for (var i = 0; i < 3; i++) {
      gate.submitAnswer('0');
    }
    expect(gate.inCooldown, isTrue);
    expect(gate.cooldownRemaining.inSeconds, greaterThan(25));

    // While cooling down, both paths are blocked.
    expect(gate.submitAnswer('999'), isFalse);
    gate.startHold();
    expect(gate.holdProgress, 0);

    clock.advance(const Duration(seconds: 31));
    expect(gate.inCooldown, isFalse);
    gate.dispose();
  });
}

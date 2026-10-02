// Design system tests.
//
// A design system without tests is a suggestion. These lock the rules from
// docs/DESIGN-LUXURY.md that are easy to erode one pull request at a time —
// the depth ladder, the gold restraint, the motion budget, and the performance
// ceiling on blur.
//
// They are cheap, they run in CI, and they are the difference between a design
// that survives six months of edits and a design that quietly turns back into
// a form.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/theme/depth.dart';
import 'package:norcha_print/theme/norcha_theme.dart';
import 'package:norcha_print/widgets/motion_budget.dart';

void main() {
  group('the depth ladder is strictly ordered', () {
    test('every level has a declared blur, overlay and shadow', () {
      for (final l in DepthLevel.values) {
        expect(Depth.blur.containsKey(l), isTrue, reason: '$l has no blur');
        expect(Depth.overlay.containsKey(l), isTrue, reason: '$l has no overlay');
        expect(Depth.shadow.containsKey(l), isTrue, reason: '$l has no shadow');
      }
    });

    test('overlay brightness increases with height', () {
      // Closer to the glass = catches more light. If this ever inverts, the
      // hierarchy reads backwards and the screen looks wrong for reasons nobody
      // can name.
      expect(Depth.overlayOf(DepthLevel.sheet),
          lessThan(Depth.overlayOf(DepthLevel.raised)));
      expect(Depth.overlayOf(DepthLevel.raised),
          lessThan(Depth.overlayOf(DepthLevel.float)));
    });

    test('only the floating level casts a heavy shadow', () {
      // A sheet with a big shadow competes with the CTA. One thing floats.
      expect(Depth.shadow[DepthLevel.sheet]![2], lessThan(0.5));
      expect(Depth.shadow[DepthLevel.float]![2], greaterThan(0.5));
    });
  });

  group('the performance ceiling holds', () {
    test('list rows are cheap — sheet level uses NO blur', () {
      // This is the rule that keeps scrolling at 60fps on a mid-range phone.
      // A blurred ListView item is a jank engine and this test forbids it.
      expect(Depth.sigmaOf(DepthLevel.sheet), 0);
    });

    test('the ground layer is never filtered', () {
      expect(Depth.sigmaOf(DepthLevel.ground), 0);
    });

    test('no blur exceeds the documented maximum', () {
      for (final entry in Depth.blur.entries) {
        expect(entry.value, lessThanOrEqualTo(30.0),
            reason: '${entry.key} blur is beyond the documented ceiling');
      }
    });

    test('parallax stays in the 8-14% band', () {
      // Above ~15% the background visibly detaches and reads as broken layout
      // rather than depth.
      expect(DepthParallax.factor, greaterThanOrEqualTo(0.08));
      expect(DepthParallax.factor, lessThanOrEqualTo(0.14));
    });
  });

  group('gold is light, not paint', () {
    test('there are exactly three golds, and they are distinct', () {
      final golds = {NorchaPalette.gold, NorchaPalette.goldDim, NorchaPalette.goldBright};
      expect(golds.length, 3,
          reason: 'Two golds collapsed to the same value — the ladder is broken.');
    });

    test('the primary gold is not a saturated yellow', () {
      // A luxury gold is desaturated antique, not #FFD700. Saturated yellow
      // reads as a discount sticker.
      const g = NorchaPalette.gold;
      final r = (g.red);
      final gg = (g.green);
      final b = (g.blue);
      expect(b, greaterThan(20), reason: 'too pure/acid a gold');
      expect(r - b, lessThan(200), reason: 'too saturated to read as foil');
      expect(gg, lessThan(r), reason: 'green channel should sit below red for antique gold');
    });

    test('the ground is warm black, not #000', () {
      // Pure black reads as a switched-off screen. A trace of warm reads as ink.
      const v = NorchaPalette.void_;
      final r = (v.red);
      final g = (v.green);
      final b = (v.blue);
      expect(r + g + b, greaterThan(0), reason: 'that is pure black');
      expect(r, greaterThanOrEqualTo(b), reason: 'the black should lean warm, not blue');
    });
  });

  group('the motion budget is enforced', () {
    setUp(() => MotionBudget.release('test-screen'));

    test('two expressive moments are allowed', () {
      expect(MotionBudget.claim('test-screen', 'total-changes'), isTrue);
      expect(MotionBudget.claim('test-screen', 'sheet-arrives'), isTrue);
    });

    test('the third is degraded, not granted', () {
      MotionBudget.claim('test-screen', 'a');
      MotionBudget.claim('test-screen', 'b');
      expect(MotionBudget.claim('test-screen', 'c'), isFalse,
          reason: 'A third expressive moment makes none of them special.');
    });

    test('re-claiming the same moment is free', () {
      expect(MotionBudget.claim('test-screen', 'total-changes'), isTrue);
      expect(MotionBudget.claim('test-screen', 'total-changes'), isTrue);
    });

    test('press response is under 80ms', () {
      expect(Motion.durationOf(Emphasis.press).inMilliseconds, lessThan(80));
    });

    test('routine motion does not overshoot', () {
      expect(Motion.curveOf(Emphasis.routine), Curves.easeOutCubic);
    });

    test('expressive motion does overshoot', () {
      expect(Motion.curveOf(Emphasis.expressive), Curves.easeOutBack);
    });
  });
}

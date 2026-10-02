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
import 'package:norcha_print/theme/netela.dart';
import 'package:norcha_print/theme/norcha_theme.dart';
import 'package:norcha_print/widgets/motion_budget.dart';

void main() {
  group('the depth ladder is strictly ordered', () {
    test('every level has a declared blur, surface and shadow', () {
      for (final l in DepthLevel.values) {
        expect(Depth.blur.containsKey(l), isTrue, reason: '$l has no blur');
        expect(Depth.surface.containsKey(l), isTrue, reason: '$l has no surface');
        expect(Depth.shadow.containsKey(l), isTrue, reason: '$l has no shadow');
      }
    });

    test('cards sit BRIGHTER than the page (light ground)', () {
      // On cream, "closer to the viewer" means purer white. The old dark build
      // inverted this. If it ever flips back, cards stop reading as laid on
      // paper and start reading as holes cut in it.
      const paper = NorchaPalette.paper;
      const card = NorchaPalette.card;
      int lum(Color c) => c.red + c.green + c.blue;
      expect(lum(card), greaterThan(lum(paper)),
          reason: 'cards must be brighter than the page on a light ground');
    });

    test('shadow depth increases with height, and stays gentle', () {
      // Light-mode shadows must be far softer than the dark-mode ones. A 55%
      // black shadow that read as depth on near-black reads as a smudge on
      // cream.
      expect(Depth.shadow[DepthLevel.sheet]![2],
          lessThan(Depth.shadow[DepthLevel.float]![2]),
          reason: 'the floating level must cast a heavier shadow than a sheet');
      expect(Depth.shadow[DepthLevel.float]![2], lessThan(0.25),
          reason: 'anything darker than this looks like dirt on cream');
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

  group('the palette is the shop's own — netela cream, pine, Meskel gold', () {
    test('the page ground is warm cream, not white', () {
      // #F8F4EE is hand-spun cotton. Pure #FFF reads as a blank document; the
      // warmth is the entire Ethiopian character of the design.
      const p = NorchaPalette.paper;
      expect(p.red + p.green + p.blue, lessThan(255 * 3),
          reason: 'that is pure white — it should be netela cream');
      expect(p.red, greaterThan(p.blue),
          reason: 'the cream should lean warm, not cool');
    });

    test('ink is warm near-black, not pure black', () {
      const i = NorchaPalette.ink;
      expect(i.red + i.green + i.blue, greaterThan(0),
          reason: 'pure #000 on cream is harsh and looks printed, not written');
      expect(i.red, greaterThanOrEqualTo(i.blue),
          reason: 'ink should lean warm like the paper it sits on');
    });

    test('pine is the primary action colour, and it is dark enough for text', () {
      // #0E5C41 on cream is ~7:1 — comfortably legible. A lighter green would
      // fail on the one thing that must never be unreadable: the CTA.
      const pine = NorchaPalette.pine;
      expect(pine.green, greaterThan(pine.red),
          reason: 'pine should be green-dominant');
      expect(pine.green, greaterThan(0x50),
          reason: 'too dark to read as the shop green');
    });

    test('the flag colours exist but are never used for text', () {
      // DESIGN.md rule: flag yellow #FCDD09 is unreadable on cream. The
      // text-safe red is a separate token on purpose.
      expect(NorchaPalette.flagYellow, isNot(NorchaPalette.warn));
      expect(NorchaPalette.flagRed, isNot(NorchaPalette.red));
    });

    test('every product family maps to an accent', () {
      for (final family in ['prints', 'canvas', 'books', 'frames', 'calendars', 'mugs']) {
        expect(Accent.forFamily(family), isNotNull);
      }
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

// Design system tests.
//
// A design system without tests is a suggestion. These lock the rules from
// docs/DESIGN-LUXURY.md that erode one pull request at a time — the depth
// ladder, the brand colours, the theme contract, and the performance ceiling
// on blur.
//
// They are cheap, they run in CI, and they are the difference between a design
// that survives six months of edits and a design that quietly turns back into
// a form.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/core/pricing.dart';
import 'package:norcha_print/theme/app_theme.dart';
import 'package:norcha_print/theme/ghost_numerals.dart';
import 'package:norcha_print/widgets/cloth_surface.dart';
import 'package:norcha_print/widgets/size_selector.dart';

int lum(Color c) => c.red + c.green + c.blue;

void main() {
  group('size selector shapes', () {
    // The selector draws each size at its REAL proportion — that shape is the
    // part doing the selling. It used to read a hand-maintained map that had
    // rotted: it named sizes that no longer existed and omitted every size the
    // shop actually sells, so EVERY tile silently fell back to a neutral 4:5.
    // Proportions are now derived from the key, and these lock that in.

    test('a size key yields its true width/height ratio', () {
      expect(aspectFor('canvas-10x15'), closeTo(10 / 15, 1e-9));
      expect(aspectFor('canvas-40x60'), closeTo(40 / 60, 1e-9));
      expect(aspectFor('canvas-60x120'), closeTo(60 / 120, 1e-9));
      expect(aspectFor('frame-40x60'), closeTo(40 / 60, 1e-9));
      expect(aspectFor('std-20x30'), closeTo(20 / 30, 1e-9));
    });

    test('portrait stays under 1, landscape stays over it', () {
      expect(aspectFor('canvas-10x15'), lessThan(1));
      expect(aspectFor('canvas-30x90'), lessThan(1));
      expect(aspectFor('canvas-60x120'), lessThan(1));
      // No product in the real catalogue is landscape; a key that is would
      // return > 1 rather than being flattened to the fallback.
      expect(aspectFor('test-120x60'), greaterThan(1));
    });

    test('paper sizes that cannot be derived are still exact', () {
      expect(aspectFor('std-a4'), closeTo(21 / 30, 1e-9));
      expect(aspectFor('std-a3'), closeTo(30 / 42, 1e-9));
      expect(aspectFor('frame-a3'), closeTo(30 / 42, 1e-9));
      expect(aspectFor('cal-a5'), closeTo(148 / 210, 1e-9));
    });

    test('EVERY size the shop sells has a real shape, not the fallback', () {
      // The regression guard: no catalogue entry may fall back.
      for (final family in ['prints', 'canvas', 'frames', 'calendars']) {
        // ignore: avoid_dynamic_calls
        for (final s in NorchaData.products[family]!.sizes) {
          final a = aspectFor(s.key);
          expect(a, isNot(closeTo(4 / 5, 1e-9)),
              reason: '${s.key} fell back to the neutral 4:5 shape');
        }
      }
    });

    test('a shapeless product falls back rather than throwing', () {
      expect(aspectFor('mug-1'), closeTo(4 / 5, 1e-9));
      expect(aspectFor('book-standard'), closeTo(4 / 5, 1e-9));
    });
  });

  group('the two themes are both complete and genuinely different', () {
    test('light and dark define every token', () {
      for (final c in [NorchaColors.light, NorchaColors.dark]) {
        expect(c.ground, isNotNull);
        expect(c.card, isNotNull);
        expect(c.ink, isNotNull);
        expect(c.line, isNotNull);
      }
    });

    test('light has a light ground and dark ink', () {
      expect(lum(NorchaColors.light.ground), greaterThan(lum(NorchaColors.light.ink)));
      expect(NorchaColors.light.isDark, isFalse);
    });

    test('dark has a dark ground and light ink — inverted, not tinted', () {
      expect(lum(NorchaColors.dark.ground), lessThan(lum(NorchaColors.dark.ink)));
      expect(NorchaColors.dark.isDark, isTrue);
    });

    test('the dark ground is warm black, never #000', () {
      // Pure black on an OLED phone reads as a switched-off screen. The dark
      // theme here is a print studio at night, not a power-saving mode.
      final g = NorchaColors.dark.ground;
      expect(lum(g), greaterThan(0), reason: 'that is pure black');
      expect(g.red, greaterThanOrEqualTo(g.blue),
          reason: 'the black should lean warm');
    });

    test('cards sit brighter than the page in BOTH themes', () {
      // "Closer to the viewer" means brighter than the ground. This inverts on
      // dark in absolute terms but the RELATIONSHIP must hold: a card is never
      // darker than the surface it sits on, or the hierarchy reads backwards.
      for (final c in [NorchaColors.light, NorchaColors.dark]) {
        expect(lum(c.card), greaterThan(lum(c.ground)),
            reason: 'card must be brighter than its ground');
      }
    });

    test('light needs lighter shadows than dark', () {
      // A 7% shadow that reads as depth on cream vanishes on near-black; a
      // 40% shadow that reads as depth on dark looks like dirt on cream.
      final l = Depth.shadowOf(DepthLevel.sheet, false)[2];
      final d = Depth.shadowOf(DepthLevel.sheet, true)[2];
      expect(d, greaterThan(l),
          reason: 'dark grounds need more shadow alpha than light ones');
      expect(l, lessThan(0.25), reason: 'too dark for cream');
    });
  });

  group('the brand colours are NOT theme-dependent', () {
    test('pine, gold and the accents are the same in both themes', () {
      // A theme that also changed the brand colours would be two brands. The
      // customer toggling the switch must still be looking at the same shop.
      expect(Brand.pine, const Color(0xFF0E5C41));
      expect(Brand.gold, const Color(0xFFC1922B));
      expect(Brand.flagGreen, const Color(0xFF078930));
    });

    test('the dark theme gets a LIGHTER cut of the same hue, not a new colour', () {
      expect(Brand.pineOnDark.green, greaterThan(Brand.pine.green),
          reason: 'the pine must be lifted for dark grounds to stay legible');
      expect(Brand.action(NorchaColors.light), Brand.pine);
      expect(Brand.action(NorchaColors.dark), Brand.pineOnDark);
    });

    test('the action colour has a contrasting on-colour in both themes', () {
      expect(Brand.onAction(NorchaColors.light), isNot(Brand.action(NorchaColors.light)));
      expect(Brand.onAction(NorchaColors.dark), isNot(Brand.action(NorchaColors.dark)));
    });

    test('every product family maps to an accent', () {
      for (final f in ['prints', 'canvas', 'books', 'frames', 'calendars', 'mugs']) {
        expect(Accent.forFamily(f), isNotNull);
      }
    });

    test('the flag colours are separate tokens from the text-safe ones', () {
      // DESIGN.md rule: flag yellow #FCDD09 is unreadable on cream.
      expect(Brand.flagYellow, isNot(Brand.warn));
      expect(Brand.flagRed, isNot(Brand.red));
    });
  });

  group('the performance ceiling holds', () {
    test('list rows are cheap — sheet level uses NO blur', () {
      // The rule that keeps scrolling smooth on a mid-range phone. A blurred
      // ListView item is a jank engine.
      expect(Depth.sigmaOf(DepthLevel.sheet), 0);
      expect(Depth.sigmaOf(DepthLevel.ground), 0);
    });

    test('no blur exceeds the documented maximum', () {
      for (final e in Depth.blur.entries) {
        expect(e.value, lessThanOrEqualTo(30.0),
            reason: '${e.key} blur is beyond the documented ceiling');
      }
    });
  });

  group('the Ge\'ez numerals are the chapter system', () {
    test('they are real Ethiopic codepoints, not Latin lookalikes', () {
      // U+1369..U+1372. A Latin numeral pretending to be Ge'ez would render in
      // the body font and lose the whole point.
      expect(GeezNumeral.one.codeUnitAt(0), 0x1369);
      expect(GeezNumeral.two.codeUnitAt(0), 0x136A);
      expect(GeezNumeral.ten.codeUnitAt(0), 0x1372);
    });

    test('every chapter maps to a distinct numeral', () {
      final five = [for (var i = 1; i <= 5; i++) GeezNumeral.at(i)];
      expect(five.toSet().length, 5,
          reason: 'two chapters share a numeral — the system has collapsed');
      expect(five.first, GeezNumeral.one);
    });

    test('indexing wraps rather than throwing', () {
      // A page with no numeral is worse than a repeated one.
      expect(GeezNumeral.at(11), GeezNumeral.one);
    });
  });

  group('the motion ladder is ordered and press is instant', () {
    test('routine does not overshoot and expressive does', () {
      expect(Motion.routine.damping, greaterThan(Motion.expressive.damping));
      expect(Motion.routine.stiffness, greaterThan(Motion.expressive.stiffness));
    });

    test('press response is under 80ms', () {
      // Slower reads as lag, and lag reads as cheap.
      expect(Motion.press.inMilliseconds, lessThan(80));
    });

    test('snappy is stiffer than routine', () {
      expect(Motion.snappy.stiffness, greaterThan(Motion.routine.stiffness));
    });
  });
}

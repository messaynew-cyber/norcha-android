// PARITY TEST — prices.
//
// ⚠️ THIS TEST NO LONGER DIFFS AGAINST THE WEBSITE.
//
// It used to. The website's js/norcha-data.js was the price reference and the
// expected values here were its literal output. On 2026-10-07 the shop supplied
// its OWN sheet (Price_List_1.xlsx, the "BOARD" column) plus Price List 2, and
// every number the website carried turned out to be a placeholder. The app no
// longer ports the site; the site now has to catch up to the app.
//
// So the expected values below come from the SHOP'S SHEET, not from any code.
// They are written as literals on purpose: if the data in pricing.dart drifts
// by one birr, this fails. Re-generating them from `NorchaData` would make this
// test agree with itself and prove nothing — see the note in
// delivery_parity_test.dart about how a Monday Easter survived in production.

import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/core/pricing.dart';

void main() {
  group('the shop sheet — canvas ("BOARD")', () {
    // 🔴 SELL prices. Price_List_1.xlsx holds ORIGINAL (supplier) prices, so
    // each one is ×1.40 (40% margin — the shop outsources all printing).
    // Written as the FINAL sell figure, with the original in the comment, so a
    // future reader can see the markup happened exactly once.
    const sheet = {
      'canvas-10x15': 420,   // 300 × 1.40
      'canvas-15x20': 700,   // 500 × 1.40
      'canvas-20x30': 1050,  // 750 × 1.40
      'canvas-30x46': 1820,  // 1300 × 1.40
      'canvas-30x60': 2240,  // 1600 × 1.40
      'canvas-30x90': 2660,  // 1900 × 1.40
      'canvas-40x60': 2660,  // 1900 × 1.40
      'canvas-50x80': 3500,  // 2500 × 1.40
      'canvas-60x90': 3780,  // 2700 × 1.40
      'canvas-60x120': 6440, // 4600 × 1.40
      // ⚠️ UNRESOLVED — Price List 2, already marked up, so NOT multiplied.
      // Breaks the ladder: same price as 50×80 (4,000 cm²) and 2,940 cheaper
      // than 60×120 (7,200 cm²). Asserted as supplied so it fails loudly when
      // the shop corrects it.
      'canvas-80x120': 3500,
    };

    test('every sheet size exists at the sheet price', () {
      sheet.forEach((key, price) {
        expect(NorchaData.priceOf('canvas', key), price, reason: key);
      });
    });

    test('canvas has exactly the sizes the sheet lists', () {
      final sizes = NorchaData.products['canvas']!.sizes;
      expect(sizes.length, sheet.length);
      for (final s in sizes) {
        expect(sheet.containsKey(s.key), isTrue,
            reason: '${s.key} is not on the shop sheet');
      }
    });

    test('the markup was applied once — no size is still at its original', () {
      // Guards the exact bug this file shipped with: raw sheet prices going
      // out at 40% below the shop's margin.
      const originals = {
        'canvas-10x15': 300, 'canvas-15x20': 500, 'canvas-20x30': 750,
        'canvas-30x46': 1300, 'canvas-30x60': 1600, 'canvas-30x90': 1900,
        'canvas-40x60': 1900, 'canvas-50x80': 2500, 'canvas-60x90': 2700,
        'canvas-60x120': 4600,
      };
      originals.forEach((key, original) {
        expect(NorchaData.priceOf('canvas', key), (original * 1.4).round(),
            reason: '$key must be sold at 40% over its original');
        expect(NorchaData.priceOf('canvas', key), isNot(original),
            reason: '$key is still at the ORIGINAL price — markup missing');
      });
    });

    test('45 x 60 is absent — the sheet has a dash, not a price', () {
      expect(NorchaData.products['canvas']!.sizes
          .any((s) => s.key.contains('45x60')), isFalse);
    });
  });

  group('the shop sheet — other products', () {
    test('frames are black wood + glass at the shop prices', () {
      expect(NorchaData.priceOf('frames', 'frame-a4'), 2200);
      expect(NorchaData.priceOf('frames', 'frame-a3'), 2800);
      expect(NorchaData.priceOf('frames', 'frame-40x60'), 5600);
      // ⚠️ flagged as a likely typo in pricing.dart, but asserted as supplied
      // so the number can never drift silently. If the shop corrects it,
      // change it in BOTH places and let this test tell you.
      expect(NorchaData.priceOf('frames', 'frame-80x120'), 28000);
    });

    test('calendar is A5 only, at 1,680', () {
      final cal = NorchaData.products['calendars']!.sizes;
      expect(cal.length, 1);
      expect(cal.single.key, 'cal-a5');
      expect(cal.single.price, 1680);
    });

    test('photo book is a single price, 1,820', () {
      final b = NorchaData.products['books']!.sizes;
      expect(b.length, 1);
      expect(b.single.price, 1820);
    });

    test('photo mug is a single price, 1,120', () {
      final m = NorchaData.products['mugs']!.sizes;
      expect(m.length, 1);
      expect(m.single.price, 1120);
    });
  });

  group('prints are still PLACEHOLDERS — do not ship them', () {
    // 🔴 The shop has never supplied paper-print prices. The old placeholders
    // are deliberately retained because 'prints' is the default family in
    // quote_page.dart and upload_page.dart; deleting the family crashes both.
    // This test exists so the placeholder situation stays VISIBLE.
    test('the family exists (so the default selection resolves)', () {
      expect(NorchaData.products.containsKey('prints'), isTrue);
    });

    test('it still carries the unconfirmed placeholder values', () {
      expect(NorchaData.priceOf('prints', 'std-10x15'), 25);
      expect(NorchaData.priceOf('prints', 'std-a3'), 280);
    });
  });

  group('priceOf', () {
    test('every size key resolves', () {
      for (final p in NorchaData.products.values) {
        for (final s in p.sizes) {
          expect(NorchaData.priceOf(p.family, s.key), s.price,
              reason: '${p.family}/${s.key}');
        }
      }
    });

    test('unknown family or key returns null, not zero', () {
      expect(NorchaData.priceOf('nope', 'std-a4'), isNull);
      expect(NorchaData.priceOf('prints', 'nope'), isNull);
      expect(NorchaData.priceOf('canvas', 'canvas-45x60'), isNull);
    });
  });

  group('tierFor — the ladder is unchanged', () {
    test('boundaries are inclusive lower bounds', () {
      expect(NorchaData.tierFor('prints', 1).pct, 0);
      expect(NorchaData.tierFor('prints', 9).pct, 0);
      expect(NorchaData.tierFor('prints', 10).pct, 10);
      expect(NorchaData.tierFor('prints', 49).pct, 10);
      expect(NorchaData.tierFor('prints', 50).pct, 20);
      expect(NorchaData.tierFor('prints', 99).pct, 20);
      expect(NorchaData.tierFor('prints', 100).pct, 35);
      expect(NorchaData.tierFor('prints', 499).pct, 35);
      expect(NorchaData.tierFor('prints', 500).pct, 50);
    });
  });

  group('quote — real shop prices end to end', () {
    test('canvas 40x60 at qty 1 carries no discount', () {
      final q = NorchaData.quote('canvas', 'canvas-40x60', 1)!;
      expect(q.unit, 1900);
      expect(q.gross, 1900);
      expect(q.pct, 0);
      expect(q.total, 1900);
    });

    test('two canvases take the wall ladder 10%', () {
      final q = NorchaData.quote('canvas', 'canvas-10x15', 2)!;
      expect(q.unit, 300);
      expect(q.gross, 600);
      expect(q.pct, 10);
      expect(q.discount, 60);
      expect(q.total, 540);
    });

    test('a framed print is a wall item too', () {
      final q = NorchaData.quote('frames', 'frame-a4', 2)!;
      expect(q.unit, 2200);
      expect(q.gross, 4400);
      expect(q.pct, 10);
      expect(q.total, 3960);
    });

    test('mugs take the gifts ladder now that the pack sizes are gone', () {
      // OLD BUG: mugs had sizes 1/2/4 at 350/650/1200 AND a percentage ladder,
      // so "2 mugs" was 650 via the pack and 644 via 350x2 -8%. Two prices for
      // one order. With one size there is nothing to collide with.
      final one = NorchaData.quote('mugs', 'mug-1', 1)!;
      expect(one.total, 1120);
      expect(one.pct, 0);

      final two = NorchaData.quote('mugs', 'mug-1', 2)!;
      expect(two.gross, 2240);
      expect(two.pct, 8);
      expect(two.total, 2061);
    });

    test('unknown input returns null, never a zero-birr quote', () {
      expect(NorchaData.quote('prints', 'nope', 1), isNull);
      expect(NorchaData.quote('nope', 'std-a4', 1), isNull);
    });
  });
}

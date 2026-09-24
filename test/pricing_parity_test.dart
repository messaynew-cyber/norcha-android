// PARITY TEST — the most important test in this project.
//
// The app and the website must never disagree about a price. "Two prices for
// one order" already happened once on the web (the mugs double-discount bug),
// and in an app nobody can hotfix, it would be worse.
//
// EXPECTED values below are the OUTPUT OF THE JAVASCRIPT, computed from
// feven-prints-v2/js/norcha-data.js @ fcf4b70 and pasted here as literals.
// If the Dart port drifts by one birr, this fails.

import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/core/pricing.dart';

void main() {
  group('priceOf', () {
    test('every size key resolves', () {
      var count = 0;
      for (final p in NorchaData.products.values) {
        for (final s in p.sizes) {
          expect(NorchaData.priceOf(p.family, s.key), s.price,
              reason: '${p.family}/${s.key}');
          count++;
        }
      }
      expect(count, 22, reason: 'the site advertises 22 priced sizes');
    });

    test('unknown family or key returns null, not zero', () {
      expect(NorchaData.priceOf('nope', 'std-a4'), isNull);
      expect(NorchaData.priceOf('prints', 'nope'), isNull);
    });
  });

  group('tierFor — exact boundaries', () {
    test('photos ladder', () {
      expect(NorchaData.tierFor('prints', 1).pct, 0);
      expect(NorchaData.tierFor('prints', 9).pct, 0);
      expect(NorchaData.tierFor('prints', 10).pct, 10);
      expect(NorchaData.tierFor('prints', 49).pct, 10);
      expect(NorchaData.tierFor('prints', 50).pct, 20);
      expect(NorchaData.tierFor('prints', 99).pct, 20);
      expect(NorchaData.tierFor('prints', 100).pct, 35);
      expect(NorchaData.tierFor('prints', 499).pct, 35);
      expect(NorchaData.tierFor('prints', 500).pct, 50);
      expect(NorchaData.tierFor('prints', 5000).pct, 50);
    });

    test('wall ladder', () {
      expect(NorchaData.tierFor('canvas', 1).pct, 0);
      expect(NorchaData.tierFor('canvas', 2).pct, 10);
      expect(NorchaData.tierFor('canvas', 5).pct, 15);
      expect(NorchaData.tierFor('canvas', 10).pct, 22);
    });

    test('books ladder', () {
      expect(NorchaData.tierFor('books', 1).pct, 0);
      expect(NorchaData.tierFor('books', 2).pct, 8);
      expect(NorchaData.tierFor('books', 5).pct, 15);
    });

    test('mugs are FLAT — pack pricing only, never double-discounted', () {
      for (final q in [1, 2, 4, 8, 100]) {
        expect(NorchaData.tierFor('mugs', q).pct, 0,
            reason: 'mugs must never receive a percentage discount');
      }
    });

    test('unknown family falls back to no discount', () {
      expect(NorchaData.tierFor('nope', 100).pct, 0);
    });
  });

  group('quote — values mirrored from the JavaScript', () {
    test('prints, no discount', () {
      final q = NorchaData.quote('prints', 'std-10x15', 1)!;
      expect(q.unit, 25);
      expect(q.gross, 25);
      expect(q.pct, 0);
      expect(q.discount, 0);
      expect(q.total, 25);
      expect(q.lead, 0);
    });

    test('prints, 100 @ A4 → 35% off', () {
      final q = NorchaData.quote('prints', 'std-a4', 100)!;
      expect(q.unit, 150);
      expect(q.gross, 15000);
      expect(q.pct, 35);
      expect(q.discount, 5250);
      expect(q.total, 9750);
    });

    test('prints, 500 @ 10x15 → 50% off', () {
      final q = NorchaData.quote('prints', 'std-10x15', 500)!;
      expect(q.gross, 12500);
      expect(q.discount, 6250);
      expect(q.total, 6250);
    });

    test('canvas, 2 @ 30x40 → 10% off', () {
      final q = NorchaData.quote('canvas', 'canvas-30x40', 2)!;
      expect(q.gross, 1900);
      expect(q.discount, 190);
      expect(q.total, 1710);
      expect(q.lead, 1);
    });

    test('books, 2 @ 20x20 → 8% off, 2-day lead', () {
      final q = NorchaData.quote('books', 'book-20x20-20', 2)!;
      expect(q.gross, 3600);
      expect(q.discount, 288);
      expect(q.total, 3312);
      expect(q.lead, 2);
    });

    // THE REGRESSION. On the web, "2 mugs" once quoted two different prices:
    // 650 via the 2-pack and 644 via the gifts ladder (350×2 − 8%).
    test('REGRESSION: 2 mugs = 650 exactly. Not 644. Not anything else.', () {
      final q = NorchaData.quote('mugs', 'mug-2', 1)!;
      expect(q.unit, 650);
      expect(q.gross, 650);
      expect(q.pct, 0);
      expect(q.discount, 0);
      expect(q.total, 650);
    });

    test('REGRESSION: 4 mugs = 1200 exactly', () {
      final q = NorchaData.quote('mugs', 'mug-4', 1)!;
      expect(q.total, 1200);
    });

    test('REGRESSION: 2 × single mug is 700 and gets no discount either', () {
      final q = NorchaData.quote('mugs', 'mug-1', 2)!;
      expect(q.gross, 700);
      expect(q.pct, 0);
      expect(q.total, 700);
    });

    test('unknown input returns null, never a zero-birr quote', () {
      expect(NorchaData.quote('prints', 'nope', 1), isNull);
      expect(NorchaData.quote('nope', 'std-a4', 1), isNull);
    });
  });

  group('money formatting', () {
    test('thousands separators, no decimals', () {
      expect(NorchaData.money(0), '0 ETB');
      expect(NorchaData.money(25), '25 ETB');
      expect(NorchaData.money(999), '999 ETB');
      expect(NorchaData.money(1000), '1,000 ETB');
      expect(NorchaData.money(12500), '12,500 ETB');
      expect(NorchaData.money(1234567), '1,234,567 ETB');
    });

    test('rounds like the site does', () {
      expect(NorchaData.money(644.4), '644 ETB');
      expect(NorchaData.money(644.5), '645 ETB');
    });
  });

  group('lead times', () {
    test('pessimistic numbers are preserved', () {
      expect(NorchaData.products['prints']!.lead, 0); // same day
      expect(NorchaData.products['canvas']!.lead, 1);
      expect(NorchaData.products['books']!.lead, 2); // "2-3 days" → use 2
      expect(NorchaData.products['frames']!.lead, 1);
      expect(NorchaData.products['calendars']!.lead, 1);
      expect(NorchaData.products['mugs']!.lead, 0);
    });
  });

  group('shop facts', () {
    test('the phone number and WhatsApp form are the confirmed ones', () {
      expect(Shop.phone, '+251 911 729 779');
      expect(Shop.wa, '251911729779');
      expect(Shop.cutoffHour, 16);
    });

    test('prices are still flagged temporary until Feven confirms', () {
      expect(Shop.pricesAreTemporary, isTrue,
          reason: 'flip to false ONLY when Feven confirms the sheet');
    });
  });
}

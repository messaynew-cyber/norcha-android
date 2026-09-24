// PARITY TEST — the holiday engine must agree with the website.
//
// The JavaScript in feven-prints-v2/js/norcha-holidays.js is the reference.
// Expected values below are ITS output, held as literals. If the Dart drifts,
// this fails — and a wrong deadline means a customer orders too late for
// Meskel and the shop cannot deliver. That is the worst bug this app can have:
// it is not a wrong pixel, it is a broken promise.

import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/core/holidays.dart';

void main() {
  group('fasika — Orthodox Easter, computed not hardcoded', () {
    // Known Gregorian dates for Orthodox Easter. These are EXTERNAL facts,
    // not the output of our own code — which is exactly why they caught the
    // Julian->Gregorian offset bug on the first CI run.
    test('known years — verified against published Orthodox calendars', () {
      // 12 Apr 2026 is confirmed: Orthodox Easter 2026 is 12 April in every
      // published calendar. The app previously produced 6 Apr (a Monday).
      expect(NorchaHolidays.fasika(2026), DateTime(2026, 4, 12));
      expect(NorchaHolidays.fasika(2027), DateTime(2027, 5, 2));
      expect(NorchaHolidays.fasika(2025), DateTime(2025, 4, 20));
    });

    test('always lands on a Sunday — THIS TEST FOUND THE BUG', () {
      // Easter is a Sunday in every tradition. An Easter on a Monday is
      // arithmetically impossible, which is how this assertion caught the
      // Julian->Gregorian offset being 7 instead of 13.
      for (var y = 2025; y <= 2050; y++) {
        expect(NorchaHolidays.fasika(y).weekday, DateTime.sunday,
            reason: 'Fasika $y must be a Sunday, got '
                '${NorchaHolidays.fasika(y)}');
      }
    });

    test('always between late March and early June', () {
      for (var y = 2025; y <= 2035; y++) {
        final f = NorchaHolidays.fasika(y);
        expect(f.month, inInclusiveRange(3, 6));
      }
    });
  });

  group('orderByFor — steps back over Sundays, never counting them', () {
    test('lead time lands on a working day', () {
      // 3 working days before an occasion must never land on a Sunday,
      // because the shop is shut and the customer could not order.
      for (var d = 1; d <= 28; d++) {
        final occasion = DateTime(2026, 9, d);
        final orderBy = NorchaHolidays.orderByFor(occasion, 3);
        expect(orderBy.weekday, isNot(DateTime.sunday),
            reason: 'order-by for $occasion landed on a Sunday');
      }
    });

    test('never returns a date on or after the occasion', () {
      for (var d = 1; d <= 28; d++) {
        final occasion = DateTime(2026, 9, d);
        final orderBy = NorchaHolidays.orderByFor(occasion, 3);
        expect(orderBy.isBefore(occasion), isTrue);
      }
    });

    test('stepping back always moves strictly backwards', () {
      final o = DateTime(2026, 9, 27); // Meskel
      final orderBy = NorchaHolidays.orderByFor(o, 3);
      expect(orderBy.isBefore(o), isTrue);
      // and it is at most lead + 2 days back (worst case two Sundays in the run)
      expect(o.difference(orderBy).inDays, lessThanOrEqualTo(5));
    });
  });

  group('upcoming — the ladder', () {
    final from = DateTime(2026, 9, 1); // 26 days before Meskel

    test('Enkutatash is next on 1 Sep 2026, not Meskel', () {
      // I originally expected Meskel because it is the famous one. Wrong:
      // Enkutatash is 11 Sep and Meskel is 27 Sep, so Enkutatash is nearer.
      // The engine was right and the expectation was folklore.
      final list = NorchaHolidays.upcoming(from, horizonDays: 90);
      expect(list, isNotEmpty);
      expect(list.first.id, 'enkutatash');
      expect(list.first.date, DateTime(2026, 9, 11));
      expect(list.first.days, 10);
      // Meskel is still there, two places later.
      expect(list.any((h) => h.id == 'meskel'), isTrue);
    });

    test('results are sorted soonest first', () {
      final list = NorchaHolidays.upcoming(from, horizonDays: 400);
      for (var i = 1; i < list.length; i++) {
        expect(list[i].days >= list[i - 1].days, isTrue,
            reason: 'list must be ascending by days');
      }
    });

    test('nothing already past is returned', () {
      final list = NorchaHolidays.upcoming(from, horizonDays: 400);
      for (final h in list) {
        expect(h.days, greaterThanOrEqualTo(0));
      }
    });

    test('horizon filters', () {
      final near = NorchaHolidays.upcoming(from, horizonDays: 30);
      final far = NorchaHolidays.upcoming(from, horizonDays: 400);
      expect(near.length, lessThan(far.length));
      for (final h in near) {
        expect(h.days, lessThanOrEqualTo(30));
      }
    });

    test('every occasion carries both languages', () {
      final list = NorchaHolidays.upcoming(from, horizonDays: 400);
      for (final h in list) {
        expect(h.en, isNotEmpty);
        expect(h.am, isNotEmpty, reason: '${h.id} is missing Amharic');
      }
    });
  });

  group('current — deliberately returns null', () {
    test('null when nothing is within the horizon', () {
      // 1 March: next fixed occasion is Mother's Day (10 May) at 70 days, and
      // Fasika 2027 is far. With a 30-day horizon nothing should show.
      final c = NorchaHolidays.current(DateTime(2027, 3, 1), horizonDays: 30);
      expect(c, isNull, reason: 'an empty horizon must produce NO banner');
    });

    test('the nearest one wins', () {
      final c = NorchaHolidays.current(DateTime(2026, 9, 1));
      expect(c, isNotNull);
      expect(c!.id, 'enkutatash');
    });
  });

  group('message — four honest cases, including the one that admits it', () {
    Occasion at(int daysToOrder) => Occasion(
          id: 'meskel',
          en: 'Meskel',
          am: 'መስቀል',
          date: DateTime(2026, 9, 27),
          days: 26,
          orderBy: DateTime(2026, 9, 24),
          daysToOrder: daysToOrder,
        );

    test('days > 1 counts down', () {
      final m = NorchaHolidays.message(at(24), 'en');
      expect(m.message, 'Meskel: order within 24 days');
    });

    test('the horizon default is 75 days, matching the site', () {
      expect(NorchaHolidays.defaultHorizon, 75);
    });

    test('days == 1 says tomorrow', () {
      final m = NorchaHolidays.message(at(1), 'en');
      expect(m.message, 'Meskel: last day to order is tomorrow');
      expect(m.sub, contains('photo books'));
    });

    test('days == 0 says today, and asks for a message', () {
      final m = NorchaHolidays.message(at(0), 'en');
      expect(m.message, contains('Today is the last day'));
      expect(m.sub, contains('before we close'));
    });

    test('NEGATIVE days admits the promise is broken — never invents urgency', () {
      final m = NorchaHolidays.message(at(-1), 'en');
      expect(m.message, contains('no longer guaranteed'));
      expect(m.sub, contains('honestly'),
          reason: 'the overdue case must invite a conversation, not a claim');
    });

    test('Amharic is a real translation, not a fallback', () {
      final m = NorchaHolidays.message(at(24), 'am');
      expect(m.message, contains('መስቀል'));
      expect(m.message, isNot(contains('Meskel')));
    });
  });

  group('fmt', () {
    test('reads like the site prints it', () {
      expect(NorchaHolidays.fmt(DateTime(2026, 9, 27), 'en'), 'Sunday 27 Sep');
      expect(NorchaHolidays.fmt(DateTime(2026, 1, 7), 'en'), 'Wednesday 7 Jan');
    });

    test('Amharic day and month names', () {
      // 27 September 2026 is a Sunday — the Amharic for Sunday is እሑድ,
      // and September is ሴፕቴ.
      final f = NorchaHolidays.fmt(DateTime(2026, 9, 27), 'am');
      expect(f, 'እሑድ 27 ሴፕቴ');
    });
  });

  group('catalogue facts', () {
    test('lead time is the pessimistic one', () {
      expect(NorchaHolidays.maxLead, 3);
    });

    test('seven occasions are tracked, Fasika included', () {
      expect(NorchaHolidays.fixed.length, 6);
      final list = NorchaHolidays.upcoming(DateTime(2026, 1, 1), horizonDays: 400);
      expect(list.any((h) => h.id == 'fasika'), isTrue);
      expect(list.any((h) => h.id == 'meskel'), isTrue);
      expect(list.any((h) => h.id == 'genna'), isTrue);
      expect(list.any((h) => h.id == 'timket'), isTrue);
    });
  });
}

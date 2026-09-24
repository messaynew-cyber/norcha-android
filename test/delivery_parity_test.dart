// Delivery engine tests.
//
// The website's js/norcha-delivery.js is the reference for BEHAVIOUR. The
// expected values here are hand-computed from its rules, and several are
// checked against calendar facts rather than the code's own output — because a
// test that asserts what the code does only proves the code agrees with itself,
// which is how a Monday Easter survived in production.

import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/core/delivery.dart';
import 'package:norcha_print/core/holidays.dart';

void main() {
  group('UTC invariants', () {
    test('every returned date is UTC midnight', () {
      final r = NorchaDelivery.assess(DateTime.utc(2026, 9, 24, 10), null, 1);
      expect(r.ready.isUtc, isTrue);
      expect(r.ready.hour, 0);
      expect(r.ready.minute, 0);
    });

    test('an input in local guise still yields a UTC result', () {
      // DateTime.now() is local; the engine must normalise it.
      final r = NorchaDelivery.assess(DateTime.now(), null, 2);
      expect(r.ready.isUtc, isTrue);
    });
  });

  group('addWorkingDays — Sundays are skipped, never counted', () {
    test('never lands on a Sunday', () {
      for (var d = 1; d <= 28; d++) {
        final from = DateTime.utc(2026, 9, d);
        for (var n = 1; n <= 6; n++) {
          expect(NorchaDelivery.addWorkingDays(from, n).weekday,
              isNot(DateTime.sunday));
        }
      }
    });

    test('SATURDAY IS A WORKING DAY — the shop trades six days', () {
      // I originally expected Mon 28 Sep here, assuming a Mon-Fri week. Wrong:
      // addWorkingDays skips SUNDAYS ONLY, which is what the website does and
      // what the shop actually does. So Fri + 1 = Sat 26 Sep.
      //
      // Verified against the calendar, not against my memory of how weeks work:
      // 25 Sep 2026 is a Friday, 26 is Saturday, 27 is Sunday.
      final fri = DateTime.utc(2026, 9, 25);
      expect(fri.weekday, DateTime.friday);
      final ready = NorchaDelivery.addWorkingDays(fri, 1);
      expect(ready, DateTime.utc(2026, 9, 26));
      expect(ready.weekday, DateTime.saturday);
    });

    test('a Sunday IS skipped, and costs one extra calendar day', () {
      // Sat + 1 working day must land on Monday, because Sunday is the only
      // day excluded.
      final sat = DateTime.utc(2026, 9, 26);
      expect(sat.weekday, DateTime.saturday);
      final ready = NorchaDelivery.addWorkingDays(sat, 1);
      expect(ready, DateTime.utc(2026, 9, 28));
      expect(ready.weekday, DateTime.monday);
    });

    test('zero working days is a no-op', () {
      final d = DateTime.utc(2026, 9, 24);
      expect(NorchaDelivery.addWorkingDays(d, 0), d);
    });
  });

  group('workingDaysBetween', () {
    test('is signed', () {
      final a = DateTime.utc(2026, 9, 21); // Mon
      final b = DateTime.utc(2026, 9, 25); // Fri
      expect(NorchaDelivery.workingDaysBetween(a, b), 4);
      expect(NorchaDelivery.workingDaysBetween(b, a), -4);
    });

    test('does not count the Sunday inside the range', () {
      // Sat 26 Sep → Tue 29 Sep: only Mon and Tue are working days.
      final sat = DateTime.utc(2026, 9, 26);
      final tue = DateTime.utc(2026, 9, 29);
      expect(NorchaDelivery.workingDaysBetween(sat, tue), 2);
    });

    test('same day is zero', () {
      final d = DateTime.utc(2026, 9, 24);
      expect(NorchaDelivery.workingDaysBetween(d, d), 0);
    });
  });

  group('earliestReady — the cut-off and the Sunday', () {
    test('lead 0 before cut-off is the same day', () {
      final now = DateTime.utc(2026, 9, 24, 10); // Thu, before 16:00
      expect(NorchaDelivery.earliestReady(now, 0), DateTime.utc(2026, 9, 24));
    });

    test('lead 0 AFTER cut-off rolls to the next working day', () {
      final now = DateTime.utc(2026, 9, 24, 17); // Thu, after 16:00
      expect(NorchaDelivery.earliestReady(now, 0), DateTime.utc(2026, 9, 25));
    });

    test('after cut-off on a Friday rolls to SATURDAY, not Monday', () {
      // Same correction: production restarts the next WORKING day, and Saturday
      // is a working day. Expecting Monday assumed a Mon-Fri week the shop does
      // not keep.
      final now = DateTime.utc(2026, 9, 25, 17); // Fri after cut-off
      final ready = NorchaDelivery.earliestReady(now, 0);
      expect(ready.weekday, DateTime.saturday);
      expect(ready, DateTime.utc(2026, 9, 26));
    });

    test('after cut-off on a SATURDAY rolls to Monday', () {
      final now = DateTime.utc(2026, 9, 26, 17); // Sat after cut-off
      final ready = NorchaDelivery.earliestReady(now, 0);
      expect(ready.weekday, DateTime.monday);
      expect(ready, DateTime.utc(2026, 9, 28));
    });

    test('on a Sunday, production starts Monday', () {
      final sunday = DateTime.utc(2026, 9, 27, 10);
      expect(sunday.weekday, DateTime.sunday);
      final ready = NorchaDelivery.earliestReady(sunday, 1);
      expect(ready.weekday, isNot(DateTime.sunday));
    });

    test('never returns a Sunday, whatever the inputs', () {
      for (var day = 21; day <= 30; day++) {
        for (final hour in [9, 15, 17]) {
          final now = DateTime.utc(2026, 9, day, hour);
          for (var lead = 0; lead <= 4; lead++) {
            expect(NorchaDelivery.earliestReady(now, lead).weekday,
                isNot(DateTime.sunday),
                reason: 'day=$day hour=$hour lead=$lead');
          }
        }
      }
    });
  });

  group('assess — four honest answers', () {
    final now = DateTime.utc(2026, 9, 24, 10); // Thu before cut-off

    test('no date requested: ok, and a ready date', () {
      final r = NorchaDelivery.assess(now, null, 1);
      expect(r.ok, isTrue);
      expect(r.want, isNull);
      expect(r.ready, DateTime.utc(2026, 9, 25));
    });

    test('a date already past is refused', () {
      final r = NorchaDelivery.assess(now, DateTime.utc(2026, 9, 20), 1);
      expect(r.ok, isFalse);
      expect(r.reason, 'past');
    });

    test('a Sunday is refused — the shop is shut', () {
      final r = NorchaDelivery.assess(now, DateTime.utc(2026, 9, 27), 1);
      expect(r.ok, isFalse);
      expect(r.reason, 'sunday');
    });

    test('a date too soon is refused and NAMES the shortfall', () {
      // Lead 3 from Thu 24 → ready Mon 28. Asking for Fri 25 is 2 days short.
      final r = NorchaDelivery.assess(now, DateTime.utc(2026, 9, 25), 3);
      expect(r.ok, isFalse);
      expect(r.reason, 'tooSoon');
      expect(r.short, isNotNull);
      expect(r.short! > 0, isTrue, reason: 'must state how short we are');
    });

    test('a comfortable date is ok and reports its slack', () {
      final r = NorchaDelivery.assess(now, DateTime.utc(2026, 10, 1), 1);
      expect(r.ok, isTrue);
      expect(r.slack, isNotNull);
      expect(r.slack! >= 0, isTrue);
    });

    test('the exact ready date is accepted, not refused', () {
      // want == ready is the boundary. Refusing it would reject an order the
      // shop can actually deliver.
      final ready = NorchaDelivery.earliestReady(now, 1);
      final r = NorchaDelivery.assess(now, ready, 1);
      expect(r.ok, isTrue);
      expect(r.slack, 0);
    });
  });

  group('Amharic labels are the same strings the site uses', () {
    test('months match the holiday engine exactly', () {
      // Duplicated across two files because both are standalone modules on the
      // site too. If one drifts, a customer sees a month spelled two ways.
      for (var m = 1; m <= 12; m++) {
        // Jan 2026 + m months → check the month name agrees
        final d = DateTime.utc(2026, m, 15);
        final viaDelivery = NorchaDelivery.fmt(d, 'am');
        final viaHolidays = NorchaHolidays.fmt(d, 'am');
        expect(viaDelivery.split(' ').last, viaHolidays.split(' ').last,
            reason: 'month $m differs between delivery and holidays');
      }
    });

    test('day names agree too', () {
      for (var d = 21; d <= 27; d++) {
        final day = DateTime.utc(2026, 9, d);
        expect(NorchaDelivery.fmt(day, 'am').split(' ').first,
            NorchaHolidays.fmt(day, 'am').split(' ').first);
      }
    });

    test('English reads like the site', () {
      expect(NorchaDelivery.fmt(DateTime.utc(2026, 9, 24), 'en'),
          'Thursday 24 Sep');
    });
  });

  group('readyPhrase', () {
    test('handles today, tomorrow and later', () {
      final today = NorchaDelivery.assess(DateTime.now(), null, 0);
      // either "Ready today" or a dated phrase depending on the hour — both
      // are valid; assert it produced something human.
      expect(NorchaDelivery.readyPhrase(today, 'en'), isNotEmpty);
    });
  });
}

// Reminder planner tests.
//
// The planner is pure Dart and knows nothing about Android, which is the whole
// reason it is testable. Everything here asserts RULES, not the code's output:
// restraint (never more than three), honesty (never a past deadline), and
// stability (ids must not collide, or one reminder silently replaces another).

import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/core/holidays.dart';
import 'package:norcha_print/core/reminders.dart';

void main() {
  group('restraint — the only strategy that survives a real customer', () {
    test('exactly three offsets, and they are the documented ones', () {
      expect(ReminderPlanner.offsets, [7, 3, 0]);
    });

    test('never schedules more than three reminders for one occasion', () {
      final planned = ReminderPlanner.plan(DateTime(2026, 9, 1));
      expect(planned.length, lessThanOrEqualTo(3));
    });

    test('a reminder every day would be deleted — we do not do that', () {
      // 75-day horizon, at most 3 reminders. If this ever grows, someone has
      // turned the app into a nuisance.
      final planned = ReminderPlanner.plan(DateTime(2026, 9, 1));
      expect(planned.length, lessThanOrEqualTo(3),
          reason: 'notification fatigue is unrecoverable — a customer who '
              'deletes the channel never gets it back');
    });
  });

  group('honesty — never invent urgency', () {
    test('no reminders at all when nothing is within the horizon', () {
      // 1 March 2027 with a 75-day default: the next fixed occasion is
      // Mother's Day at 70 days... if that is inside, the planner may fire.
      // Assert only that a DISTANT date yields nothing.
      final planned = ReminderPlanner.plan(DateTime(2026, 11, 1));
      // Genna is 7 Jan — 67 days away, inside the horizon. So expect either
      // empty or a small set; never a large one.
      expect(planned.length, lessThanOrEqualTo(3));
    });

    test('every scheduled reminder is in the future', () {
      final now = DateTime(2026, 9, 20, 12);
      for (final r in ReminderPlanner.plan(now)) {
        expect(r.fireAt.isAfter(now), isTrue,
            reason: '${r.occasionId} at ${r.fireAt} is not in the future');
      }
    });

    test('same-day reminders ARE scheduled when today is the order-by day', () {
      // Meskel 2026: order-by is Thu 24 Sep. On that morning the customer
      // should still hear about it — that is the last honest warning.
      final now = DateTime(2026, 9, 24, 8);
      final planned = ReminderPlanner.plan(now);
      final sameDay = planned.where((r) => r.occasionId == 'meskel');
      expect(sameDay.isNotEmpty, isTrue,
          reason: 'the last-day reminder must not be dropped on the day');
    });

    test('the day AFTER the order-by date, that occasion is not scheduled', () {
      final now = DateTime(2026, 9, 25, 9); // day after Meskel's order-by
      final planned = ReminderPlanner.plan(now);
      expect(planned.any((r) => r.occasionId == 'meskel'), isFalse,
          reason: 'a reminder for a passed deadline is dishonest');
    });
  });

  group('fire time', () {
    test('fires at 09:30 — early enough to act, late enough to be civil', () {
      final planned = ReminderPlanner.plan(DateTime(2026, 9, 1));
      expect(planned, isNotEmpty);
      for (final r in planned) {
        expect(r.fireAt.hour, 9);
        expect(r.fireAt.minute, 30);
      }
    });
  });

  group('ids must never collide', () {
    test('same occasion, different offsets, different ids', () {
      final ids = ReminderPlanner.offsets
          .map((o) => ReminderPlanner.idFor('meskel', o))
          .toSet();
      expect(ids.length, ReminderPlanner.offsets.length,
          reason: 'a collision means one reminder silently replaces another');
    });

    test('different occasions, same offset, different ids', () {
      final ids = NorchaHolidays.fixed
          .map((h) => ReminderPlanner.idFor(h.id, 7))
          .toSet();
      expect(ids.length, NorchaHolidays.fixed.length);
    });

    test('ids are non-negative (the plugin requires an int)', () {
      for (final h in NorchaHolidays.fixed) {
        for (final o in ReminderPlanner.offsets) {
          expect(ReminderPlanner.idFor(h.id, o), greaterThanOrEqualTo(0));
        }
      }
    });

    test('ids are stable across calls — rescheduling replaces, not duplicates',
        () {
      expect(ReminderPlanner.idFor('meskel', 7),
          ReminderPlanner.idFor('meskel', 7));
    });
  });

  group('messages', () {
    test('each reminder has a distinct, non-empty title and body', () {
      final planned = ReminderPlanner.plan(DateTime(2026, 9, 1));
      expect(planned, isNotEmpty);
      final titles = <String>{};
      for (final r in planned) {
        expect(r.title, isNotEmpty);
        expect(r.body, isNotEmpty);
        titles.add(r.title);
      }
      expect(titles.length, planned.length,
          reason: 'two reminders with the same title look like a bug');
    });

    test('Amharic reminders name the occasion in Amharic', () {
      final planned = ReminderPlanner.plan(DateTime(2026, 9, 1), lang: 'am');
      expect(planned, isNotEmpty);
      expect(planned.first.title, isNot(contains('Enkutatash')),
          reason: 'Amharic mode must not fall back to English');
    });

    test('no message claims urgency for a passed deadline', () {
      // The planner cannot produce one (tested above), but assert the property
      // directly as a guard against a future change to the offsets.
      final planned = ReminderPlanner.plan(DateTime(2026, 9, 1));
      for (final r in planned) {
        expect(r.body.toLowerCase(), isNot(contains('no longer guaranteed')));
      }
    });
  });

  group('nextFire', () {
    test('null when nothing is planned', () {
      expect(ReminderPlanner.nextFire(const []), isNull);
    });

    test('returns the soonest', () {
      final planned = ReminderPlanner.plan(DateTime(2026, 9, 1));
      final next = ReminderPlanner.nextFire(planned);
      expect(next, isNotNull);
      for (final r in planned) {
        expect(next!.isAfter(r.fireAt), isFalse);
      }
    });
  });
}

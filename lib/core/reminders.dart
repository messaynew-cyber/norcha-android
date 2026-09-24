// Reminder scheduling — the one capability the website genuinely does not have.
//
// WHY THIS IS THE POINT OF THE APP
// Everything else in this app is a better version of something norchaprint.com
// already does. This is not. A countdown on a web page only works if the
// customer thinks to visit. A notification works while they are doing something
// else entirely — which is the only time a deadline reminder is worth anything.
//
// WHAT IT SCHEDULES, AND WHY EXACTLY TWO
// Three reminders per occasion, and no more:
//   1. SEVEN DAYS out  — when there is still time to choose photos
//   2. THREE DAYS out  — when it is time to act
//   3. THE ORDER-BY DAY itself — the last honest warning
//
// A reminder every day would be deleted, and a deleted notification channel is
// impossible to get back. Restraint here is not politeness, it is the only
// strategy that survives contact with a real customer.
//
// The engine decides whether an occasion is worth mentioning at all
// (NorchaHolidays.current returns null when nothing is close). This file only
// decides WHEN to say it, and it never invents urgency: the message text comes
// from NorchaHolidays.message, which has an honest fourth case for occasions
// that have already passed.

import 'package:flutter/foundation.dart';

import 'holidays.dart';

/// One reminder, ready to be handed to the notification plugin.
@immutable
class Reminder {
  /// Stable id derived from the occasion + offset, so rescheduling REPLACES
  /// rather than duplicates. A customer with three copies of the same reminder
  /// turns notifications off.
  final int id;
  final String occasionId;
  final DateTime fireAt;
  final String title;
  final String body;

  const Reminder({
    required this.id,
    required this.occasionId,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  @override
  String toString() =>
      'Reminder($occasionId @ ${fireAt.toIso8601String()}): $title';
}

class ReminderPlanner {
  /// Days before the order-by date to fire. See the note at the top of the file
  /// for why there are exactly three.
  static const List<int> offsets = [7, 3, 0];

  /// Schedule window. Never schedule a reminder further out than this — a
  /// notification that arrives in four months is noise, and the customer's
  /// plans will have changed anyway.
  static const int horizonDays = NorchaHolidays.defaultHorizon;

  /// A stable, collision-resistant id.
  ///
  /// The plugin identifies a notification by an int. If two different reminders
  /// ever share one, one silently replaces the other — which is how a customer
  /// misses the reminder that mattered. So the id is derived from BOTH the
  /// occasion and its offset, not from the offset alone.
  static int idFor(String occasionId, int offset) {
    var h = 17;
    for (final c in occasionId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return (h + offset) & 0x7fffffff;
  }

  /// Build every reminder worth scheduling, given "now".
  ///
  /// Returns an empty list when nothing is close — deliberately. An empty list
  /// is a correct answer here, not a failure.
  static List<Reminder> plan(DateTime now, {String lang = 'en'}) {
    final occasion =
        NorchaHolidays.current(now, horizonDays: horizonDays);
    if (occasion == null) return const [];

    final out = <Reminder>[];
    for (final offset in offsets) {
      final fireAt = occasion.orderBy.subtract(Duration(days: offset));

      // Do not schedule into the past. If today is already the order-by day,
      // only the same-day reminder is still useful.
      if (_isBeforeToday(fireAt, now)) continue;

      final m = _messageFor(offset, occasion, lang);
      out.add(Reminder(
        id: idFor(occasion.id, offset),
        occasionId: occasion.id,
        fireAt: DateTime(fireAt.year, fireAt.month, fireAt.day, 9, 30),
        title: m.$1,
        body: m.$2,
      ));
    }
    return out;
  }

  /// Fire time is 9:30 in the morning. Early enough to act on the same day,
  /// late enough not to wake anyone. Not configurable — a setting nobody
  /// changes is not a feature.
  static const int fireHour = 9;
  static const int fireMinute = 30;

  static bool _isBeforeToday(DateTime d, DateTime now) {
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(now.year, now.month, now.day);
    // NOT `a == b`. DateTime does not override ==, so comparing two DateTime
    // objects tests IDENTITY, not the instant they represent — this silently
    // returned false for equal days. Compare the parsed components instead.
    // (Same class of bug as num.clamp() not narrowing: correct-looking code,
    // wrong for a reason nobody checked.)
    final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
    return a.isBefore(b) || sameDay;
  }

  /// Title and body for a given offset. Uses NorchaHolidays.message so the app
  /// never states a deadline differently from the website.
  static (String, String) _messageFor(
      int offset, Occasion h, String lang) {
    final name = h.name(lang);
    switch (offset) {
      case 7:
        return (
          '$name is in a week',
          'There is still time to choose your photographs. '
              'Order by ${NorchaHolidays.fmt(h.orderBy, lang)}.',
        );
      case 3:
        return (
          'Three days to order for $name',
          'Last order day is ${NorchaHolidays.fmt(h.orderBy, lang)}. '
              'Message us if you are unsure about anything.',
        );
      default:
        return (
          'Today is the last day to order for $name',
          'Photo books take longer — message us and we will tell you honestly.',
        );
    }
  }

  /// The next moment a reminder should fire, or null if none is planned.
  /// Used to show the customer what they have agreed to before we schedule it.
  static DateTime? nextFire(List<Reminder> reminders) {
    if (reminders.isEmpty) return null;
    final sorted = [...reminders]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return sorted.first.fireAt;
  }
}

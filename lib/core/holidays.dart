// Ethiopian holiday deadline engine.
//
// PORTED FROM: feven-prints-v2/js/norcha-holidays.js @ main
// 1:1 port. test/holiday_parity_test.dart holds the JavaScript's behaviour as
// literal expectations and fails if the Dart drifts.
//
// WHY THIS EXISTS
// A euro-market print shop advertises "last order dates for Christmas" — one
// holiday, one date, one number. Ethiopia has a LADDER of printing occasions,
// and every one of them sends families to a print shop in the same week:
//
//   Meskel (27 Sep) · Enkutatash (11 Sep) · Genna (7 Jan) · Timket (19 Jan)
//   Fasika (movable) · Mother's Day · graduation season
//
// So this is not one line. It computes the NEXT deadline, steps back over
// Sundays, accounts for the fact that a canvas needs one production day while
// a photo book needs three, and — critically — HIDES ITSELF when nothing is
// near. A permanent countdown is noise, and noise stops being read.

/// One occasion and the date it falls on, this year or next.
class Occasion {
  final String id;
  final String en;
  final String am;
  final DateTime date;
  /// Days from "today" to the occasion itself.
  final int days;
  /// The last day you can order and still be ready in time.
  final DateTime orderBy;
  /// Days from "today" to that last day. Negative means it has passed.
  final int daysToOrder;

  const Occasion({
    required this.id,
    required this.en,
    required this.am,
    required this.date,
    required this.days,
    required this.orderBy,
    required this.daysToOrder,
  });

  String name(String lang) => lang == 'am' ? am : en;
}

class NorchaHolidays {
  /// Production days needed. The pessimistic number across the catalogue —
  /// a photo book takes two, so nothing is promised faster than that.
  static const int maxLead = 3;

  /// Show nothing if the next occasion is further away than this. 75 days is
  /// the site's number; matching it keeps the app and the web consistent.
  static const int defaultHorizon = 75;

  /// Fixed Gregorian dates. Fasika is the exception — a movable feast computed
  /// from Orthodox Easter, so it gets its own function.
  /// ⚠️ [FEVEN] the shop should confirm which occasions it actually prints for.
  static const List<({String id, String en, String am, int month, int day})>
      fixed = [
    (id: 'meskel', en: 'Meskel', am: 'መስቀል', month: 9, day: 27),
    (id: 'enkutatash', en: 'Enkutatash', am: 'እንቁጣጣሽ', month: 9, day: 11),
    (id: 'genna', en: 'Genna', am: 'ገና', month: 1, day: 7),
    (id: 'timket', en: 'Timket', am: 'ጥምቀት', month: 1, day: 19),
    (id: 'mothersday', en: "Mother's Day", am: 'የእናቶች ቀን', month: 5, day: 10),
    (id: 'graduation', en: 'Graduation season', am: 'የምረቃ ወቅት', month: 7, day: 1),
  ];

  /// Orthodox Easter (Fasika), in the Gregorian calendar.
  ///
  /// Meeus' Julian algorithm, then +7 days to convert Julian → Gregorian and
  /// a further +7 for the Orthodox reckoning. This is the same arithmetic the
  /// website uses; do not "simplify" it — the +7s are load-bearing and the
  /// dates are checked in the parity test against known years.
  static DateTime fasika(int year) {
    final a = year % 4;
    final b = year % 7;
    final c = year % 19;
    final d = (19 * c + 15) % 30;
    final e = (2 * a + 4 * b - d + 34) % 7;
    final month = (d + e + 114) ~/ 31;
    final day = ((d + e + 114) % 31) + 1;
    // NOTE: the JS uses new Date(year, month-1, day) then +7 days. Dart's
    // DateTime normalises overflow the same way, so this is equivalent.
    final greg = DateTime(year, month, day);
    return greg.add(const Duration(days: 7));
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whole days between two dates, ignoring the time of day.
  /// Mirrors daysBetween() — both sides are normalised to midnight first, so
  /// the result is exact even across a DST boundary or a leap second.
  static int _daysBetween(DateTime a, DateTime b) {
    final sa = _startOfDay(a);
    final sb = _startOfDay(b);
    return sb.difference(sa).inDays;
  }

  /// The last day you can order for [date] and still make it.
  ///
  /// Steps back [leadDays] *working* days — and the shop does not work
  /// Sundays, so a Sunday is stepped over without counting. This is the detail
  /// that makes the promise honest rather than approximately honest.
  static DateTime orderByFor(DateTime date, int leadDays) {
    var cursor = DateTime(date.year, date.month, date.day);
    var remaining = leadDays;
    while (remaining > 0) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (cursor.weekday != DateTime.sunday) remaining--;
    }
    return cursor;
  }

  /// Every occasion from [from] onward, within [horizonDays], soonest first.
  static List<Occasion> upcoming(
    DateTime from, {
    int horizonDays = 90,
    int leadDays = maxLead,
  }) {
    final start = _startOfDay(from);
    final y = start.year;

    final raw = <({String id, String en, String am, DateTime date})>[];
    for (var yi = 0; yi <= 1; yi++) {
      for (final h in fixed) {
        raw.add((
          id: h.id,
          en: h.en,
          am: h.am,
          date: DateTime(y + yi, h.month, h.day),
        ));
      }
      raw.add((
        id: 'fasika',
        en: 'Fasika',
        am: 'ፋሲካ',
        date: fasika(y + yi),
      ));
    }

    final out = <Occasion>[];
    for (final h in raw) {
      final days = _daysBetween(start, h.date);
      if (days < 0) continue; // already passed
      final orderBy = orderByFor(h.date, leadDays);
      out.add(Occasion(
        id: h.id,
        en: h.en,
        am: h.am,
        date: h.date,
        days: days,
        orderBy: orderBy,
        daysToOrder: _daysBetween(start, orderBy),
      ));
    }
    out.sort((a, b) => a.days.compareTo(b.days));
    return out.where((h) => h.days <= horizonDays).toList();
  }

  /// The one to show, or null when nothing is close enough to matter.
  /// Returns null deliberately often — see the note at the top of the file.
  static Occasion? current(DateTime from, {int horizonDays = defaultHorizon}) {
    final list = upcoming(from, horizonDays: horizonDays);
    return list.isEmpty ? null : list.first;
  }

  static const _dayNames = {
    'en': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    'am': ['እሑድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'ዓርብ', 'ቅዳሜ'],
  };
  static const _months = {
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'am': ['ጃንዩ', 'ፌብሩ', 'ማርች', 'ኤፕሪ', 'ሜይ', 'ጁን', 'ጁላይ', 'ኦገስ', 'ሴፕቴ', 'ኦክቶ', 'ኖቬም', 'ዲሴም'],
  };

  /// "Fri 27 Sep" — the same format the website prints.
  static String fmt(DateTime d, String lang) {
    final l = lang == 'am' ? 'am' : 'en';
    // Dart weekday: 1=Mon..7=Sun. _dayNames is Sunday-first, so shift.
    final idx = d.weekday % 7;
    return '${_dayNames[l]![idx]} ${d.day} ${_months[l]![d.month - 1]}';
  }

  /// The message to show, and its quieter second line.
  ///
  /// Four cases, and the FOURTH is the one that matters: once the last order
  /// day has passed, it does not pretend. It says same-day pickup is no longer
  /// guaranteed and invites an honest conversation. A shop that over-promises
  /// loses the customer twice.
  static ({String message, String sub}) message(Occasion h, String lang) {
    final name = h.name(lang);
    final days = h.daysToOrder;
    if (days > 1) {
      return (
        message: '$name: order within $days days',
        sub: 'to be ready before the holiday',
      );
    }
    if (days == 1) {
      return (
        message: '$name: last day to order is tomorrow',
        sub: 'photo books may need longer',
      );
    }
    if (days == 0) {
      return (
        message: 'Today is the last day to order for $name',
        sub: 'message us before we close',
      );
    }
    return (
      message: 'Same-day pickup is no longer guaranteed for $name',
      sub: 'message us and we will tell you honestly',
    );
  }
}

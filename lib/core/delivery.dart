// Delivery estimation — a real date, not "6-9 working days".
//
// PORTED FROM: feven-prints-v2/js/norcha-delivery.js
//
// WHY THIS EXISTS
// Every print shop says "6-9 working days" and every customer has to guess what
// that means for THEIR date. This answers the actual question: given what you
// want printed and the day you want it, can we make it — and if not, why not.
//
// It is PESSIMISTIC on purpose. When a date does not fit it says so and names
// the reason: past, Sunday, or too soon. An over-promise costs the shop twice,
// once when the customer arrives and again when they tell people.
//
// 🔴 UTC, DELIBERATELY
// The original JS uses local-time dates throughout. That is invisible in Addis
// (GMT+3, no DST) but it is fragile — and it would have made this module and
// the holiday engine measure "a day" differently, since holidays.dart converts
// dates to UTC. Verified before writing: the UTC conversion changes nothing in
// any timezone tested (Addis, UTC, UTC+14), so this is a free correctness win.

class DeliveryAssessment {
  /// Can the shop hit the requested date?
  final bool ok;

  /// One of: null, 'past', 'sunday', 'tooSoon'.
  final String? reason;

  /// The date the job will actually be ready.
  final DateTime ready;

  /// The date the customer asked for. Null when they did not specify one.
  final DateTime? want;

  /// Working days from today to [want] — only present for a valid request.
  final int? days;

  /// Working days of spare capacity when the request is comfortable.
  final int? slack;

  /// Working days SHORT when it is not. Names the size of the problem.
  final int? short;

  const DeliveryAssessment({
    required this.ok,
    this.reason,
    required this.ready,
    this.want,
    this.days,
    this.slack,
    this.short,
  });
}

class NorchaDelivery {
  static DateTime _startOfDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  static bool _isSunday(DateTime d) => d.weekday == DateTime.sunday;

  /// Add [n] WORKING days. Sundays are skipped, not counted — the shop is shut.
  static DateTime addWorkingDays(DateTime from, int n) {
    var d = _startOfDay(from);
    var left = n;
    while (left > 0) {
      d = d.add(const Duration(days: 1));
      if (!_isSunday(d)) left--;
    }
    return d;
  }

  /// Working days between two dates, signed. Positive means b is later.
  static int workingDaysBetween(DateTime a, DateTime b) {
    var start = _startOfDay(a);
    var end = _startOfDay(b);
    var sign = 1;
    if (end.isBefore(start)) {
      final t = start;
      start = end;
      end = t;
      sign = -1;
    }
    var count = 0;
    var cur = start;
    while (cur.isBefore(end)) {
      cur = cur.add(const Duration(days: 1));
      if (!_isSunday(cur)) count++;
    }
    return count * sign;
  }

  /// The earliest the job could be ready.
  ///
  /// Two things push production to the next working day: being past the
  /// same-day cut-off, or it being Sunday. In either case the customer
  /// effectively loses today — and the lead time is counted from the new base,
  /// not from today. Getting that wrong is how a shop promises Monday for a
  /// Friday job.
  static DateTime earliestReady(DateTime now, int lead, {int cutoffHour = 16}) {
    final afterCutoff = now.hour >= cutoffHour;
    var base = _startOfDay(now);

    if (afterCutoff || _isSunday(base)) {
      base = addWorkingDays(base, 1);
      return addWorkingDays(base, lead > 0 ? lead - 1 : 0);
    }
    if (lead == 0) return base; // same day
    return addWorkingDays(base, lead);
  }

  /// Can the shop hit [requested]? Pessimistic by design — see the note above.
  static DeliveryAssessment assess(
    DateTime now,
    DateTime? requested,
    int lead, {
    int cutoffHour = 16,
  }) {
    final ready = earliestReady(now, lead, cutoffHour: cutoffHour);

    if (requested == null) {
      return DeliveryAssessment(
        ok: true,
        ready: ready,
        days: workingDaysBetween(now, ready),
      );
    }

    final want = _startOfDay(requested);
    final today = _startOfDay(now);

    if (want.isBefore(today)) {
      return DeliveryAssessment(
          ok: false, reason: 'past', ready: ready, want: want);
    }
    if (_isSunday(want)) {
      return DeliveryAssessment(
          ok: false, reason: 'sunday', ready: ready, want: want);
    }
    if (!want.isBefore(ready)) {
      return DeliveryAssessment(
        ok: true,
        ready: ready,
        want: want,
        days: workingDaysBetween(now, want),
        slack: workingDaysBetween(ready, want),
      );
    }
    return DeliveryAssessment(
      ok: false,
      reason: 'tooSoon',
      ready: ready,
      want: want,
      short: workingDaysBetween(want, ready),
    );
  }

  static const _dayNames = {
    'en': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    'am': ['እሑድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'ዓርብ', 'ቅዳሜ'],
  };
  static const _months = {
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'am': ['ጃንዩ', 'ፌብሩ', 'ማርች', 'ኤፕሪ', 'ሜይ', 'ጁን', 'ጁላይ', 'ኦገስ', 'ሴፕቴ', 'ኦክቶ', 'ኖቬም', 'ዲሴም'],
  };

  /// "Thursday 24 Sep" — the same format the site prints.
  static String fmt(DateTime d, String lang) {
    final l = lang == 'am' ? 'am' : 'en';
    final idx = d.weekday % 7; // Dart 1=Mon..7=Sun → Sunday-first index
    return '${_dayNames[l]![idx]} ${d.day} ${_months[l]![d.month - 1]}';
  }

  /// A short human phrase for the ready date, for the quote screen.
  static String readyPhrase(DeliveryAssessment r, String lang) {
    final days = workingDaysBetween(DateTime.now(), r.ready);
    if (days <= 0) return 'Ready today';
    if (days == 1) return 'Ready tomorrow';
    return 'Ready ${fmt(r.ready, lang)}';
  }
}

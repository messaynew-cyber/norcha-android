// Norcha Print — the language layer.
//
// WHY THIS IS HAND-ROLLED RATHER THAN intl/gen-l10n
// The app has about eighty strings in two languages. flutter gen-l10n generates
// an ARB pipeline, a build step and a code-generated class for that, and it
// would be the only generated code in the repo. A map and a lookup does the same
// job, is readable in one screen, and — the deciding reason — it keeps the
// Amharic next to the English so a translator can see both without opening a
// second file.
//
// 🔴 AMHARIC IS NOT A TRANSLATION LAYER.
// Norcha's counter speaks Amharic first. This is not "localisation" bolted on at
// the end; it is the primary register for most customers. That is why every
// string here is written twice by hand rather than machine-translated, and why
// the Amharic is checked for meaning rather than for word-for-word fidelity.
//
// Where a term has no clean Amharic equivalent, the English is kept and marked
// — a made-up word is worse than a borrowed one.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NorchaLang {
  en,
  am;

  static NorchaLang parse(String? s) => s == 'am' ? NorchaLang.am : NorchaLang.en;
  String get code => name;
  bool get isAmharic => this == NorchaLang.am;
}

class LangController extends ChangeNotifier {
  static const _key = 'norcha.lang';

  NorchaLang _lang = NorchaLang.en;
  NorchaLang get lang => _lang;

  /// Read the saved preference. Failure is silent: a first launch with nothing
  /// stored is normal, and the app must never refuse to open because a
  /// preference could not be read.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _lang = NorchaLang.parse(p.getString(_key));
    } catch (_) {
      _lang = NorchaLang.en;
    }
    notifyListeners();
  }

  Future<void> set(NorchaLang l) async {
    if (l == _lang) return;
    _lang = l;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, l.code);
    } catch (_) {
      // The switch already happened on screen. Failing to remember it is a
      // smaller problem than refusing to switch.
    }
  }

  Future<void> toggle() =>
      set(_lang == NorchaLang.am ? NorchaLang.en : NorchaLang.am);

  /// Reach the controller from anywhere in the tree.
  static LangController of(BuildContext context) {
    // InheritedNotifier stores its Listenable in `notifier`; there is no
    // `controller` field. Reading the wrong one is a null at runtime and an
    // undefined-getter at analysis time.
    final scope = context.dependOnInheritedWidgetOfExactType<LangScope>();
    final n = scope?.notifier;
    if (n is LangController) return n;
    throw StateError('No LangScope above this widget');
  }
}

class LangScope extends InheritedNotifier<LangController> {
  const LangScope({
    super.key,
    required LangController controller,
    required super.child,
  }) : super(notifier: controller);
}

/// Every user-facing string, both languages, side by side.
///
/// Grouped by screen so a missing one is visible by eye. `t()` falls back to the
/// key itself rather than to English — a missing translation should be LOUD in
/// development, not silently rendered in the wrong language.
mixin L {
  static const Map<String, (String, String)> _s = {
    // ── shell / nav ────────────────────────────────────────────────────
    'nav.home':    ('Home', 'መግቢያ'),
    'nav.quote':   ('Quote', 'ዋጋ'),
    'nav.order':   ('Order', 'ትዕዛዝ'),
    'nav.upload':  ('Upload', 'መላኪያ'),
    'nav.studio':  ('Studio', 'ስቱዲዮ'),

    // ── home ───────────────────────────────────────────────────────────
    'home.eyebrow': ('Norcha Print · Bole', 'ኖርቻ ፕሪንት · ቦሌ'),
    'home.title':   ('Photo printing,\ndone properly.',
                     'የፎቶ ህትመት፣\nበአግባቡ።'),
    'home.hero.kicker': ('SAME-DAY PICKUP', 'በዚያው ቀን መውሰድ'),
    'home.hero.line':   ('Your photos,\nprinted properly.',
                         'ፎቶዎችዎ፣\nበአግባቡ ታትመዋል።'),
    'home.section.products': ('WHAT WE MAKE', 'የምንሠራው'),
    'home.section.find':     ('FIND US', 'ያግኙን'),
    'home.sizes':  ('sizes', 'መጠኖች'),
    'home.sameDay': ('same day', 'በዚያው ቀን'),
    'home.days':   ('days', 'ቀናት'),
    'home.day':    ('day', 'ቀን'),
    'home.orderWithin': ('Order within', 'ይዘዙ በ'),
    'home.lastDayToday': ('Last day to order is today', 'ዛሬ የመጨረሻው ቀን ነው'),
    'home.from':   ('from', 'ከ'),

    // ── quote ──────────────────────────────────────────────────────────
    'quote.eyebrow': ('Build a job', 'ስራ ያዘጋጁ'),
    'quote.title':   ('What are we\nprinting?', 'ምን እናትም?'),
    'quote.size':    ('SIZE', 'መጠን'),
    'quote.howMany': ('HOW MANY', 'ብዛት'),
    'quote.when':    ('WHEN DO YOU NEED IT?', 'መቼ ይፈልጋሉ?'),
    'quote.breakdown': ('THE BREAKDOWN', 'ዝርዝር'),
    'quote.unit':    ('Unit price', 'የአንዱ ዋጋ'),
    'quote.qty':     ('Quantity', 'ብዛት'),
    'quote.subtotal':('Subtotal', 'ንዑስ ድምር'),
    'quote.discount':('Discount', 'ቅናሽ'),
    'quote.total':   ('TOTAL', 'ጠቅላላ'),
    'quote.send':    ('Send', 'ላክ'),
    'quote.pickDate':('Pick a date (optional)', 'ቀን ይምረጡ (አማራጭ)'),
    'quote.needBy':  ('Need it by', 'ያስፈልገኛል በ'),
    'quote.readyToday':   ('Ready today', 'ዛሬ ዝግጁ ነው'),
    'quote.readyTomorrow':('Ready tomorrow', 'ነገ ዝግጁ ነው'),
    'quote.ready':   ('Ready', 'ዝግጁ ይሆናል'),
    'quote.tierUnlock': ('Volume tier unlocked', 'የብዛት ቅናሽ ተከፍቷል'),
    'quote.applied': ('volume discount applied — saving',
                      'የብዛት ቅናሽ ተተግብሯል — ቁጠባ'),
    'quote.past':    ('That date has passed.', 'ያ ቀን አልፏል።'),
    'quote.sunday':  ('The shop is shut on Sundays.', 'ሱቁ እሁድ ዝግ ነው።'),
    'quote.tight':   ('That is tight — earliest ready is', 'ጠባብ ነው — በጣም ፈጣኑ ዝግጁ'),
    'quote.tempWarn':('Prices are not yet confirmed by the studio. Please '
                      'confirm on WhatsApp before ordering.',
                      'ዋጋዎቹ ገና በስቱዲዮ አልተረጋገጡም። ከመዘዙ በፊት በዋትስአፕ ያረጋግጡ።'),

    // ── order ──────────────────────────────────────────────────────────
    'order.eyebrow': ('Order status', 'የትዕዛዝ ሁኔታ'),
    'order.title':   ('Did my photos\narrive?', 'ፎቶዎቼ\nደርሰዋል?'),
    'order.blurb':   ('Enter the reference we gave you and the phone number '
                      'you ordered with.',
                      'የሰጠንዎትን ቁጥር እና የዘዙበትን ስልክ ቁጥር ያስገቡ።'),
    'order.ref':     ('REFERENCE', 'ቁጥር'),
    'order.phone':   ('PHONE NUMBER', 'ስልክ ቁጥር'),
    'order.check':   ('Check my order', 'ትዕዛዜን ፈልግ'),
    'order.checking':('Checking…', 'በመፈለግ ላይ…'),
    'order.found':   ('We have your photos', 'ፎቶዎችዎ ደርሰዋል'),
    'order.received':('Photos received', 'የደረሱ ፎቶዎች'),
    'order.arrived': ('Received', 'የደረሱበት ቀን'),
    'order.asked':   ('You asked for', 'የዘዙት'),
    'order.deleted': ('We delete them on', 'የምንያጠፋቸው ቀን'),
    'order.whatsapp':('Message us on WhatsApp', 'በዋትስአፕ ያግኙን'),
    'order.another': ('Check another reference', 'ሌላ ቁጥር ይፈልጉ'),

    // ── upload ─────────────────────────────────────────────────────────
    'upload.eyebrow': ('Send photos', 'ፎቶ ይላኩ'),
    'upload.title':   ('Upload your\noriginals.', 'ዋና ፎቶዎችዎን\nይላኩ።'),
    'upload.blurb':   ('Same originals, no compression. You get a reference '
                       'number you can read down a phone line.',
                       'ዋናዎቹ ፋይሎች፣ ያለ መጨመቅ። በስልክ ሊነገር የሚችል ቁጥር ያገኛሉ።'),
    'upload.choose':  ('Choose photos', 'ፎቶዎችን ይምረጡ'),
    'upload.again':   ('Tap to choose again', 'እንደገና ለመምረጥ ይንኩ'),
    'upload.selected':('selected', 'ተመርጠዋል'),
    'upload.upTo':    ('Up to', 'እስከ'),
    'upload.forWhat': ('WHAT IS IT FOR?', 'ለምን ነው?'),
    'upload.sizeOpt': ('SIZE (OPTIONAL)', 'መጠን (አማራጭ)'),
    'upload.yourName':('YOUR NAME', 'ስምዎ'),
    'upload.phone':   ('PHONE', 'ስልክ'),
    'upload.note':    ('ANYTHING WE SHOULD KNOW', 'ማወቅ ያለብን ነገር'),
    'upload.optional':('Optional', 'አማራጭ'),
    'upload.send':    ('Send photos', 'ፎቶ ላክ'),
    'upload.sendN':   ('Send', 'ላክ'),
    'upload.sending': ('Sending…', 'በመላክ ላይ…'),
    'upload.sent':    ('sent', 'ተልኳል'),
    'upload.keepChat':('The chat still works and it always will — WhatsApp is '
                       'right there if you would rather send them that way.',
                       'ቻቱ አሁንም ይሰራል። በዋትስአፕ መላክ ከፈለጉ ሁልጊዜ ይችላሉ።'),
    'upload.offTitle':('Upload is not switched on yet',
                       'መላኪያው ገና አልተከፈተም'),
    'upload.offBody': ('Please send your photos on WhatsApp — it works right '
                       'now, and you keep the chat.',
                       'እባክዎ ፎቶዎችዎን በዋትስአፕ ይላኩ — አሁን ይሰራል።'),
    'upload.waSend':  ('Send on WhatsApp', 'በዋትስአፕ ላክ'),
    'upload.received':('photos received', 'ፎቶዎች ደርሰዋል'),
    'upload.yourRef': ('YOUR REFERENCE', 'የእርስዎ ቁጥር'),
    'upload.keepRef': ('Keep this. A person at the studio still confirms sizes '
                       'and price before printing.',
                       'ይህን ያስቀምጡ። ከመታተሙ በፊት ሰው መጠኑንና ዋጋውን ያረጋግጣል።'),
    'upload.refWa':   ('Send the reference on WhatsApp', 'ቁጥሩን በዋትስአፕ ላክ'),

    // ── studio ─────────────────────────────────────────────────────────
    'studio.eyebrow': ('The studio', 'ስቱዲዮው'),
    'studio.title':   ('Norcha Print,\nBole.', 'ኖርቻ ፕሪንት፣\nቦሌ።'),
    'studio.findUs':  ('FIND US', 'ያግኙን'),
    'studio.cutoff':  ('Same-day cut-off', 'የበዚያው ቀን መጨረሻ'),
    'studio.maps':    ('Open in Maps', 'በካርታ ክፈት'),
    'studio.talk':    ('TALK TO A PERSON', 'ከሰው ጋር ይነጋገሩ'),
    'studio.whatsapp':('WhatsApp', 'ዋትስአፕ'),
    'studio.call':    ('Call', 'ደውል'),
    'studio.howLong': ('HOW LONG IT TAKES', 'ምን ያህል ጊዜ ይወስዳል'),
    'studio.timingNote': ('A photo book takes two production days; prints and '
                          'canvas take less. Sundays the shop is shut, so they '
                          'are not counted.',
                          'የፎቶ መጽሐፍ ሁለት የስራ ቀን ይወስዳል፤ ህትመትና ካንቫስ ያነሰ። እሁድ ሱቁ ዝግ ነው።'),
    'studio.yourPhotos':('YOUR PHOTOS', 'ፎቶዎችዎ'),
    'studio.retention': ('We keep your photos for 30 days so we can print '
                         'them, then we delete them. We do not publish them, '
                         'and we do not sell them.',
                         'ፎቶዎችዎን ለመታተም 30 ቀን እናቆያለን፣ ከዚያ እናጠፋለን። አናትምም፣ አንሸጥም።'),
    'studio.privacy': ('Order lookup needs both your reference AND the phone '
                       'number you ordered with. One without the other gets no '
                       'answer — so nobody can use it to check whether an order '
                       'exists.',
                       'ፍለጋው ቁጥሩንና ስልክ ቁጥሩን ሁለቱንም ይፈልጋል። አንዱ ብቻ መልስ አያገኝም።'),

    // ── settings ───────────────────────────────────────────────────────
    'set.theme.light': ('Light', 'ብርሃን'),
    'set.theme.dark':  ('Dark', 'ጨለማ'),
    'set.lang':        ('Language', 'ቋንቋ'),
    'set.appearance':  ('Appearance', 'አቀራረብ'),
  };

  static String t(String key, NorchaLang lang) {
    final v = _s[key];
    if (v == null) return key; // loud in dev; a wrong-language string is worse
    return lang.isAmharic ? v.$2 : v.$1;
  }

  /// Bilingual label — used where both should be visible at once (the language
  /// switch itself, and the page headers).
  static (String, String) both(String key) {
    final v = _s[key];
    return v ?? (key, key);
  }
}

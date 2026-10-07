// Norcha Print — the single source of truth for products, prices and lead times.
//
// SOURCE: the shop's OWN price sheet (Price_List_1.xlsx, the "BOARD" column) and
// Price List 2, both supplied by the Architect on 2026-10-07. The website's
// js/norcha-data.js is NO LONGER the price reference — every number it carried
// was a placeholder and none of them were the shop's real prices.
//
// "BOARD" on the sheet means CANVAS. Confirmed by the Architect 2026-10-07.
//
// test/pricing_parity_test.dart previously diffed this file against the website.
// That test must now be regenerated from THIS file — the website is the thing
// that has to catch up, not the app.
//
// Lead times are in PRODUCTION DAYS (working days, before shipping/pickup).

/// Shop facts. Mirrors SHOP in norcha-data.js.
class Shop {
  static const name = 'Norcha Print';
  static const phone = '+251 911 729 779'; // confirmed by the Architect 2026-09-23
  static const wa = '251911729779'; // digits only — this form goes into wa.me links
  static const currency = 'ETB';
  static const city = 'Bole, Addis Ababa';
  static const hours = 'Mon-Sat 8:30-19:00, Sun 10:00-17:00';
  static const cutoffHour = 16; // same-day cut-off

  /// The shop supplied its own sheet on 2026-10-07, so the prices below are
  /// real. Two numbers are still pending confirmation and are flagged inline:
  /// 80x120 canvas (a price inversion) and 80x120 framed (looks like a typo).
  static const pricesAreTemporary = false;
}

/// A bilingual label. Amharic is not a translation afterthought here — it is
/// the language most of the counter speaks.
class Bi {
  final String en;
  final String am;
  const Bi(this.en, this.am);

  String call(String lang) => lang == 'am' ? am : en;
}

class PrintSize {
  final String key;
  final String label;
  final int price;
  const PrintSize(this.key, this.label, this.price);
}

class Product {
  final String family;
  final Bi label;
  final int lead; // production days
  final String tier; // which discount ladder applies
  final List<PrintSize> sizes;
  const Product(this.family, this.label, this.lead, this.tier, this.sizes);
}

class Tier {
  final int min;
  final int pct;
  const Tier(this.min, this.pct);
}

/// The full price breakdown, so the UI never does its own maths.
class Quote {
  final int unit;
  final int qty;
  final int gross;
  final int pct;
  final int discount;
  final int total;
  final int lead;
  const Quote({
    required this.unit,
    required this.qty,
    required this.gross,
    required this.pct,
    required this.discount,
    required this.total,
    required this.lead,
  });
}

class NorchaData {
  static const Map<String, Product> products = {
    // ---- STANDARD PRINTS (paper) ----------------------------------------
    // 🔴 [ARCHITECT] NOT SUPPLIED. The shop's sheet covers "BOARD" (canvas)
    // only, and Price List 2 has no plain paper prints. These six numbers are
    // the OLD PLACEHOLDERS, kept so 'prints' remains a valid family — it is
    // the DEFAULT selection in quote_page.dart and upload_page.dart, so
    // deleting it crashes both screens.
    // ⚠️ THESE PRICES ARE NOT REAL. Get them from the shop.
    'prints': Product('prints', Bi('Standard prints', 'መደበኛ ህትመት'), 0, 'photos', [
      PrintSize('std-10x15', '10 × 15 cm', 25),
      PrintSize('std-13x18', '13 × 18 cm', 40),
      PrintSize('std-15x21', '15 × 21 cm', 60),
      PrintSize('std-20x30', '20 × 30 cm', 120),
      PrintSize('std-a4', 'A4 · 21 × 30 cm', 150),
      PrintSize('std-a3', 'A3 · 30 × 42 cm', 280),
    ]),

    // ---- CANVAS  (the shop's sheet calls this "BOARD") ------------------
    // Straight from Price_List_1.xlsx. 11 sizes; "45 x 60" is on the sheet
    // with a dash and NO price, so it is deliberately absent here rather than
    // guessed. Lead time 1 day, as the original site carried.
    'canvas': Product('canvas', Bi('Canvas prints', 'የካንቫስ ህትመት'), 1, 'wall', [
      PrintSize('canvas-10x15', '10 × 15 cm', 300),
      PrintSize('canvas-15x20', '15 × 20 cm', 500),
      PrintSize('canvas-20x30', '20 × 30 cm', 750),
      PrintSize('canvas-30x46', '30 × 46 cm', 1300),
      PrintSize('canvas-30x60', '30 × 60 cm', 1600),
      PrintSize('canvas-30x90', '30 × 90 cm', 1900),
      PrintSize('canvas-40x60', '40 × 60 cm', 1900),
      PrintSize('canvas-50x80', '50 × 80 cm', 2500),
      PrintSize('canvas-60x90', '60 × 90 cm', 2700),
      PrintSize('canvas-60x120', '60 × 120 cm', 4600),
      // ⚠️ [ARCHITECT] 3,500 as instructed, but this BREAKS THE LADDER:
      // 60 × 120 (7,200 cm²) is 4,600 while 80 × 120 (9,600 cm²) is 3,500 —
      // the bigger canvas is 1,100 CHEAPER, and cost/cm² drops 0.639 -> 0.365.
      // Every other size steps down smoothly. Suspect a dropped digit (8,500?)
      // or that 60 × 120 is the wrong one. Left exactly as instructed — do not
      // "fix" without the shop saying so.
      PrintSize('canvas-80x120', '80 × 120 cm', 3500),
    ]),

    // ---- BLACK WOOD FRAMES WITH GLASS -----------------------------------
    // A separate product line, not framed canvas — the sizes are paper sizes.
    // Confirmed by the Architect 2026-10-07: black wood frame + glass.
    'frames': Product('frames', Bi('Black wood frames · glass', 'ጥቁር እንጨት ፍሬም · ብርጭቆ'), 1, 'wall', [
      PrintSize('frame-a4', 'A4 framed', 2200),
      PrintSize('frame-a3', 'A3 framed', 2800),
      PrintSize('frame-40x60', '40 × 60 cm framed', 5600),
      // ⚠️ [ARCHITECT] 28,000 is almost certainly a typo. 40 × 60 is 5,600;
      // 28,000 is 5× that for 2.3× the area. Extrapolating the A3 -> 40×60
      // step (+2,800) gives roughly 8,400. Left as instructed, flagged here.
      PrintSize('frame-80x120', '80 × 120 cm framed', 28000),
    ]),

    // ---- CALENDAR -------------------------------------------------------
    // A5 ONLY. Confirmed by the Architect: this is the only size it comes in.
    // The old A4/A3 wall-calendar entries were placeholders and are deleted.
    'calendars': Product('calendars', Bi('Calendar', 'የቀን መቁጠሪያ'), 1, 'wall', [
      PrintSize('cal-a5', 'A5 calendar', 1680),
    ]),

    // ---- PHOTO BOOK -----------------------------------------------------
    // The shop gave one figure: 1,820. That is treated as the single photo-book
    // price. The four old sizes (1,800 / 2,600 / 3,800 / 6,400) were
    // placeholders and are gone.
    // ⚠️ [ARCHITECT] confirm whether 1,820 is one fixed book or the entry tier.
    'books': Product('books', Bi('Photo book', 'የፎቶ መጽሐፍ'), 2, 'books', [
      PrintSize('book-standard', 'Photo book', 1820),
    ]),

    // ---- PHOTO MUG ------------------------------------------------------
    // 1,120 from the shop. The old 350 / 650 / 1200 pack ladder was a
    // placeholder. ONE size now — a mug is a mug, so the old double-discount
    // trap (a 2-pack price colliding with the gifts ladder) cannot happen:
    // there is no longer a pack size to collide with.
    // ⚠️ [ARCHITECT] two things to confirm: (a) 1,120 is PER MUG, not a pack;
    // (b) the 'gifts' ladder gives 2 mugs 8% off. Intended for mugs?
    'mugs': Product('mugs', Bi('Photo mug', 'የፎቶ ሙግ'), 0, 'gifts', [
      PrintSize('mug-1', 'Photo mug', 1120),
    ]),
  };

  /// Volume discounts, shaped for ETHIOPIAN bulk buying: weddings, funerals,
  /// church events, graduations — quantity jumps fast, and the buyer is
  /// price-sensitive at the low end but loyal at the high end.
  static const Map<String, List<Tier>> tiers = {
    'photos': [ // standard prints — sold in hundreds
      Tier(1, 0), Tier(10, 10), Tier(50, 20), Tier(100, 35), Tier(500, 50),
    ],
    'wall': [ // canvas / frames / calendars — few units
      Tier(1, 0), Tier(2, 10), Tier(5, 15), Tier(10, 22),
    ],
    'books': [ // photo books — expensive, low volume
      Tier(1, 0), Tier(2, 8), Tier(5, 15),
    ],
    'gifts': [ // small goods that price per unit
      Tier(1, 0), Tier(2, 8), Tier(4, 15), Tier(12, 25),
    ],
  };

  /// Unit price for a size key. Null when the family or key is unknown.
  static int? priceOf(String family, String key) {
    final p = products[family];
    if (p == null) return null;
    for (final s in p.sizes) {
      if (s.key == key) return s.price;
    }
    return null;
  }

  /// The tier that applies at this quantity.
  static Tier tierFor(String family, int qty) {
    final p = products[family];
    if (p == null) return const Tier(1, 0);
    final list = tiers[p.tier] ?? tiers['photos']!;
    var best = list[0];
    for (final t in list) {
      if (qty >= t.min) best = t;
    }
    return best;
  }

  /// The full breakdown. Mirrors quote() in norcha-data.js exactly —
  /// including Math.round on the discount. Do not "improve" the rounding:
  /// the website is the reference implementation.
  static Quote? quote(String family, String key, int qty) {
    final unit = priceOf(family, key);
    if (unit == null) return null;
    final t = tierFor(family, qty);
    final gross = unit * qty;
    final discount = (gross * t.pct / 100).round();
    return Quote(
      unit: unit,
      qty: qty,
      gross: gross,
      pct: t.pct,
      discount: discount,
      total: gross - discount,
      lead: products[family]!.lead,
    );
  }

  /// Convenience: quote by size key alone when the family is unambiguous.
  static Quote? quoteByKey(String key, int qty) {
    for (final f in products.keys) {
      if (priceOf(f, key) != null) return quote(f, key, qty);
    }
    return null;
  }

  /// Money formatting — ETB with thousands separators, no decimals.
  /// Mirrors money() in norcha-data.js.
  static String money(num n) {
    final s = n.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${n < 0 ? '-' : ''}$buf ${Shop.currency}';
  }
}

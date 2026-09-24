// Norcha Print — the single source of truth for products, prices and lead times.
//
// PORTED FROM: feven-prints-v2/js/norcha-data.js  @ fcf4b70 (2026-09-24)
// This is a 1:1 port. If a number changes on the website, change it here too —
// test/pricing_parity_test.dart diffs the two implementations and fails on any
// disagreement of more than zero birr.
//
// ⚠️ [FEVEN] Every price below is marked TEMPORARY and must be confirmed before
// this app is handed to a real customer. They came from the existing website,
// not from the shop.
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

  /// Flip to false when Feven confirms the price sheet.
  static const pricesAreTemporary = true;
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
    'prints': Product('prints', Bi('Standard prints', 'መደበኛ ህትመት'), 0, 'photos', [
      PrintSize('std-10x15', '10 × 15 cm', 25),
      PrintSize('std-13x18', '13 × 18 cm', 40),
      PrintSize('std-15x21', '15 × 21 cm', 60),
      PrintSize('std-20x30', '20 × 30 cm', 120),
      PrintSize('std-a4', 'A4 · 21 × 30 cm', 150),
      PrintSize('std-a3', 'A3 · 30 × 42 cm', 280),
    ]),
    'canvas': Product('canvas', Bi('Canvas prints', 'የካንቫስ ህትመት'), 1, 'wall', [
      PrintSize('canvas-30x40', '30 × 40 cm', 950),
      PrintSize('canvas-40x60', '40 × 60 cm', 1600),
      PrintSize('canvas-60x80', '60 × 80 cm', 2700),
      PrintSize('canvas-80x120', '80 × 120 cm', 4600),
    ]),
    'books': Product('books', Bi('Photo books', 'የፎቶ መጽሐፍ'), 2, 'books', [
      PrintSize('book-20x20-20', '20 × 20 cm · 20 pages', 1800),
      PrintSize('book-21x21-30', '21 × 21 cm · 30 pages', 2600),
      PrintSize('book-28x28-40', '28 × 28 cm · 40 pages', 3800),
      PrintSize('book-30x30-80', '30 × 30 cm · 80 pages', 6400),
    ]),
    'frames': Product('frames', Bi('Framed prints', 'የተከፈፈ ህትመት'), 1, 'wall', [
      PrintSize('frame-a4', 'A4 framed', 600),
      PrintSize('frame-a3', 'A3 framed', 900),
      PrintSize('frame-40x60', '40 × 60 cm framed', 1500),
    ]),
    'calendars': Product('calendars', Bi('Wall calendars', 'የግድግዳ የቀን መቁጠሪያ'), 1, 'wall', [
      PrintSize('cal-a4', 'A4 wall calendar', 450),
      PrintSize('cal-a3', 'A3 wall calendar', 700),
    ]),
    // 🔴 tier: 'mugs' is DELIBERATELY its own ladder — a flat one.
    // Mugs already carry pack pricing in `sizes` (1/2/4 at 350/650/1200).
    // Applying a percentage ladder on top DOUBLE-DISCOUNTS: "2 mugs" came out
    // as 650 via the 2-pack and 644 via 350×2 −8%. Two prices for one order.
    // Do not "fix" this by giving mugs the `gifts` ladder.
    'mugs': Product('mugs', Bi('Photo mugs', 'የፎቶ ሙግ'), 0, 'mugs', [
      PrintSize('mug-1', '1 mug', 350),
      PrintSize('mug-2', '2 mugs', 650),
      PrintSize('mug-4', '4 mugs', 1200),
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
    // Mugs price by the pack, not by a percentage. Flat ladder keeps quote()
    // honest for them and leaves this key free for small goods that are NOT
    // pack-priced.
    'mugs': [Tier(1, 0)],
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

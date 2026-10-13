// Norcha Print — the ghost numerals.
//
// FROM THE WEBSITE, DELIBERATELY
// norchaprint.com carries one ornament-scale Ge'ez numeral behind each section
// that opens its order flow, at z-index -1 so it is a watermark and never sits
// behind text a person has to read. This is that device, in the app, one
// numeral per page:
//
//   Home  ፩  soft, top-right     (the first chapter)
//   Quote ፪  soft, top-right     (the second)
//   Order ፫  soft, top-left      (the third)
//   Upload ፬ soft, top-right     (the fourth)
//   Studio ፭ soft, top-right     (the fifth)
//
// WHY GE'EZ NUMERALS AND NOT LATIN ONES
// Because Latin numerals would be decoration, and these are identity. Ge'ez
// numerals are not a novelty font treatment — they are the numbers this shop's
// customers grew up reading on church calendars and printed price lists. A
// watermark of ፪ behind the quote page says "this was made here" in a way no
// amount of gold hairline does.
//
// 🔴 IT IS NEVER BEHIND TEXT. Every caller must place it as the first child of a
// Stack, so content paints over it. `ExcludeSemantics` + `IgnorePointer` below
// enforce that it is decoration and not an input target.
//
// ═══════════════════════════════════════════════════════════════════════════
// WHY THERE IS ONLY ONE TREATMENT NOW (soft fill), AND NO STROKE — Aug 2026
// ═══════════════════════════════════════════════════════════════════════════
//
// This file used to offer two treatments: a soft fill and a "woven outline"
// (GhostStyle.outline). The outline stroked the glyph via a `foreground` Paint
// with PaintingStyle.stroke, i.e. the Flutter equivalent of the site's
// `-webkit-text-stroke`.
//
// IT PRODUCED A DOUBLED NUMERAL, THROUGH THREE SEPARATE BUILDS.
//
// The stroke width was tuned twice, in opposite directions:
//
//     1.6            (0.67% of glyph)  -> still doubled
//     size * 0.045   (4.6%)            -> EIGHT TIMES too thick, worse
//
// Both attempts failed because the RATIO WAS NEVER THE BUG. Two things were:
//
//   1. `strokeWidth` is centred on the glyph CONTOUR — half of it is drawn
//      INSIDE the letterform. Push it past the width of a thin stroke and it
//      eats straight through, leaving two parallel hairlines. That is the
//      doubling.
//
//   2. Worse: the app strokes a DIFFERENT TYPEFACE than the site does.
//      The site's `.ghost-num` resolves through
//          --display: 'EB Garamond','Bricolage Grotesque','Noto Sans Ethiopic',…
//      For Ge'ez, only one entry in that stack has the glyphs: Noto Sans
//      Ethiopic (sans, own subset, 167 glyphs). This app strokes
//      NorchaTypeFace.amharic = Noto Serif Ethiopic (serif, 860 glyphs).
//      Different contours, different stem weights. The site's measured 1.7px
//      was measured against outlines this app has never drawn.
//
// So the outline was never one value away from working. It was copying a
// number from a reference implementation while rendering a different glyph.
//
// WHAT WE DID INSTEAD — the site's OWN default.
// A full pass over feven-prints-v2/css/style.css found `-webkit-text-stroke`
// in exactly TWO places, both inside the single @supports block that defines
// .ghost-num--outline. Nothing else in the site strokes anything.
// And of the site's eight ghost pages, FOUR use the plain soft fill — it is
// the DEFAULT treatment (bare `class="ghost-num"`). Outline is the exception.
//
// Soft fill is `color: gold` + theme opacity. No Paint, no contour, no stroke
// width, no ratio. **There is no code path left that can double.**
//
// The soft numbers are the site's, copied exactly:
//     .ghost-num--soft { opacity: .13 }
//     [data-theme="dark"] .ghost-num--soft { opacity: .17 }
// which is precisely what NorchaColors.ghostOpacity already carries
// (light 0.13 / dark 0.17) — so the theme needed no change at all.
//
// IF ANYONE WANTS THE WOVEN OUTLINE BACK:
// Do not re-add a stroke to this file. Bundle the site's own Ethiopic face
// (fonts/noto-ethiopic-slim.woff2 in feven-prints-v2) as a SECOND font family
// and use it ONLY for the watermark, so the stroke ratio transfers against the
// outlines it was actually measured on. Then it can be tuned honestly.

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Ge'ez numerals, as the shop reads them. ፩ is one, ፲ is ten.
class GeezNumeral {
  static const one = '\u1369';   // ፩
  static const two = '\u136A';   // ፪
  static const three = '\u136B'; // ፫
  static const four = '\u136C';  // ፬
  static const five = '\u136D';  // ፭
  static const six = '\u136E';   // ፮
  static const seven = '\u136F'; // ፯
  static const eight = '\u1370'; // ፰
  static const nine = '\u1371';  // ፱
  static const ten = '\u1372';   // ፲

  static const list = [one, two, three, four, five, six, seven, eight, nine, ten];

  /// 1-based index to numeral. Wraps, because a page with no numeral is worse
  /// than a repeated one.
  static String at(int n) => list[(n - 1) % list.length];
}

/// The watermark itself. Absolutely positioned inside whatever Stack calls it.
///
/// There is only one treatment. An earlier `GhostStyle` enum offered a stroked
/// "woven outline" as well; it was removed because stroking the serif face this
/// app renders is what produced the doubled numeral. See the header comment.
class GhostNumeral extends StatelessWidget {
  final String numeral;
  final bool left;
  final double size;

  const GhostNumeral({
    super.key,
    required this.numeral,
    this.left = false,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    // The website measured a .10 opacity numeral as a 4/255 channel difference
    // on cream — present in the DOM, invisible to a human. It raised the value
    // until it read as a watermark rather than a rumour. Same lesson here: the
    // opacity comes from the theme so dark and light each get their own
    // (0.13 light, 0.17 dark — the site's own .ghost-num--soft numbers).
    //
    // No multiplier for a second treatment any more. There is no second
    // treatment, and the old `outline ? 2.4 : 1.0` is part of the bug's history:
    // it was compensating for a stroke's thinness by over-brightening the fill
    // it was drawn over.
    final opacity = c.ghostOpacity;

    return Positioned(
      top: 8,
      right: left ? null : 12,
      left: left ? 12 : null,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Opacity(
            // Clamped the way the site guards its own value: a watermark that
            // goes missing is worse than one that is slightly too quiet, but a
            // numeral bright enough to compete with copy is worse than both.
            opacity: opacity.clamp(0.0, 0.42),
            child: Text(
              numeral,
              style: TextStyle(
                fontFamily: NorchaTypeFace.amharic,
                fontSize: size,
                height: 1.0,
                // ⚠️ w400, NOT w600.
                //
                // The site never sets a font-weight on .ghost-num at all, so it
                // inherits 400. This app used to force w600 here — and on a
                // variable font that is a real, visible difference in stem
                // weight (Noto Serif Ethiopic's wght axis runs 100–900 with a
                // default of 400). It was never the doubling, but it was a
                // second silent divergence from the reference, and on a filled
                // watermark the lighter weight is the correct one: the numeral
                // recedes, which is the entire job.
                fontWeight: FontWeight.w400,
                color: Brand.gold.withOpacity(1.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

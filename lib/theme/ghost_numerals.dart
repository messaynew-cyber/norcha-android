// Norcha Print — the ghost numerals.
//
// FROM THE WEBSITE, DELIBERATELY
// norchaprint.com carries one ornament-scale Ge'ez numeral behind each section
// that opens its order flow, at z-index -1 so it is a watermark and never sits
// behind text a person has to read. Three treatments exist there — a soft fill,
// a woven outline, and a left-positioned variant — "the same device, one shape,
// never a new motif".
//
// This is that device, in the app, one numeral per page:
//
//   Home  ፩  soft, top-right     (the first chapter)
//   Quote ፪  outline, top-right  (the second)
//   Order ፫  outline, top-left   (the third)
//   Upload ፬ soft, top-right     (the fourth)
//   Studio ፭ outline, top-right  (the fifth)
//
// WHY GE'EZ NUMERALS AND NOT LATIN ONES
// Because Latin numerals would be decoration, and these are identity. Ge'ez
// numerals are not a novelty font treatment — they are the numbers this shop's
// customers grew up reading on church calendars and printed price lists. A
// watermark of ፪ behind the quote page says "this was made here" in a way no
// amount of gold hairline does.
//
// 🔴 IT IS NEVER BEHIND TEXT. Every caller must place it as the first child of a
// Stack, under a scrim, or on a page whose header has clear space. A watermark
// behind a price is a bug, not an effect.


import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The Ge'ez numerals, 1..10 and the tens. Enough for any page count this app
/// will ever have, and ፲/፳/፴/፵/፶/፷/፸/፹/፺ are the tens the website uses.
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

enum GhostStyle {
  /// Filled, very low opacity. The quietest of the three.
  soft,

  /// Woven outline — a stroke instead of a fill. The tibeb idea at glyph scale.
  outline,
}

/// The watermark itself. Absolutely positioned inside whatever Stack calls it.
class GhostNumeral extends StatelessWidget {
  final String numeral;
  final GhostStyle style;
  final bool left;
  final double size;

  const GhostNumeral({
    super.key,
    required this.numeral,
    this.style = GhostStyle.soft,
    this.left = false,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    // The website measured a .10 opacity numeral as a 4/255 channel difference
    // on cream — present in the DOM, invisible to a human. It raised the value
    // until it read as a watermark rather than a rumour. Same lesson here: the
    // opacity comes from the theme so dark and light each get their own.
    final opacity = c.ghostOpacity * (style == GhostStyle.outline ? 2.4 : 1.0);

    final text = Text(
      numeral,
      style: TextStyle(
        fontFamily: NorchaTypeFace.amharic,
        fontSize: size,
        height: 1.0,
        fontWeight: FontWeight.w600,
        color: style == GhostStyle.soft
            ? Brand.gold.withOpacity(opacity)
            : Colors.transparent,
      ),
    );

    return Positioned(
      top: 8,
      right: left ? null : 12,
      left: left ? 12 : null,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Opacity(
            // Outline strokes cannot be done with a plain TextStyle colour, so
            // the woven variant is a stroked paint. Guarded the same way the
            // website guards it — an unsupported stroke renders NOTHING, which
            // is worse than rendering something quieter.
            opacity: style == GhostStyle.outline ? opacity.clamp(0.0, 0.42) : 1.0,
            child: style == GhostStyle.soft
                ? text
                : _StrokedText(
                    text: numeral,
                    size: size,
                    colour: Brand.gold,
                    // 🔴 THE STROKE MUST SCALE WITH THE GLYPH.
                    //
                    // This was a fixed 1.6, tuned when the Ethiopic family was
                    // supplied by the system font. The real Noto Serif Ethiopic
                    // at w600 has stems ~30px wide at size 250 (measured), so a
                    // 1.6px stroke centred on such a stem draws two hairlines
                    // 30px apart with nothing between — a hollow stem that at
                    // this scale reads as a SECOND OFFSET COPY of the numeral.
                    // That is the "doubled" appearance.
                    //
                    // 0.045 of the size gives ~11px at the 250px numeral.
                    // Measured: a stem at that size is ~30px wide, so the two
                    // edges of the outline sit ~19px apart — close enough to
                    // read as ONE outlined shape rather than two separate
                    // copies. At the old fixed 1.6 the gap was 28px, almost a
                    // full stem width, which is why it looked doubled.
                    //
                    // Tying it to `size` keeps that proportion right whatever
                    // the numeral is drawn at, instead of being a magic number
                    // that silently broke the moment the font changed.
                    strokeWidth: (size * 0.045).clamp(1.0, 14.0),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A stroked glyph. Flutter has no text-stroke equivalent of -webkit-text-stroke,
/// so this paints the glyph as a Path and strokes it — which is what the
/// website is doing anyway, just spelled differently.
class _StrokedText extends StatelessWidget {
  final String text;
  final double size;
  final Color colour;
  final double strokeWidth;

  const _StrokedText({
    required this.text,
    required this.size,
    required this.colour,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.85, size * 0.9),
      painter: _StrokePainter(
        text: text,
        size: size,
        colour: colour,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final String text;
  final double size;
  final Color colour;
  final double strokeWidth;

  _StrokePainter({
    required this.text,
    required this.size,
    required this.colour,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // A stroked glyph, the Flutter equivalent of -webkit-text-stroke.
    //
    // Flutter cannot stroke a TextStyle directly, but it CAN paint the text
    // with a `foreground` Paint instead of a `color`, and a Paint with
    // PaintingStyle.stroke does exactly the woven-outline thing the website
    // does. That is the whole implementation — no glyph-outline extraction, no
    // custom path building, and it works for Ethiopic the same as for Latin.
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: NorchaTypeFace.amharic,
          fontSize: size,
          height: 1.0,
          fontWeight: FontWeight.w600,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeJoin = StrokeJoin.round
            ..color = colour,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Centred on the box the CustomPaint was given.
    final dx = (canvasSize.width - painter.width) / 2;
    final dy = (canvasSize.height - painter.height) / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.text != text || old.size != size || old.colour != colour;
}

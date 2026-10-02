// Norcha Print — the Ethiopian decorative layer.
//
// Every motif here is drawn from something the shop's own website already uses
// (DESIGN.md), so the app and the site share one visual vocabulary rather than
// the app inventing a rival one. Nothing here is a new invention — the point is
// that a customer who has seen norchaprint.com recognises these.
//
// THE FOUR MOTIFS
//   1. tibeb     — the woven border on a netela. A hairline with a gold tick.
//   2. selvedge  — three dyed threads: emerald, gold, oxblood. Site rule: used
//                  at the very top of a page and NOWHERE else, never a
//                  tricolour repeated. Two legal places only.
//   3. adey abeba— the Meskel daisy. The site's only rounded glyph and its
//                  bullet mark. Here it marks list items and section openers.
//   4. telafi    — the woven band: a repeated diamond/chevron strip. Drawn as
//                  a CustomPainter so it tiles at any width without an asset.
//
// 🔴 RESTRAINT IS PART OF THE DESIGN
// DESIGN.md: "Do not introduce a new ornament without retiring one." Four
// motifs is the budget. Adding a fifth because it looks nice is how a design
// language turns into decoration.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The ceremonial selvedge: three dyed threads, emerald → gold → oxblood.
/// Site rule — the top of a page, and above the footer. Nowhere else.
class Selvedge extends StatelessWidget {
  final double height;
  const Selvedge({super.key, this.height = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF17532F), // deep emerald
            Color(0xFFB8912F), // antique gold
            Color(0xFF7E211C), // oxblood
          ],
        ),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// The tibeb: a hairline rule with a gold tick at one end. The recurring
/// ornament — it opens a section without shouting.
class TibebRule extends StatelessWidget {
  final double width;
  final Color? colour;
  final Color? tick;

  const TibebRule({super.key, this.width = 46, this.colour, this.tick});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return SizedBox(
      width: width,
      height: 2,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: colour ?? c.line)),
          const SizedBox(width: 4),
          Container(
            width: 7,
            height: 2,
            decoration: BoxDecoration(
              color: tick ?? Brand.gold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// The woven telafi band — a repeated diamond-and-chevron strip, drawn rather
/// than shipped as an image so it tiles at any width and takes the theme's
/// colours.
///
/// This is the closest thing in the app to actual tibeb weaving: the diamonds
/// alternate between the flag's three colours the way a woven border alternates
/// dyed threads, and the hairline above and below is the fold.
class TelafiBand extends StatelessWidget {
  final double height;
  final double opacity;
  final bool reverse;

  const TelafiBand({
    super.key,
    this.height = 14,
    this.opacity = 1.0,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TelafiPainter(
            line: c.line,
            reverse: reverse,
            dark: c.isDark,
          ),
        ),
      ),
    );
  }
}

class _TelafiPainter extends CustomPainter {
  final Color line;
  final bool reverse;
  final bool dark;

  _TelafiPainter({
    required this.line,
    required this.reverse,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final mid = h / 2;

    // The three dyed threads, in the order DESIGN.md uses them.
    // Muted on light, lifted on dark so they read as cloth rather than as
    // stripes — a flag-bright green on cream looks like a highlighter.
    final colours = dark
        ? [
            const Color(0xFF3E9C78),
            const Color(0xFFC1922B),
            const Color(0xFFB4544C),
          ]
        : [
            const Color(0xFF17532F),
            const Color(0xFFB8912F),
            const Color(0xFF7E211C),
          ];

    // Hairlines top and bottom — the folds.
    final fold = Paint()
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 0.5), Offset(size.width, 0.5), fold);
    canvas.drawLine(Offset(0, h - 0.5), Offset(size.width, h - 0.5), fold);

    // Diamonds. Spacing is fixed so the band reads as a repeat, not a gradient.
    const step = 16.0;
    final count = (size.width / step).ceil() + 1;

    for (var i = 0; i < count; i++) {
      final x = i * step + (reverse ? step / 2 : 0);
      final colour = colours[i % 3];
      final fill = Paint()
        ..color = colour.withOpacity(dark ? 0.75 : 0.55)
        ..style = PaintingStyle.fill;

      // A diamond: four points around a centre, squashed vertically so the
      // band stays a band rather than becoming a row of squares.
      final path = Path()
        ..moveTo(x, mid - 3.2)
        ..lineTo(x + 4.4, mid)
        ..lineTo(x, mid + 3.2)
        ..lineTo(x - 4.4, mid)
        ..close();
      canvas.drawPath(path, fill);

      // A hairline through the middle of each diamond — the thread.
      final thread = Paint()
        ..color = colour
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(x - 1.6, mid), Offset(x + 1.6, mid), thread);
    }
  }

  @override
  bool shouldRepaint(_TelafiPainter old) =>
      old.line != line || old.reverse != reverse || old.dark != dark;
}

/// Adey abeba — the Meskel daisy. The site uses it as a bullet; here it marks
/// the same things: list leads and section openers.
///
/// Eight petals and a centre, drawn at whatever size is asked for. Small it
/// reads as a bullet; large it reads as a flower.
class AdeyAbeba extends StatelessWidget {
  final double size;
  final Color? colour;
  final bool filled;

  const AdeyAbeba({
    super.key,
    this.size = 9,
    this.colour,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DaisyPainter(
          colour: colour ?? Brand.gold,
          filled: filled,
          ink: c.ink,
        ),
      ),
    );
  }
}

class _DaisyPainter extends CustomPainter {
  final Color colour;
  final bool filled;
  final Color ink;

  _DaisyPainter({
    required this.colour,
    required this.filled,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final petal = Paint()
      ..color = colour
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, r * 0.16);
    final core = Paint()..color = filled ? colour : ink;

    // Eight petals, evenly spaced. The Meskel daisy is drawn as a ring of
    // strokes rather than a filled flower so it stays legible at 8px.
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      canvas.drawLine(
        centre + Offset(math.cos(a) * r * 0.28, math.sin(a) * r * 0.28),
        centre + Offset(math.cos(a) * r * 0.92, math.sin(a) * r * 0.92),
        petal,
      );
    }
    canvas.drawCircle(centre, r * 0.20, core);
  }

  @override
  bool shouldRepaint(_DaisyPainter old) =>
      old.colour != colour || old.filled != filled || old.ink != ink;
}

/// A section header in the shop's own idiom: the daisy, the label, a rule.
///
/// This replaces the plain "SECTION" text that every other app has. One call
/// site, so the ornament cannot drift between pages.
class EthiopianSectionHeader extends StatelessWidget {
  final String label;
  final String? trailing;
  final EdgeInsetsGeometry padding;

  const EthiopianSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(24, 26, 24, 12),
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          const AdeyAbeba(size: 10),
          const SizedBox(width: 9),
          Text(label, style: NorchaType.sectionLabel(c)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: c.line)),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(trailing!, style: NorchaType.bodySmall(c).copyWith(fontSize: 11.5)),
          ],
        ],
      ),
    );
  }
}

/// A tibeb-framed card. The woven border drawn as a proper frame rather than a
/// left edge — used for the few things that should feel like a printed object
/// (the delivery estimate, the retention promise).
class TibebFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  const TibebFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return Stack(
      children: [
        // The content, inset so the frame sits outside it.
        Padding(
          padding: const EdgeInsets.all(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Corners.md - 1),
            child: DecoratedBox(
              decoration: BoxDecoration(color: c.card),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
        // The woven edge, drawn on top of the corners.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TibebFramePainter(
                accent: accent ?? Brand.gold,
                line: c.line,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TibebFramePainter extends CustomPainter {
  final Color accent;
  final Color line;

  _TibebFramePainter({required this.accent, required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(Corners.md.toDouble());
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final rr = RRect.fromRectAndRadius(rect, r);

    // The frame itself.
    canvas.drawRRect(
      rr,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Accent ticks at the four corners — the tibeb mark, scaled to a frame.
    final tick = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const len = 12.0;
    const inset = 10.0;
    // top-left
    canvas.drawLine(Offset(inset, 1), Offset(inset + len, 1), tick);
    // top-right
    canvas.drawLine(
        Offset(size.width - inset - len, 1), Offset(size.width - inset, 1), tick);
    // bottom-left
    canvas.drawLine(
        Offset(inset, size.height - 1), Offset(inset + len, size.height - 1), tick);
    // bottom-right
    canvas.drawLine(Offset(size.width - inset - len, size.height - 1),
        Offset(size.width - inset, size.height - 1), tick);
  }

  @override
  bool shouldRepaint(_TibebFramePainter old) =>
      old.accent != accent || old.line != line;
}

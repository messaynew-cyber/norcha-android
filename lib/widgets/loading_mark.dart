// Norcha Print — the loading mark.
//
// WHAT IT IS
// The ኖ monogram, drawn rather than shown: the gold ring sweeps closed, then
// the character writes itself in, then it all breathes. About 1.6 seconds.
//
// WHY NOT A SPINNER
// A Material CircularProgressIndicator is the single strongest signal that an
// app is a template. This app's whole argument is that it is a studio's, not a
// template's, so the one moment a customer is forced to wait is exactly the
// wrong moment to look generic.
//
// The ring is drawn with a sweep gradient so it has a bright arc and a faint
// one — a solid ring reads as a progress indicator, a weighted one reads as a
// stroke of ink. Same information, better manners.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/ghost_numerals.dart';

class LoadingMark extends StatefulWidget {
  final double size;
  final String? label;

  const LoadingMark({super.key, this.size = 96, this.label});

  @override
  State<LoadingMark> createState() => _LoadingMarkState();
}

class _LoadingMarkState extends State<LoadingMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return Semantics(
      label: 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _MarkPainter(
                  t: _c.value,
                  ink: c.ink,
                  ground: c.ground,
                ),
              ),
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 18),
            Text(
              widget.label!,
              style: NorchaType.bodySmall(c).copyWith(letterSpacing: 0.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final double t; // 0..1, repeating
  final Color ink;
  final Color ground;

  _MarkPainter({required this.t, required this.ink, required this.ground});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.40;

    // Phase 1 (0.00-0.45): the ring sweeps closed, 0 -> 360 degrees.
    final ringT = Curves.easeOutCubic.transform((t / 0.45).clamp(0.0, 1.0));
    final sweep = ringT * math.pi * 2;

    // A weighted arc: bright where the stroke is "fresh", faint where it has
    // been sitting. Reads as ink, not as a progress meter.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Brand.gold.withOpacity(0.18),
          Brand.gold.withOpacity(0.85),
          Brand.gold.withOpacity(0.18),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: centre, radius: r));

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r),
      -math.pi / 2,
      sweep,
      false,
      ring,
    );

    // Phase 2 (0.35-0.85): the glyph fades and rises in, with a slight scale so
    // it settles rather than appearing.
    final glyphT =
        Curves.easeOutBack.transform(((t - 0.35) / 0.5).clamp(0.0, 1.0));

    if (glyphT > 0) {
      final scale = 0.86 + (0.14 * glyphT);
      final dy = (1 - glyphT) * size.height * 0.06;

      canvas.save();
      canvas.translate(centre.dx, centre.dy + dy);
      canvas.scale(scale);

      final tp = TextPainter(
        text: TextSpan(
          text: GeezNumeral.six, // ፮ is not used as a page numeral; free as a mark
          style: TextStyle(
            fontFamily: NorchaTypeFace.amharic,
            fontSize: size.height * 0.36,
            height: 1.0,
            fontWeight: FontWeight.w600,
            color: ink.withOpacity(glyphT.clamp(0.0, 1.0)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Phase 3 (0.75-1.0): a slow breath so a long wait is not frozen.
    if (t > 0.75) {
      final breath = math.sin((t - 0.75) / 0.25 * math.pi);
      final halo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Brand.gold.withOpacity(0.22 * breath);
      canvas.drawCircle(centre, r + (3 * breath), halo);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t || old.ink != ink;
}

/// A full-screen holding page for the few genuinely slow things (an upload
/// starting, the app's first frame). Not for inline waits — those use
/// [LoadingMark] at a smaller size so the layout does not jump.
class LoadingScreen extends StatelessWidget {
  final String label;
  const LoadingScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: c.ground),
      child: Center(child: LoadingMark(label: label)),
    );
  }
}

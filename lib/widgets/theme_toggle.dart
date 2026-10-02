// Norcha Print — the theme switch.
//
// A sun/moon that morphs rather than two icons that swap. The icon rotates and
// the rays retract as it crosses — a small thing, but the toggle is the one
// control a customer touches specifically to see it happen, so it is the wrong
// place to be lazy.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class ThemeToggle extends StatefulWidget {
  final ThemeController controller;
  const ThemeToggle({super.key, required this.controller});

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.medium,
  );

  @override
  void initState() {
    super.initState();
    _c.value = widget.controller.mode == NorchaThemeMode.dark ? 1 : 0;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final going = widget.controller.mode == NorchaThemeMode.light;
    // Start the animation immediately; do not wait on the write to disk. The
    // switch must feel instant even if SharedPreferences is slow.
    if (going) {
      _c.forward();
    } else {
      _c.reverse();
    }
    await widget.controller.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return Semantics(
      button: true,
      label: widget.controller.mode == NorchaThemeMode.dark
          ? 'Switch to light theme'
          : 'Switch to dark theme',
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.line),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(_c.value);
              return Transform.rotate(
                angle: t * math.pi,
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _SunMoonPainter(t: t, colour: c.ink, gold: Brand.gold),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One shape that is a sun at t=0 and a moon at t=1.
///
/// The trick is the crescent: a circle with a second circle subtracted from it,
/// where the subtracting circle slides in from off-canvas. The rays fade as it
/// arrives. No cross-fade between two icons, so there is never a frame with
/// both or neither.
class _SunMoonPainter extends CustomPainter {
  final double t;
  final Color colour;
  final Color gold;

  _SunMoonPainter({required this.t, required this.colour, required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);

    // Core disc: shrinks slightly as it becomes a moon.
    final coreR = 6.0 - (1.4 * t);
    final body = Paint()
      ..color = Color.lerp(gold, colour, t)!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(centre, coreR, body);

    // Rays: eight, retracting and rotating away.
    if (t < 1) {
      final ray = Paint()
        ..color = Color.lerp(gold, colour, t)!.withOpacity(1 - t)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < 8; i++) {
        final a = (i / 8) * math.pi * 2 + (t * 0.6);
        final r1 = coreR + 2.2 + (2.5 * t);
        final r2 = r1 + 2.4 * (1 - t);
        canvas.drawLine(
          centre + Offset(math.cos(a) * r1, math.sin(a) * r1),
          centre + Offset(math.cos(a) * r2, math.sin(a) * r2),
          ray,
        );
      }
    }

    // The crescent bite: an offset disc SUBTRACTED from the core so the disc
    // turns into a moon. Using a Path difference rather than a blend mode means
    // it works over any background — a clear() would punch a hole through
    // whatever is behind the toggle, which on a scrolling page is visible.
    if (t > 0.02) {
      final biteCentre = centre + Offset(-coreR * 1.5 * t, -coreR * 0.75 * t);
      final biteR = coreR * 1.12;

      final outer = Path()..addOval(Rect.fromCircle(center: centre, radius: coreR));
      final inner = Path()..addOval(Rect.fromCircle(center: biteCentre, radius: biteR));
      final crescent = Path.combine(PathOperation.difference, outer, inner);

      canvas.drawPath(crescent, body);
    }
  }

  @override
  bool shouldRepaint(_SunMoonPainter old) => old.t != t || old.colour != colour;
}

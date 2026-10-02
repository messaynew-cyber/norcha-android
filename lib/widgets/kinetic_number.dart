// A number that moves when it changes.
//
// This is the single most important piece of motion in the app. A price that
// snaps from 250 to 1,200 tells you it changed. A price that rolls and settles
// tells you what you are doing is worth money. Same information, and only one
// of them is worth showing someone.
//
// Material 3 Expressive leans on exactly this: motion carries meaning, not just
// polish.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KineticNumber extends StatelessWidget {
  final String value;
  final TextStyle style;
  final Duration duration;

  const KineticNumber({
    super.key,
    required this.value,
    required this.style,
    this.duration = Motion.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.42),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return ClipRect(
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
      // The key is the value itself, so AnimatedSwitcher only remounts when the
      // number actually changes — not on every rebuild of the parent.
      child: Text(value, key: ValueKey(value), style: style),
    );
  }
}

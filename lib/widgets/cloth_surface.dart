// Norcha Print — the cloth surface.
//
// One widget, four levels, no way to cheat: screens declare WHERE a thing sits
// and this builds the edge, the shadow and the fold consistently, in either
// theme.
//
// Funnelling everything through one widget is the whole point. A design system
// survives only if the easy path is also the correct path — the moment someone
// hand-rolls a Container with a border, the edges stop agreeing with each other
// and the app starts looking assembled rather than designed.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum DepthLevel {
  /// Page ground. Never carries text directly.
  ground,

  /// Content panels and repeated rows. Card fill + hairline. NO blur cost.
  sheet,

  /// Selected / interactive. Lift + an accent edge.
  raised,

  /// The CTA, the total, the bottom bar. Floats with a real, visible shadow.
  float,
}

class Depth {
  /// Backdrop blur sigma. Zero for list rows on purpose — a blurred row in a
  /// list is a jank engine on a mid-range phone.
  static const Map<DepthLevel, double> blur = {
    DepthLevel.ground: 0,
    DepthLevel.sheet: 0,
    DepthLevel.raised: 16,
    DepthLevel.float: 24,
  };

  /// Contact shadow: [blurRadius, yOffset, alpha].
  ///
  /// Dark grounds need MORE shadow alpha than light ones: a 7% shadow that
  /// reads as depth on cream disappears entirely on near-black, where the only
  /// cue left is the edge highlight.
  static const Map<DepthLevel, List<double>> shadowLight = {
    DepthLevel.ground: [0, 0, 0],
    DepthLevel.sheet: [14, 3, 0.07],
    DepthLevel.raised: [20, 6, 0.10],
    DepthLevel.float: [30, 12, 0.14],
  };

  static const Map<DepthLevel, List<double>> shadowDark = {
    DepthLevel.ground: [0, 0, 0],
    DepthLevel.sheet: [16, 4, 0.34],
    DepthLevel.raised: [22, 7, 0.42],
    DepthLevel.float: [32, 13, 0.52],
  };

  static double sigmaOf(DepthLevel l) => blur[l] ?? 0;
  static List<double> shadowOf(DepthLevel l, bool dark) =>
      (dark ? shadowDark : shadowLight)[l] ?? const [0, 0, 0];
}

class ClothSurface extends StatelessWidget {
  final Widget child;
  final DepthLevel level;

  /// A product accent (green/red/yellow) on the edges. Reserved for product
  /// cards; using it everywhere makes it meaningless.
  final Color? accent;

  /// Real backdrop blur. Only valid with something painted beneath — on a list
  /// row this is a performance bug.
  final bool blurBackdrop;

  final BorderRadius? radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const ClothSurface({
    super.key,
    required this.child,
    this.level = DepthLevel.sheet,
    this.accent,
    this.blurBackdrop = false,
    this.radius,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final r = radius ?? BorderRadius.circular(Corners.md);
    final spec = Depth.shadowOf(level, c.isDark);
    final fill = level == DepthLevel.ground ? c.ground : c.card;

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          splashColor: Brand.action(c).withOpacity(0.07),
          highlightColor: Brand.action(c).withOpacity(0.03),
          child: content,
        ),
      );
    }

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: r),
      child: content,
    );

    if (blurBackdrop && Depth.sigmaOf(level) > 0) {
      final sigma = Depth.sigmaOf(level);
      surface = ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: surface,
        ),
      );
    }

    // The fold. On light: a white top edge where paper turns toward the light.
    // On dark: a faint light top edge instead, because a surface that absorbs
    // cannot have a bright specular the way paper does.
    final edge = Border(
      top: BorderSide(color: accent ?? c.foldTop, width: 1),
      left: BorderSide(color: accent ?? c.line, width: 1),
      right: BorderSide(color: accent ?? c.line, width: 1),
      bottom: BorderSide(color: accent ?? c.line, width: 1),
    );

    surface = DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, border: edge),
      child: surface,
    );

    if (spec[2] > 0) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: (c.isDark ? Colors.black : c.ink)
                  .withOpacity(spec[2]),
              blurRadius: spec[0],
              offset: Offset(0, spec[1]),
            ),
          ],
        ),
        child: surface,
      );
    }

    return ClipRRect(borderRadius: r, child: surface);
  }
}

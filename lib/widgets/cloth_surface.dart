// Norcha Print — the cloth surface.
//
// The light-ground replacement for GlassSurface. One widget, four levels, no
// way to cheat: screens declare WHERE a thing sits and this builds the edge,
// the shadow and the fold consistently.
//
// Funnelling everything through one widget is the whole point. A design system
// survives only if the easy path is also the correct path — the moment someone
// hand-rolls a Container with a border, the edges stop agreeing with each other
// and the app starts looking assembled rather than designed.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../theme/netela.dart';
import '../theme/norcha_theme.dart';

class ClothSurface extends StatelessWidget {
  final Widget child;
  final DepthLevel level;

  /// A product accent (green/red/yellow) on the left edge — the woven trim.
  /// Reserved for product cards; using it everywhere makes it meaningless.
  final Color? accent;

  /// Enables a real backdrop blur. Only valid when something is actually
  /// painted beneath. Setting this on a list row is a performance bug.
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
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.circular(NorchaShape.md);
    final shadowSpec = Depth.shadow[level] ?? const [0, 0, 0];
    final fill = Depth.surfaceOf(level);

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          splashColor: NorchaPalette.pine.withOpacity(0.07),
          highlightColor: NorchaPalette.pine.withOpacity(0.03),
          child: content,
        ),
      );
    }

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: r),
      child: content,
    );

    if (blurBackdrop && Depth.sigmaOf(level) > 0) {
      surface = ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: Depth.sigmaOf(level),
            sigmaY: Depth.sigmaOf(level),
          ),
          child: surface,
        ),
      );
    }

    final edge = Cloth.edge(level, accent: accent);
    if (edge != null) {
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: r, border: edge),
        child: surface,
      );
    }

    if (shadowSpec[2] > 0) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: NorchaPalette.ink.withOpacity(shadowSpec[2]),
              blurRadius: shadowSpec[0],
              offset: Offset(0, shadowSpec[1]),
            ),
          ],
        ),
        child: surface,
      );
    }

    return ClipRRect(borderRadius: r, child: surface);
  }
}

// Norcha Print — the glass surface.
//
// SPEC: docs/DESIGN-LUXURY.md
//
// One widget, four levels, no way to cheat. Screens declare WHERE a thing sits
// in space and this builds the lighting consistently. The reason to funnel
// everything through one widget is that a design system only survives if the
// easy path is also the correct path — the moment someone hand-rolls a
// Container with a border, the lighting stops agreeing with itself and the app
// starts looking assembled rather than designed.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../theme/depth.dart';
import '../theme/norcha_theme.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final DepthLevel level;

  /// Gold rim instead of white — reserved for `float` and the active selection.
  /// Overusing it is the fastest way to make gold stop meaning anything.
  final bool goldRim;

  /// Enables the real backdrop blur. Only valid when there is actually something
  /// painted beneath. Setting this on a list row is a performance bug.
  final bool blurBackdrop;

  final BorderRadius? radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const GlassSurface({
    super.key,
    required this.child,
    this.level = DepthLevel.sheet,
    this.goldRim = false,
    this.blurBackdrop = false,
    this.radius,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.circular(NorchaShape.md);
    final overlayAlpha = Depth.overlayOf(level);
    final shadowSpec = Depth.shadow[level] ?? const [0, 0, 0];

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: r,
        splashColor: NorchaPalette.gold.withValues(alpha: 0.08),
        highlightColor: NorchaPalette.gold.withValues(alpha: 0.04),
        child: content,
      );
    }

    // Base fill. Sheet level is the cheap path: a translucent white overlay on
    // the (already dark) ground, with no filter at all.
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: overlayAlpha),
        borderRadius: r,
      ),
      child: content,
    );

    // Optional real blur. BackdropFilter must sit directly above what it blurs,
    // and it is expensive — see the performance rules in depth.dart.
    if (blurBackdrop && Depth.sigmaOf(level) > 0) {
      surface = ClipRRect(
        borderRadius: r,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: Depth.sigmaOf(level),
            sigmaY: Depth.sigmaOf(level),
          ),
          child: surface,
        ),
      );
    }

    // The specular edge. This is the detail that reads as glass.
    final border = Glass.specular(level, gold: goldRim);
    if (border != null) {
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: r, border: border),
        child: surface,
      );
    }

    // Contact shadow — only meaningful above `sheet`.
    if (shadowSpec[2] > 0) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowSpec[2]),
              blurRadius: shadowSpec[0],
              offset: Offset(0, shadowSpec[1]),
            ),
          ],
        ),
        child: surface,
      );
    }

    return ClipRRect(
      borderRadius: r,
      clipBehavior: clipBehavior,
      child: surface,
    );
  }
}

/// The atmospheric ground layer.
///
/// Sits behind everything, moves at [DepthParallax.factor] of the scroll speed,
/// and carries NO text — it is atmosphere, not content. The scrim is not
/// optional: a photo behind text without a scrim is unreadable on a bad screen
/// in daylight, which is where this app is actually used.
class AtmosphericGround extends StatelessWidget {
  final String? imageAsset;
  final Widget child;
  final ScrollController? scrollController;

  const AtmosphericGround({
    super.key,
    required this.child,
    this.imageAsset,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    Widget ground = const ColoredBox(color: NorchaPalette.void_);

    if (imageAsset != null) {
      ground = Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        // The ground is decoration. It must never make the app wait.
        errorBuilder: (_, __, ___) =>
            const ColoredBox(color: NorchaPalette.void_),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Parallax: the background scrolls slower than the content above it.
        AnimatedBuilder(
          animation: scrollController ?? ScrollController(),
          builder: (context, g) {
            final offset = scrollController?.hasClients == true
                ? (scrollController!.offset * -DepthParallax.factor)
                : 0.0;
            return Transform.translate(
              offset: Offset(0, offset),
              child: g,
            );
          },
          child: ground,
        ),

        // The scrim. Deliberately strong at the bottom so the floating CTA has
        // something to sit against.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                NorchaPalette.void_.withValues(alpha: 0.72),
                NorchaPalette.void_.withValues(alpha: 0.88),
                NorchaPalette.void_.withValues(alpha: 0.96),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),

        child,
      ],
    );
  }
}

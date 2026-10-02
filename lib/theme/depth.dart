// Norcha Print — the depth system.
//
// SPEC: docs/DESIGN-LUXURY.md
//
// WHY THIS FILE EXISTS SEPARATELY FROM THE COLOURS
// The previous direction had a good palette and a flat plane. Gold hairlines on
// near-black look expensive for about four seconds, and then every surface sits
// at the same distance from the glass and the screen stops having a foreground.
// Luxury on a screen is mostly *depth*: something is close, something is far,
// and the eye is told which is which without being told.
//
// So depth is not a decoration here. It is the hierarchy. Every surface declares
// a Z-level, and no two levels share lighting. If two things look equally close,
// one of them is wrong.
//
// 🔴 PERFORMANCE IS PART OF THE SPEC, NOT AN AFTERTHOUGHT
// Blur is the most expensive thing in this file. It is O(area), and three
// overlapping full-bleed blurs will drop frames on a mid-range device. The rules
// below are enforced by convention and documented so they cannot be forgotten:
//   - max 2 live BackdropFilters on screen at once
//   - the scrolling list NEVER sits under a blur
//   - repeated rows use DepthLevel.sheet (no filter), not a blur
//   - ImageFiltered over BackdropFilter when blurring a single widget

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// The four physical levels. See DESIGN-LUXURY.md §1.
enum DepthLevel {
  /// Atmospheric background. Image + dark scrim. Never carries text.
  ground,

  /// Content panels and repeated rows. Overlay + hairline, NO blur cost.
  sheet,

  /// Selected / interactive. Brighter overlay, gold hairline.
  raised,

  /// The CTA, the total, the nav bar. Floats above with a real shadow.
  float,
}

class Depth {
  /// Blur sigma per level. `ground` and `sheet` are 0 on purpose — the
  /// background is a pre-darkened image, and rows must stay cheap.
  static const Map<DepthLevel, double> blur = {
    DepthLevel.ground: 0,
    DepthLevel.sheet: 0, // overlay only — a blurred row in a list is a jank engine
    DepthLevel.raised: 22,
    DepthLevel.float: 30,
  };

  /// White overlay alpha. Glass catches light; a raised surface catches more.
  static const Map<DepthLevel, double> overlay = {
    DepthLevel.ground: 0,
    DepthLevel.sheet: 0.06,
    DepthLevel.raised: 0.10,
    DepthLevel.float: 0.13,
  };

  /// Contact shadow. [blur, y-offset, alpha]. `float` is the only level that
  /// casts a heavy shadow — that is what makes it read as physically above.
  static const Map<DepthLevel, List<double>> shadow = {
    DepthLevel.ground: [0, 0, 0],
    DepthLevel.sheet: [18, 4, 0.35],
    DepthLevel.raised: [26, 8, 0.45],
    DepthLevel.float: [40, 16, 0.55],
  };

  static double sigmaOf(DepthLevel level) => blur[level] ?? 0;
  static double overlayOf(DepthLevel level) => overlay[level] ?? 0;
}

/// Glass-specific decoration. Kept as one place so every surface in the app
/// catches light the same way — inconsistency here is what makes a UI look
/// assembled from parts rather than designed.
class Glass {
  /// The specular edge: a 1px bright line where glass would catch light.
  ///
  /// This single detail is most of the difference between "a rounded box" and
  /// "a pane". It fades out because a uniform white border reads as a stroke,
  /// and a stroke reads as a wireframe.
  static Border? specular(DepthLevel level, {bool gold = false}) {
    if (level == DepthLevel.ground) return null;
    final top = gold
        ? const Color(0x66C9A227) // gold rim — reserved for `float` and selection
        : const Color(0x24FFFFFF); // 14% white
    return Border(
      top: BorderSide(color: top, width: 1),
      left: BorderSide(color: const Color(0x0DFFFFFF), width: 1),
      right: BorderSide(color: const Color(0x0DFFFFFF), width: 1),
      bottom: BorderSide(color: const Color(0x14000000), width: 1),
    );
  }

  /// A one-line gradient that mimics the falloff of a real specular highlight.
  /// Used where a Border cannot reach — e.g. the top edge of the floating CTA.
  static const specularGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x29FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 1.0],
  );

  /// Wrap a single widget in a blur. Prefer this over BackdropFilter: Flutter's
  /// own docs are explicit that ImageFiltered is dramatically cheaper for the
  /// single-widget case, and it is simpler to reason about.
  static Widget frosted({
    required Widget child,
    double sigma = 22,
    Clip clip = Clip.antiAlias,
  }) {
    if (sigma <= 0) return child;
    return ClipRRect(
      clipBehavior: clip,
      borderRadius: BorderRadius.zero,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}

/// Scroll parallax for the atmospheric ground layer.
///
/// The ground moves at a fraction of the content speed. This is the cheapest
/// possible depth cue and the one people feel without being able to name it —
/// the screen stops being a flat card and becomes a space with a front and back.
class DepthParallax {
  /// 8–14% is the sweet spot. Above that it reads as broken layout rather than
  /// depth, because the background visibly detaches from the content.
  static const double factor = 0.12;
}

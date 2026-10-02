// Norcha Print — the layered-surface system ("netela": cloth laid on cloth).
//
// SPEC: docs/DESIGN-LUXURY.md
//
// WHY LAYERS ON A LIGHT GROUND
// The dark build could fake depth with glow. On cream that is not available, so
// depth has to be earned honestly: real contact shadows, a hairline that reads
// as a fold rather than a glow, and cards that sit slightly BRIGHTER than the
// page beneath them. Cream paper with a white card on it is the oldest trick in
// print design, and it still works because it is how paper actually behaves.
//
// The hierarchy is the same four levels as before, but "light" now means
// "closer to the viewer", not "brighter emission".

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import 'norcha_theme.dart';

/// The four physical levels. See DESIGN-LUXURY.md §1.
enum DepthLevel {
  /// Page ground. The cream the cards are laid on. Never carries text directly.
  ground,

  /// Content panels and repeated rows. Card white + hairline. NO blur cost.
  sheet,

  /// Selected / interactive. Lift + a pine or gold edge.
  raised,

  /// The CTA, the total, the bottom bar. Floats with a real, visible shadow.
  float,
}

class Depth {
  /// Backdrop blur sigma. Kept for the glass moments (the bottom bar over
  /// content) and deliberately ZERO for list rows — a blurred row in a list is
  /// a jank engine on a mid-range phone.
  static const Map<DepthLevel, double> blur = {
    DepthLevel.ground: 0,
    DepthLevel.sheet: 0,
    DepthLevel.raised: 18,
    DepthLevel.float: 26,
  };

  /// Surface tint. On a light ground, "closer" means purer white — the card is
  /// brighter than the paper. (On the old dark ground this was inverted.)
  static const Map<DepthLevel, Color> surface = {
    DepthLevel.ground: NorchaPalette.paper,
    DepthLevel.sheet: NorchaPalette.card,
    DepthLevel.raised: NorchaPalette.card,
    DepthLevel.float: NorchaPalette.card,
  };

  /// Contact shadow: [blurRadius, yOffset, alpha].
  ///
  /// Light-mode shadows must be MUCH softer and less opaque than the dark-mode
  /// ones were. A 55%-black shadow that reads as depth on near-black reads as a
  /// dirty smudge on cream.
  static const Map<DepthLevel, List<double>> shadow = {
    DepthLevel.ground: [0, 0, 0],
    DepthLevel.sheet: [14, 3, 0.07],
    DepthLevel.raised: [20, 6, 0.10],
    DepthLevel.float: [30, 12, 0.14],
  };

  static double sigmaOf(DepthLevel level) => blur[level] ?? 0;
  static Color surfaceOf(DepthLevel level) =>
      surface[level] ?? NorchaPalette.card;
}

/// Cloth edges. On a light ground the "specular highlight" of the dark build
/// becomes a folded edge: a slightly DARKER hairline at the bottom (where cloth
/// turns away from the light) and a faint white line at the top.
class Cloth {
  /// A hairline edge that reads as a fold, not a glow.
  static Border? edge(DepthLevel level, {Color? accent}) {
    if (level == DepthLevel.ground) return null;
    return Border(
      top: const BorderSide(color: Color(0xFFFFFFFF), width: 1),
      left: BorderSide(color: accent ?? NorchaPalette.line, width: 1),
      right: BorderSide(color: accent ?? NorchaPalette.line, width: 1),
      bottom: BorderSide(color: NorchaPalette.line, width: 1),
    );
  }

  /// The ceremonial selvedge from the website: a band of three dyed threads.
  /// Used for the wordmark rule and the top of the quote sheet — nowhere else.
  /// Three colours, one band, no exceptions (DESIGN.md rule).
  static const selvedge = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF17532F), // deep emerald
      Color(0xFFB8912F), // antique gold
      Color(0xFF7E211C), // oxblood
    ],
  );

  /// The tibeb: a hairline rule with a gold tick at one end. The recurring
  /// ornament — it marks the top of a section without shouting.
  static Widget tibeb({double width = 44, Color? colour}) {
    return SizedBox(
      width: width,
      height: 2,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: colour ?? NorchaPalette.line,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 2,
            decoration: BoxDecoration(
              color: colour ?? NorchaPalette.gold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scroll parallax for the ground layer.
///
/// Cheap depth cue: the background drifts at a fraction of content speed. On a
/// light theme it is subtler than it was on dark — 12% of a photo behind cream
/// is a lot more visible than 12% behind near-black.
class DepthParallax {
  static const double factor = 0.08;
}

/// Wrap a single widget in a blur. Flutter's docs are explicit that
/// ImageFiltered is dramatically cheaper than BackdropFilter for this case.
class Netela {
  static Widget frosted({
    required Widget child,
    double sigma = 18,
    BorderRadius? radius,
  }) {
    if (sigma <= 0) return child;
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: radius ?? BorderRadius.zero,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}

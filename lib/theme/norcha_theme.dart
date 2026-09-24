// Norcha Print — design system.
//
// DIRECTION: "THE PAPER SHOP" — the daylight world.
//
// WHY THIS EXISTS
// The dark editorial version (shipped, approved, preserved on main) is a print
// studio at night: near-black ground, gold as foil, serif numbers. It is
// beautiful and it is quiet.
//
// This is its inverse, and deliberately not a variation of it. Cream ground,
// ink text, the colours of actual printing — kraft, rust, sage. It is built on
// one thesis: *the app should look like the thing the shop sells.* Feven sells
// paper. So the interface is paper.
//
// That is why this is not "the dark theme, lightened". Inverting a palette
// produces a washed-out copy. Different ground, different type, different
// elevation model, different information order.
//
// Still Motion-Expressive in behaviour — springs, not curves. The physics of
// the interaction does not change with the surface.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The palette. Daylight, paper, ink, and the two colours that actually appear
/// in a print shop: rust from the ink pots, sage from the cutting mat.
class PaperPalette {
  // Grounds — this is a stack of paper, not a flat fill.
  static const ground = Color(0xFFF6F1E7); // the desk
  static const sheet = Color(0xFFFFFDF8); // a fresh sheet
  static const kraft = Color(0xFFEADFC8); // the box the prints go in
  static const kraftDeep = Color(0xFFDCCDB0); // its shadowed edge

  // Ink — never pure black. Real ink on real paper is warm.
  static const ink = Color(0xFF1C1814);
  static const inkSoft = Color(0xFF5A5048);
  static const inkFaint = Color(0xFF918A7D);

  // The two accents. Rust is the action colour — it is warm, urgent, and it is
  // the colour of a pressed stamp. Sage is the quiet one: correct states,
  // confirmations, the calm half of the shop.
  static const rust = Color(0xFF9C4A1E);
  static const rustDeep = Color(0xFF7A3916);
  static const sage = Color(0xFF6B7355);
  static const sageLight = Color(0xFF8B9474);

  // Rules and edges — printing uses hairlines, not borders.
  static const rule = Color(0xFFCFC2A8);
  static const ruleStrong = Color(0xFFB0A184);

  static const warn = Color(0xFFB07A1E);
  static const danger = Color(0xFFA63A22);
}

/// Type. EB Garamond for display because it is a real book face and the website
/// already uses it — Garamond on paper is not a stylistic choice, it is the
/// correct tool. Inter for anything functional, where clarity beats character.
class PaperType {
  static const displayFamily = 'EB Garamond';
  static const bodyFamily = 'Inter';
  static const amharicFamily = 'Noto Sans Ethiopic';

  static const displayXL = TextStyle(
    fontFamily: displayFamily,
    fontSize: 52,
    height: 1.06,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: PaperPalette.ink,
  );

  static const display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w600,
    color: PaperPalette.ink,
  );

  static const title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 23,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: PaperPalette.ink,
  );

  /// Printed small caps. The device that makes a page read as *set* rather than
  /// typed — a letterpress caption under a plate.
  static const sectionLabel = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 10.5,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: PaperPalette.inkSoft,
  );

  static const body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: PaperPalette.ink,
  );

  static const bodySmall = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: PaperPalette.inkSoft,
  );

  static const label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: PaperPalette.ink,
  );

  /// Prices are the one place the interface borrows from a ledger: tabular
  /// figures so a column of numbers aligns, as it would on a printed price list.
  static const price = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: PaperPalette.ink,
  );

  static const priceLarge = TextStyle(
    fontFamily: displayFamily,
    fontSize: 42,
    height: 1.05,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: PaperPalette.ink,
  );

  static const mono = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: PaperPalette.inkSoft,
  );
}

/// Motion. Unchanged from the dark version on purpose: the physics of a good
/// interaction does not depend on whether the room is lit.
class PaperMotion {
  static const standard = SpringDescription(mass: 1, stiffness: 500, damping: 35);
  static const expressive = SpringDescription(mass: 1, stiffness: 380, damping: 22);
  static const snappy = SpringDescription(mass: 1, stiffness: 700, damping: 42);

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
}

/// Shape. Squarer than the dark version — paper has corners. A 26px radius on
/// a cream ground reads as a phone app; a 4px radius reads as a card that was
/// cut.
class PaperShape {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 10;
  static const double xl = 16;
  static const double pill = 999;

  static const card = BorderRadius.all(Radius.circular(md));
  static const sheet = BorderRadius.all(Radius.circular(lg));
  static const chip = BorderRadius.all(Radius.circular(pill));
}

/// Elevation. On paper, depth is a *stack*, not a glow: a hard offset shadow
/// with almost no blur, the way one sheet sits on another. This is the single
/// biggest departure from the dark theme, where shadows were invisible and
/// depth came from light.
class PaperElevation {
  /// One sheet resting on another. Hard, close, barely blurred.
  static List<BoxShadow> get sheet => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ];

  /// Lifted — a sheet raised off the stack. Still hard-edged.
  static List<BoxShadow> get lifted => const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ];
}

/// A printer's rule — a hairline, solid, like a rule drawn with a pen.
class RuleLine extends StatelessWidget {
  final double opacity;
  final bool strong;
  const RuleLine({super.key, this.opacity = 1.0, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: strong ? 1.4 : 1,
      color: (strong ? PaperPalette.ruleStrong : PaperPalette.rule)
          .withOpacity(opacity),
    );
  }
}

/// The paper edge of a sheet — the faint darker line where a cut was made.
class PaperEdge extends StatelessWidget {
  final Widget child;
  const PaperEdge({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

ThemeData buildPaperTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: PaperPalette.ground,
  );

  return base.copyWith(
    colorScheme: const ColorScheme.light(
      primary: PaperPalette.rust,
      onPrimary: PaperPalette.sheet,
      secondary: PaperPalette.sage,
      onSecondary: PaperPalette.sheet,
      surface: PaperPalette.sheet,
      onSurface: PaperPalette.ink,
      error: PaperPalette.danger,
    ),
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: PaperPalette.ground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: PaperPalette.ground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: PaperType.displayXL,
      headlineMedium: PaperType.display,
      titleLarge: PaperType.title,
      bodyMedium: PaperType.body,
      bodySmall: PaperType.bodySmall,
      labelLarge: PaperType.label,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PaperPalette.ink,
      contentTextStyle: TextStyle(
        fontFamily: PaperType.bodyFamily,
        fontSize: 14,
        color: PaperPalette.sheet,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: PaperShape.card),
    ),
  );
}

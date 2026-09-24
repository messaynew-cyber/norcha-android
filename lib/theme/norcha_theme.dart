// Norcha Print — design system.
//
// DIRECTION: dark editorial luxury.
//
// WHY THIS REPLACED THE FIRST DESIGN
// The first build was a correct form. Cream background, chips, radio rows, a
// stepper. It worked and it looked like a tax return. Nobody shows a friend a
// well-aligned form.
//
// What this is instead: a print studio at night. Near-black ground so the
// images carry, antique gold used like foil — sparingly, always as a hairline
// or a small mark, never as a big flat fill. Display serif for the numbers
// because a number set large in a serif reads as *worth* something. Space used
// as a luxury signal, not wasted.
//
// MOTION follows Material 3 Expressive (Google I/O 2025, rolled to Android 16):
// physics-based springs rather than easing curves. Two schemes — standard for
// utility, expressive for delight. Flutter can do this natively with
// SpringDescription, so there is no dependency here.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The palette. Dark ground, gold as accent, everything else restrained.
class NorchaPalette {
  // Grounds — near-black, warmed slightly. Pure #000 reads like a switched-off
  // screen; a trace of warm in the black reads like ink on dark paper.
  static const void_ = Color(0xFF08070A);
  static const ink = Color(0xFF0F0E12);
  static const raised = Color(0xFF161519);
  static const raisedHigh = Color(0xFF1E1C22);

  // Gold — the whole personality lives here. Three steps, because using one
  // gold for both a hairline and a button is how a design starts looking flat.
  static const gold = Color(0xFFC9A227); // primary — marks, active states
  static const goldDim = Color(0xFF8A6F1E); // hairlines, dividers
  static const goldBright = Color(0xFFE8C766); // highlights, the foil moment

  // Text
  static const textPrimary = Color(0xFFF4EFE6); // warm white, not #FFF
  static const textSecondary = Color(0xFFA9A29A);
  static const textTertiary = Color(0xFF6E6862);

  // Semantic
  static const success = Color(0xFF7FB069);
  static const warn = Color(0xFFD98E4A);
  static const danger = Color(0xFFC4553F);
}

/// Type scale. Display sizes are deliberately large — M3 Expressive leans on
/// emphasis hierarchy, and a price set at 56pt reads as a different class of
/// object than the same price at 26pt.
///
/// Fonts are Google Fonts (google_fonts package). The website uses Bricolage /
/// EB Garamond / Outfit; woff2 cannot be loaded by Flutter and converting it
/// needs brotli, which this ARM64 authoring device cannot install. Same
/// character, different cut — noted so nobody thinks it is an accident.
class NorchaType {
  /// Editorial serif. The display face. Prices, headings, moments.
  static const displayFamily = 'Playfair Display';

  /// Clean geometric sans. Everything functional.
  static const bodyFamily = 'Inter';

  /// Amharic. Not an afterthought — most of the counter speaks it.
  static const amharicFamily = 'Noto Sans Ethiopic';

  static const displayXL = TextStyle(
    fontFamily: displayFamily,
    fontSize: 56,
    height: 1.02,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    color: NorchaPalette.textPrimary,
  );

  static const display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 38,
    height: 1.08,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    color: NorchaPalette.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: NorchaPalette.textPrimary,
  );

  static const sectionLabel = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 10.5,
    height: 1.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.4,
    color: NorchaPalette.textTertiary,
  );

  static const body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: NorchaPalette.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: NorchaPalette.textSecondary,
  );

  static const label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: NorchaPalette.textPrimary,
  );

  static const price = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: NorchaPalette.textPrimary,
  );

  static const mono = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: NorchaPalette.textSecondary,
  );
}

/// Motion. Physics, not curves — Material 3 Expressive's core idea.
///
/// A spring that arrives without overshoot feels mechanical. A spring with a
/// little bounce feels alive. The distinction is the whole point of the update.
class NorchaMotion {
  /// Utilitarian movement — things that should not draw attention.
  static const standard = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 35,
  );

  /// Bouncy. For the moments that should feel good: a quantity changing, a
  /// selection landing, a sheet opening.
  static const expressive = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 22,
  );

  /// Snappy, minimal overshoot — for small targets like a tap chip.
  static const snappy = SpringDescription(
    mass: 1,
    stiffness: 700,
    damping: 42,
  );

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
}

/// Shape. M3 Expressive animates corner radii rather than holding them fixed.
class NorchaShape {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double xl = 34;
  static const double pill = 999;

  static const card = BorderRadius.all(Radius.circular(md));
  static const sheet = BorderRadius.vertical(top: Radius.circular(xl));
  static const chip = BorderRadius.all(Radius.circular(pill));
}

/// Elevation, done with light rather than shadow — on a near-black ground a
/// drop shadow is invisible, so depth comes from a lifted surface + a hairline.
class NorchaElevation {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withOpacity(0.55),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: Colors.black.withOpacity(0.7),
          blurRadius: 44,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: NorchaPalette.gold.withOpacity(0.05),
          blurRadius: 18,
          spreadRadius: -4,
        ),
      ];
}

/// Gold hairline. Used everywhere a border would normally go.
class Hairline extends StatelessWidget {
  final double opacity;
  final double? width;
  const Hairline({super.key, this.opacity = 0.22, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NorchaPalette.gold.withOpacity(0),
            NorchaPalette.gold.withOpacity(opacity),
            NorchaPalette.gold.withOpacity(opacity),
            NorchaPalette.gold.withOpacity(0),
          ],
          stops: const [0.0, 0.18, 0.82, 1.0],
        ),
      ),
    );
  }
}

/// The app theme. Deliberately minimal: most styling lives on the widgets so
/// that a component can be understood by reading one file.
ThemeData buildNorchaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NorchaPalette.void_,
  );

  return base.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: NorchaPalette.gold,
      onPrimary: NorchaPalette.void_,
      secondary: NorchaPalette.goldBright,
      surface: NorchaPalette.ink,
      onSurface: NorchaPalette.textPrimary,
      error: NorchaPalette.danger,
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: NorchaPalette.void_,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: NorchaPalette.void_,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: NorchaType.displayXL,
      headlineMedium: NorchaType.display,
      titleLarge: NorchaType.title,
      bodyMedium: NorchaType.body,
      bodySmall: NorchaType.bodySmall,
      labelLarge: NorchaType.label,
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      thickness: 0,
      space: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NorchaPalette.raisedHigh,
      contentTextStyle: NorchaType.body,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: NorchaShape.card),
    ),
  );
}

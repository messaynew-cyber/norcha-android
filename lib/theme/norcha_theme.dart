// Norcha Print — design system.
//
// DIRECTION: light, editorial, Ethiopian. "Netela" — cream paper, pine, gold.
//
// ─── WHY THIS IS LIGHT, AFTER THE DARK VERSION WAS ACCEPTED ───────────────
// The dark editorial build ("Darkroom") was signed off on 2026-09-25 without
// any recorded reasoning. The website's own DESIGN.md says why that was a
// mistake: the shop's real identity is LIGHT — netela cream #F8F4EE, ink
// #241F18, pine #0E5C41, Meskel gold #C1922B. Dark exists on the web only as a
// [data-theme="dark"] toggle, a secondary mode, not the brand.
//
// So the app was wearing a costume the shop itself does not wear. Light is not
// a redesign here; it is the app finally matching the site a customer has
// already seen. That is a consistency argument, not a taste argument, and it is
// the one that matters.
//
// ─── WHY EVERY CARD IS WOVEN ─────────────────────────────────────────────
// Norcha prints — a photo studio in Bole. Its visual language comes from
// Ethiopian cloth: the netela's cream, the tibeb's woven border, the flag's
// green-gold-red used as SEPARATE accent roles, never as a tricolour except in
// the ceremony band. Colour is not decoration here; it is identity.
//
// MOTION follows Material 3 Expressive: physics-based springs rather than
// easing curves. Two schemes — routine for utility, expressive for delight.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The palette. Cream ground, ink text, pine as the primary action colour,
/// gold as ornament.
class NorchaPalette {
  // ── Grounds ───────────────────────────────────────────────────────────
  /// Page ground. Netela cream — the colour of hand-spun Ethiopian cotton.
  static const paper = Color(0xFFF8F4EE);

  /// Tinted section ground. One step darker, for alternating bands.
  static const paperDeep = Color(0xFFF0EAE1);

  /// Card surfaces. Deliberately brighter than the page, so cards read as
  /// laid ON the paper rather than cut out of it.
  static const card = Color(0xFFFFFDF9);

  // ── Ink ───────────────────────────────────────────────────────────────
  static const ink = Color(0xFF241F18); // primary text — warm near-black
  static const inkSoft = Color(0xFF6B6155); // secondary
  static const inkFaint = Color(0xFF9C9285); // tertiary, labels

  /// Hairlines. Every divider in this app is this colour — one line weight,
  /// one value, so the grid reads as a system rather than a series of choices.
  static const line = Color(0xFFE4DBCC);

  // ── Identity colours ──────────────────────────────────────────────────
  /// Primary UI green. NOT the flag green — this one holds text legibly.
  static const pine = Color(0xFF0E5C41);
  static const pineDeep = Color(0xFF0A4632);
  static const pineSoft = Color(0xFFDCE7DF);

  /// Meskel gold — ornaments, Amharic accents, the foil moments.
  static const gold = Color(0xFFC1922B);
  static const goldBright = Color(0xFFE0B84D);
  static const goldSoft = Color(0xFFF3E9D2);

  /// Accent roles. One product family gets one accent — see [Accent].
  /// The FLAG colours are ornament-only; `red` is the text-safe red (~6:1).
  static const flagGreen = Color(0xFF078930);
  static const flagYellow = Color(0xFFFCDD09);
  static const flagRed = Color(0xFFDA121A);
  static const red = Color(0xFFB3261E);

  static const success = Color(0xFF0E5C41);
  static const warn = Color(0xFFB98A16);
  static const danger = Color(0xFFB3261E);

  // ── Legacy aliases ────────────────────────────────────────────────────
  // The dark palette is gone, but screen code still refers to these names in a
  // few places. Aliased rather than deleted so nothing renders undefined while
  // the screens migrate — and so the compiler flags every remaining usage for
  // cleanup instead of silently painting black on cream.
  static const textPrimary = ink;
  static const textSecondary = inkSoft;
  static const textTertiary = inkFaint;
  static const raised = card;
  static const raisedHigh = card;
  static const void_ = paper; // was the dark ground; now the light one
  static const inkDeep = ink;
}

/// One accent per product family, applied to the woven card trim and the
/// detail-page badge. Mirrors the website's table exactly — canvas green,
/// photo books red, calendars yellow, and so on.
enum Accent {
  green(NorchaPalette.pine),
  red(NorchaPalette.red),
  yellow(NorchaPalette.warn);

  final Color colour;
  const Accent(this.colour);

  /// The family → accent map. Must match DESIGN.md on the website.
  static Accent forFamily(String family) {
    switch (family) {
      case 'canvas':
      case 'mugs':
        return Accent.green;
      case 'books':
      case 'frames':
        return Accent.red;
      case 'calendars':
      case 'prints':
        return Accent.yellow;
      default:
        return Accent.gold;
    }
  }

  static const gold = Accent.green; // fallback only; gold is not in the enum
}

/// Typography.
class NorchaType {
  /// Display serif. Numbers, headlines, the moments that should feel weighty.
  /// A price set large in a serif reads as WORTH something; the same price in
  /// sans reads as data entry.
  static const displayFamily = 'EB Garamond';

  /// Clean geometric sans. Everything functional.
  static const bodyFamily = 'Outfit';

  /// Amharic. Not an afterthought — most of the counter speaks it.
  static const amharicFamily = 'Noto Sans Ethiopic';

  static const displayXL = TextStyle(
    fontFamily: displayFamily,
    fontSize: 56,
    height: 1.02,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    color: NorchaPalette.ink,
  );

  static const display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 38,
    height: 1.08,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    color: NorchaPalette.ink,
  );

  static const title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: NorchaPalette.ink,
  );

  /// Small caps label. Positive tracking — the only place tracking goes up.
  static const sectionLabel = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 10.5,
    height: 1.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.4,
    color: NorchaPalette.inkFaint,
  );

  static const body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: NorchaPalette.ink,
  );

  static const bodySmall = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: NorchaPalette.inkSoft,
  );

  /// Amharic runs. Same metrics, Ethiopic face — a mixed EN/AM line must not
  /// visibly jump between the two.
  static const amharic = TextStyle(
    fontFamily: amharicFamily,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: NorchaPalette.ink,
  );

  static const mono = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: NorchaPalette.inkSoft,
  );
}

/// Motion. Physics, not curves — Material 3 Expressive's core idea.
class NorchaMotion {
  /// Utilitarian movement — things that should not draw attention.
  static const standard = SpringDescription(mass: 1, stiffness: 500, damping: 35);

  /// Bouncy. For the moments that should feel good.
  static const expressive = SpringDescription(mass: 1, stiffness: 380, damping: 22);

  /// Snappy, minimal overshoot — for small targets like a tap chip.
  static const snappy = SpringDescription(mass: 1, stiffness: 700, damping: 42);

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
  static const sheet = BorderRadius.vertical(top: Radius.circular(lg));
}

/// The theme.
class NorchaTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: NorchaPalette.paper,
      colorScheme: const ColorScheme.light(
        primary: NorchaPalette.pine,
        onPrimary: NorchaPalette.card,
        secondary: NorchaPalette.gold,
        onSecondary: NorchaPalette.ink,
        surface: NorchaPalette.card,
        onSurface: NorchaPalette.ink,
        error: NorchaPalette.danger,
        outline: NorchaPalette.line,
      ),
      // The app draws its own chrome — no elevation tinting, no default
      // Material surfaces bleeding through.
      appBarTheme: const AppBarTheme(
        backgroundColor: NorchaPalette.paper,
        foregroundColor: NorchaPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: NorchaPalette.paper,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: NorchaPalette.line,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: NorchaType.displayXL,
        headlineMedium: NorchaType.display,
        titleLarge: NorchaType.title,
        bodyMedium: NorchaType.body,
        bodySmall: NorchaType.bodySmall,
        labelSmall: NorchaType.sectionLabel,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// Kept so `NorchaTheme.dark()` callers do not break — but it returns the
  /// light theme on purpose. A dark variant is a future decision with a
  /// recorded reason, not a default.
  static ThemeData dark() => light();
}

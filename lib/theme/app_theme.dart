// Norcha Print — theme resolution, light and dark, switchable.
//
// ─── WHY BOTH, AFTER ARGUING FOR ONE ─────────────────────────────────────
// I built dark, was told it was mediocre; built light, was told it felt plain.
// Both reactions were real and the honest conclusion is that neither is wrong —
// dark sells atmosphere, light sells the shop's own face. Making the customer
// choose is better than losing an argument, and it costs one preference key.
//
// 🔴 THE PALETTE IS NOT NEGOTIABLE PER THEME.
// Both themes use the SAME identity colours — pine, Meskel gold, the flag
// accents, the product accents. Only the GROUND and the INK swap. A theme that
// also changed the brand colours would be two brands, and a customer toggling
// it would be looking at a different shop.
//
// The dark ground is warmed (#12100E), never #000: pure black on an OLED phone
// reads as a switched-off screen, and the whole point of the dark theme here is
// a print studio at night, not a power saving mode.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Which theme is active. Persisted across launches.
enum NorchaThemeMode {
  light,
  dark;

  static NorchaThemeMode parse(String? s) =>
      s == 'dark' ? NorchaThemeMode.dark : NorchaThemeMode.light;

  String get key => name;
}

/// Everything a widget needs to paint itself correctly in either theme.
///
/// Passed through an InheritedWidget rather than read from ThemeData, because
/// half of what this design depends on — cloth edges, selvedge, ghost numerals
/// — has no equivalent in the Material theme model, and cramming it into
/// ColorScheme would be a lie about what it is.
class NorchaColors extends ThemeExtension<NorchaColors> {
  // Grounds
  final Color ground;
  final Color groundDeep;
  final Color card;
  final Color cardRaised;

  // Ink
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color line;

  /// The hairline that reads as a fold. On light it is a light line ON the top
  /// edge; on dark it is a slightly lighter line, because the light source is
  /// the same but the surface absorbs instead of reflecting.
  final Color foldTop;
  final Color foldBottom;

  /// Ghost Ge'ez numeral opacity. Dark needs a touch more — a gold watermark
  /// on near-black is far less visible than the same watermark on cream.
  final double ghostOpacity;

  const NorchaColors({
    required this.ground,
    required this.groundDeep,
    required this.card,
    required this.cardRaised,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.line,
    required this.foldTop,
    required this.foldBottom,
    required this.ghostOpacity,
  });

  bool get isDark => ground.computeLuminance() < 0.5;

  /// Netela: hand-spun Ethiopian cotton. The shop's own ground.
  static const light = NorchaColors(
    ground: Color(0xFFF8F4EE),
    groundDeep: Color(0xFFF0EAE1),
    card: Color(0xFFFFFDF9),
    cardRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF241F18),
    inkSoft: Color(0xFF6B6155),
    inkFaint: Color(0xFF9C9285),
    line: Color(0xFFE4DBCC),
    foldTop: Color(0xFFFFFFFF),
    foldBottom: Color(0xFFE4DBCC),
    ghostOpacity: 0.13,
  );

  /// The studio at night. Warm black, never #000 — see the note at the top.
  static const dark = NorchaColors(
    ground: Color(0xFF12100E),
    groundDeep: Color(0xFF0C0B09),
    card: Color(0xFF1C1917),
    cardRaised: Color(0xFF262220),
    ink: Color(0xFFF4EFE6),
    inkSoft: Color(0xFFA9A29A),
    inkFaint: Color(0xFF6E6862),
    line: Color(0xFF2E2A26),
    foldTop: Color(0x1FFFFFFF),
    foldBottom: Color(0x66000000),
    ghostOpacity: 0.17,
  );

  @override
  NorchaColors copyWith({
    Color? ground, Color? groundDeep, Color? card, Color? cardRaised,
    Color? ink, Color? inkSoft, Color? inkFaint, Color? line,
    Color? foldTop, Color? foldBottom, double? ghostOpacity,
  }) => NorchaColors(
    ground: ground ?? this.ground,
    groundDeep: groundDeep ?? this.groundDeep,
    card: card ?? this.card,
    cardRaised: cardRaised ?? this.cardRaised,
    ink: ink ?? this.ink,
    inkSoft: inkSoft ?? this.inkSoft,
    inkFaint: inkFaint ?? this.inkFaint,
    line: line ?? this.line,
    foldTop: foldTop ?? this.foldTop,
    foldBottom: foldBottom ?? this.foldBottom,
    ghostOpacity: ghostOpacity ?? this.ghostOpacity,
  );

  @override
  NorchaColors lerp(ThemeExtension<NorchaColors>? other, double t) {
    if (other is! NorchaColors) return this;
    return NorchaColors(
      ground: Color.lerp(ground, other.ground, t)!,
      groundDeep: Color.lerp(groundDeep, other.groundDeep, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardRaised: Color.lerp(cardRaised, other.cardRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      line: Color.lerp(line, other.line, t)!,
      foldTop: Color.lerp(foldTop, other.foldTop, t)!,
      foldBottom: Color.lerp(foldBottom, other.foldBottom, t)!,
      ghostOpacity: ghostOpacity + (other.ghostOpacity - ghostOpacity) * t,
    );
  }

  /// Reach the resolved colours from any build method.
  static NorchaColors of(BuildContext context) =>
      Theme.of(context).extension<NorchaColors>() ?? NorchaColors.light;
}

/// Identity colours. IDENTICAL in both themes — see the note at the top.
class Brand {
  static const pine = Color(0xFF0E5C41);
  static const pineDeep = Color(0xFF0A4632);

  /// Lift the pine for dark grounds. The same hex that reads as deep green on
  /// cream reads as near-black on warm black, so the dark theme gets a lighter
  /// cut of the SAME hue rather than a different colour.
  static const pineOnDark = Color(0xFF3E9C78);

  static const gold = Color(0xFFC1922B);
  static const goldBright = Color(0xFFE0B84D);
  static const goldSoft = Color(0xFFF3E9D2);

  static const flagGreen = Color(0xFF078930);
  static const flagYellow = Color(0xFFFCDD09);
  static const flagRed = Color(0xFFDA121A);
  static const red = Color(0xFFB3261E);
  static const warn = Color(0xFFB98A16);

  /// The primary action colour, resolved for the ground it sits on.
  static Color action(NorchaColors c) => c.isDark ? pineOnDark : pine;

  /// Text/icon colour ON the action colour.
  static Color onAction(NorchaColors c) =>
      c.isDark ? const Color(0xFF0B0A09) : const Color(0xFFFFFDF9);

  /// The ceremonial selvedge — three dyed threads. Used at the top of a page
  /// and nowhere else. DESIGN.md rule: never a third tricolour.
  static const selvedge = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF17532F), Color(0xFFB8912F), Color(0xFF7E211C)],
  );
}

/// Motion tokens — the spring ladder and the durations.
class Motion {
  static const routine = SpringDescription(mass: 1, stiffness: 500, damping: 35);
  static const expressive = SpringDescription(mass: 1, stiffness: 340, damping: 20);
  static const snappy = SpringDescription(mass: 1, stiffness: 700, damping: 42);

  static const Duration press = Duration(milliseconds: 70);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 620);
}

/// Shape tokens.
class Radius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double xl = 34;
  static const double pill = 999;
}

/// Font families. Bundled, not fetched.
///
/// 🔴 WHY BUNDLED MATTERS HERE
/// google_fonts fetches over HTTP at runtime by default. On a shop counter with
/// bad signal, the first launch renders in the WRONG TYPEFACE — which is the
/// single most visible way an app can look cheap, and it happens exactly when
/// the customer is standing in front of you. The fonts are in assets/fonts and
/// referenced directly.
class NorchaTypeFace {
  /// Display serif. Numbers and headlines. A price set large in a serif reads
  /// as worth something; the same price in sans reads as data entry.
  static const display = 'EB Garamond';

  /// Body sans. Everything functional.
  static const body = 'Outfit';

  /// Amharic — and the Ge'ez numerals. Not an afterthought: most of the
  /// counter speaks it, and it is the identity of every watermark in the app.
  static const amharic = 'Noto Serif Ethiopic';
}

/// Text styles, resolved against the active theme.
///
/// These are methods rather than constants because ink colour changes with the
/// theme and a constant cannot. Call sites read `NorchaType.title(c)`.
class NorchaType {
  static TextStyle displayXL(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.display, fontSize: 56, height: 1.02,
    fontWeight: FontWeight.w700, letterSpacing: -1.2, color: c.ink,
  );

  static TextStyle display(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.display, fontSize: 38, height: 1.08,
    fontWeight: FontWeight.w600, letterSpacing: -0.6, color: c.ink,
  );

  static TextStyle title(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.display, fontSize: 24, height: 1.2,
    fontWeight: FontWeight.w600, letterSpacing: -0.2, color: c.ink,
  );

  /// Small caps label. Positive tracking — the only place tracking goes up.
  static TextStyle sectionLabel(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.body, fontSize: 10.5, height: 1.0,
    fontWeight: FontWeight.w600, letterSpacing: 2.4, color: c.inkFaint,
  );

  static TextStyle body(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.body, fontSize: 15, height: 1.45,
    fontWeight: FontWeight.w400, color: c.ink,
  );

  static TextStyle bodySmall(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.body, fontSize: 13, height: 1.4,
    fontWeight: FontWeight.w400, color: c.inkSoft,
  );

  /// Amharic runs. Same metrics as body — a mixed EN/AM line must not visibly
  /// jump between the two faces.
  static TextStyle amharicText(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.amharic, fontSize: 15, height: 1.5,
    fontWeight: FontWeight.w400, color: c.ink,
  );

  static TextStyle mono(NorchaColors c) => TextStyle(
    fontFamily: NorchaTypeFace.body, fontSize: 13, height: 1.3,
    fontWeight: FontWeight.w500,
    fontFeatures: const [FontFeature.tabularFigures()], color: c.inkSoft,
  );
}

/// ThemeData assembly. Material still needs a ThemeData even though this app
/// draws most of its own chrome.
class NorchaThemeData {
  static ThemeData build(NorchaColors c) {
    final scheme = c.isDark
        ? const ColorScheme.dark(
            primary: Brand.pineOnDark,
            onPrimary: Color(0xFF0B0A09),
            secondary: Brand.gold,
            surface: Color(0xFF1C1917),
            onSurface: Color(0xFFF4EFE6),
            error: Brand.red,
            outline: Color(0xFF2E2A26),
          )
        : const ColorScheme.light(
            primary: Brand.pine,
            onPrimary: Color(0xFFFFFDF9),
            secondary: Brand.gold,
            surface: Color(0xFFFFFDF9),
            onSurface: Color(0xFF241F18),
            error: Brand.red,
            outline: Color(0xFFE4DBCC),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.ground,
      colorScheme: scheme,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.ground,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              c.isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: c.ground,
          systemNavigationBarIconBrightness:
              c.isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

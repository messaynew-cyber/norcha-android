// Can the pages actually RENDER in Amharic?
//
// WHY THIS FILE EXISTS
// The app shipped with no widget test at all — every test in this repo was pure
// logic (prices, dates, strings). Nothing ever pumped a page and looked at it,
// so a bug where the Upload and Order pages went blank in Amharic was invisible
// to CI: the strings were right, the prices were right, the page was empty.
//
// 🔴 WHAT ACTUALLY CAUSED IT
// The label above every text field is content, so in Amharic it is Ethiopic —
// but it was styled with `NorchaType.sectionLabel`, which named a LATIN-ONLY
// face (Outfit) at `height: 1.0`. Measured from the shipped font files:
//
//     Noto Serif Ethiopic   ascent 1069, descent -293, upm 1000 -> 1.362 em
//     Outfit                ascent 1000, descent -260, upm 1000 -> 1.260 em
//
// Ethiopic needs MORE line height than Latin at the same size. At height 1.0
// the Amharic glyphs are taller than their line box and overflow a box that
// Latin fits — which is why Order and Upload broke in Amharic only. Both are
// the only pages with text fields, and unlike the page header (its own widget
// subtree) the body is a single Column, so a broken child takes the body with
// it. That is the "grey board with the header still visible".
//
// Not one test here would have caught this before, because Flutter's test font
// has imaginary metrics: every glyph is the same size, so nothing ever
// overflows in a test. These tests therefore assert the RULES — that a style
// which can carry Amharic has room for Amharic and names a face that has the
// glyphs — rather than trying to reproduce the rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:norcha_print/core/lang.dart';
import 'package:norcha_print/core/pricing.dart';
import 'package:norcha_print/features/order/order_page.dart';
import 'package:norcha_print/features/upload/upload_page.dart';
import 'package:norcha_print/theme/app_theme.dart';
import 'package:norcha_print/theme/theme_controller.dart';
import 'package:norcha_print/widgets/diagnostic_banner.dart';

/// Measured from the shipped Noto Serif Ethiopic with fontTools, 2026-10-07.
const double kEthiopicLineEm = 1.362;

/// The lowest opacity any FadeTransition in the tree is currently at.
/// Every page wraps its children in StaggeredReveal, which fades 0 -> 1, so a
/// page that finished animating should have nothing near zero left.
double minOpacity(WidgetTester tester) {
  var worst = 1.0;
  for (final e in find.byType(FadeTransition).evaluate()) {
    final o = (e.widget as FadeTransition).opacity.value;
    if (o < worst) worst = o;
  }
  return worst;
}

Future<void> pumpPage(WidgetTester tester, Widget page, LangController langs,
    ThemeController themes) async {
  // The same nesting the real app uses: LangScope above MaterialApp, so the
  // language notifier rebuilds the page exactly as it does on device.
  await tester.pumpWidget(LangScope(
    controller: langs,
    child: MaterialApp(
      theme: NorchaThemeData.build(themes.colors),
      home: Scaffold(body: page),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump(const Duration(milliseconds: 1200));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('pages render in both languages', () {
    testWidgets('Order page is visible in EN and in AM', (tester) async {
      final langs = LangController();
      final themes = ThemeController();

      await pumpPage(
          tester, OrderPage(themes: themes, langs: langs), langs, themes);
      expect(tester.takeException(), isNull, reason: 'English threw');
      expect(minOpacity(tester), greaterThan(0.9),
          reason: 'English Order page not fully visible');

      langs.set(NorchaLang.am);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.takeException(), isNull, reason: 'Amharic threw');
      expect(minOpacity(tester), greaterThan(0.9),
          reason: 'Amharic Order page rendered at low opacity');
    });

    testWidgets('Upload page is visible in EN and in AM', (tester) async {
      final langs = LangController();
      final themes = ThemeController();

      await pumpPage(
          tester, UploadPage(themes: themes, langs: langs), langs, themes);
      expect(tester.takeException(), isNull, reason: 'English threw');
      expect(minOpacity(tester), greaterThan(0.9),
          reason: 'English Upload page not fully visible');

      langs.set(NorchaLang.am);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.takeException(), isNull, reason: 'Amharic threw');
      expect(minOpacity(tester), greaterThan(0.9),
          reason: 'Amharic Upload page rendered at low opacity');
    });

    testWidgets('switching back to English leaves the page visible',
        (tester) async {
      final langs = LangController();
      final themes = ThemeController();

      await pumpPage(
          tester, OrderPage(themes: themes, langs: langs), langs, themes);
      langs.set(NorchaLang.am);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      langs.set(NorchaLang.en);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(minOpacity(tester), greaterThan(0.9),
          reason: 'page stayed blank after switching back');
    });

    testWidgets('text fields are keyed by language', (tester) async {
      // The bug: swapping language reused the TextField element, so the
      // platform InputConnection stayed alive across the rebuild and the
      // field's slot painted as the framework's default grey — wiping the
      // body of Order and Upload in Amharic.
      //
      // The fix is a per-language key, which forces the old field to dispose
      // (tearing the connection down). This asserts the key EXISTS and that it
      // actually differs between the two languages — a key that never changes
      // would fix nothing.
      final langs = LangController();
      final themes = ThemeController();

      await pumpPage(
          tester, OrderPage(themes: themes, langs: langs), langs, themes);
      final enKeys = find
          .byType(TextField)
          .evaluate()
          .map((e) => e.widget.key)
          .whereType<ValueKey<String>>()
          .map((k) => k.value)
          .toSet();
      expect(enKeys, isNotEmpty, reason: 'Order fields carry no key at all');

      langs.set(NorchaLang.am);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final amKeys = find
          .byType(TextField)
          .evaluate()
          .map((e) => e.widget.key)
          .whereType<ValueKey<String>>()
          .map((k) => k.value)
          .toSet();
      expect(amKeys, isNotEmpty, reason: 'Amharic Order fields carry no key');
      expect(enKeys.intersection(amKeys), isEmpty,
          reason: 'the field key did not change with the language, so the '
              'element would be reused and the platform connection kept');
    });

    testWidgets('every product family has both labels', (tester) async {
      for (final family in NorchaData.products.keys) {
        final p = NorchaData.products[family]!;
        expect(p.label.am.trim(), isNotEmpty, reason: '$family: no Amharic');
        expect(p.label.en.trim(), isNotEmpty, reason: '$family: no English');
      }
    });
  });

  group('the diagnostic overlay cannot break the app', () {
    // 🔴 THIS TEST EXISTS BECAUSE THE OVERLAY DID BREAK IT.
    //
    // The first version wrapped MaterialApp from the OUTSIDE, where there is no
    // Directionality. It builds a Stack with Positioned children, and a
    // Positioned needs a text direction — so the app threw on its first build
    // and showed a blank white screen. The diagnostic tool took down the app it
    // was meant to diagnose, and could not report its own error because the
    // banner was inside the failing subtree.
    //
    // These pump the overlay in exactly the hostile positions that broke it.

    testWidgets('mounts WITHOUT any ambient Directionality', (tester) async {
      // No MaterialApp, no Directionality, no MediaQuery — the shape that
      // produced the white screen.
      await tester.pumpWidget(DiagnosticHost(child: Container()));
      expect(tester.takeException(), isNull,
          reason: 'the overlay threw when it had no Directionality above it');
    });

    testWidgets('mounts inside a bare View', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DiagnosticHost(child: const SizedBox()),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders its child, not just itself', (tester) async {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            DiagnosticHost(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Text('PAGE CONTENT')),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('PAGE CONTENT'), findsOneWidget,
          reason: 'the overlay hid or replaced the page');
    });

    testWidgets('shows the build tag when there are no errors', (tester) async {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            DiagnosticHost(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Text('x')),
      ));
      await tester.pump();
      // The banner carries the build tag; the expanded body also says
      // "no errors recorded this session". Two matches is correct — match the
      // one that carries the identity.
      expect(find.textContaining('no errors ·'), findsOneWidget,
          reason: 'the banner must always show the build identity');
    });

    testWidgets('surfaces a recorded error instead of swallowing it',
        (tester) async {
      Diagnostics.clear();
      Diagnostics.record('TEST', 'something went wrong');
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            DiagnosticHost(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Text('x')),
      ));
      await tester.pump();
      expect(find.textContaining('1 ERROR'), findsOneWidget);
      expect(find.textContaining('something went wrong'), findsOneWidget,
          reason: 'a recorded error must appear on screen, not only in a log');
      Diagnostics.clear();
    });
  });

  group('Ethiopic metrics and fonts', () {
    test('sectionLabel leaves room for Ethiopic in both scripts', () {
      final en = NorchaType.sectionLabel(NorchaColors.light);
      final am = NorchaType.sectionLabel(NorchaColors.light, amharic: true);

      expect(en.height, greaterThanOrEqualTo(1.2),
          reason: 'even the Latin label must not clip its descenders');
      expect(am.height, greaterThanOrEqualTo(kEthiopicLineEm),
          reason: 'Amharic label would overflow its line box');
      expect(am.fontFamily, NorchaTypeFace.amharic,
          reason: 'Amharic label must not be set in a Latin-only face');
      expect(en.fontFamily, NorchaTypeFace.body);
    });

    test('no Amharic-capable style clips Ethiopic or names a Latin face', () {
      final c = NorchaColors.light;
      final amStyles = <String, TextStyle>{
        'sectionLabel(am)': NorchaType.sectionLabel(c, amharic: true),
        'amharicText': NorchaType.amharicText(c),
        'forText(am)': NorchaType.forText(c, true),
      };
      amStyles.forEach((name, s) {
        expect(s.height ?? 1.0, greaterThanOrEqualTo(kEthiopicLineEm),
            reason: '$name has no room for Ethiopic');
        expect(s.fontFamily, NorchaTypeFace.amharic,
            reason: '$name does not name the Ethiopic face');
      });
    });

    test('every weight the app uses is DECLARED, so none is synthesised', () {
      // A variable font registered without a `weight:` key is pinned to the
      // font's own default (Outfit's is 100 — Thin) and every other weight is
      // faked by smearing a second offset copy of the glyph. On the stroked
      // Ge'ez ghost numerals that reads as a DOUBLED outline.
      //
      // This checks the app does not ask for a weight the bundle does not
      // declare. The list below mirrors pubspec.yaml's four entries per family
      // and is meant to fail the moment pubspec and the code disagree.
      const declared = {400, 500, 600, 700};
      final used = <int>{};
      // Every style NorchaType exposes, at the weight it sets.
      final styles = <TextStyle>[
        NorchaType.displayXL(NorchaColors.light),
        NorchaType.display(NorchaColors.light),
        NorchaType.title(NorchaColors.light),
        NorchaType.sectionLabel(NorchaColors.light),
        NorchaType.sectionLabel(NorchaColors.light, amharic: true),
        NorchaType.body(NorchaColors.light),
        NorchaType.bodySmall(NorchaColors.light),
        NorchaType.amharicText(NorchaColors.light),
        NorchaType.forText(NorchaColors.light, true),
        NorchaType.mono(NorchaColors.light),
      ];
      for (final st in styles) {
        final w = (st.fontWeight ?? FontWeight.w400).value;
        used.add(w);
        expect(declared, contains(w),
            reason: 'a style asks for w$w but pubspec does not declare it, '
                'so Flutter will synthesise it');
      }
      expect(used, isNotEmpty);
    });

    test('the three families are the ones the bundle declares', () {
      // If pubspec ever loses the `fonts:` block again, every family silently
      // falls back to whatever the device has. These names must match it.
      expect(NorchaTypeFace.body, 'Outfit');
      expect(NorchaTypeFace.display, 'EB Garamond');
      expect(NorchaTypeFace.amharic, 'Noto Serif Ethiopic');
    });
  });
}

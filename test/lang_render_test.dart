// Can the pages actually RENDER in Amharic?
//
// WHY THIS FILE EXISTS
// The app shipped with no widget test at all — every test in this repo was pure
// logic (prices, dates, strings). So nothing ever pumped a page and looked at
// it. A bug where the Upload and Order pages went blank when switching to
// Amharic was therefore invisible to CI: the string table was correct, the
// prices were correct, and the page was still empty.
//
// The cause is StaggeredReveal, the per-child entrance animation every page
// uses. Each child starts at opacity 0 and fades in from a DELAYED future:
//
//     Future.delayed(ms, () { if (mounted) _c.forward(); });
//
// If that future does not run, the child stays at opacity 0 — the page is
// structurally perfect and completely invisible. That is the "grey board".
//
// These tests pump the real pages and assert that the content is actually
// VISIBLE, not merely built. A page that renders at opacity 0 is the bug.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:norcha_print/core/lang.dart';
import 'package:norcha_print/core/pricing.dart';
import 'package:norcha_print/features/order/order_page.dart';
import 'package:norcha_print/features/upload/upload_page.dart';
import 'package:norcha_print/theme/app_theme.dart';
import 'package:norcha_print/theme/theme_controller.dart';

/// Every StaggeredReveal drives its child's opacity through a FadeTransition.
/// Walk the tree and find the lowest opacity any visible text is rendered at.
double minTextOpacity(WidgetTester tester) {
  var worst = 1.0;
  for (final fe in find.byType(FadeTransition).evaluate()) {
    final w = fe.widget as FadeTransition;
    final o = w.opacity.value;
    if (o < worst) worst = o;
  }
  return worst;
}

/// Pumps a page inside the same scope nesting the real app uses: LangScope
/// wraps MaterialApp (see the app's build), and the theme arrives through
/// MaterialApp's own theme. Reproducing the real nesting matters — the bug only
/// happens when the language notifier is ABOVE the page and rebuilding it.
Future<void> pumpPage(WidgetTester tester, Widget page, LangController langs,
    ThemeController themes) async {
  await tester.pumpWidget(LangScope(
    controller: langs,
    child: MaterialApp(
      theme: NorchaThemeData.build(themes.colors),
      home: Scaffold(body: page),
    ),
  ));
  // The stagger is up to 520ms of delay plus a 420ms fade.
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump(const Duration(milliseconds: 1200));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Order page is visible in BOTH languages', (tester) async {
    final langs = LangController();
    final themes = ThemeController();

    await pumpPage(tester, OrderPage(themes: themes, langs: langs), langs, themes);
    expect(tester.takeException(), isNull, reason: 'English threw');
    expect(minTextOpacity(tester), greaterThan(0.9),
        reason: 'English Order page is not fully visible');

    langs.set(NorchaLang.am);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull, reason: 'Amharic threw');
    expect(minTextOpacity(tester), greaterThan(0.9),
        reason: 'Amharic Order page rendered at low opacity — the blank-page bug');
  });

  testWidgets('Upload page is visible in BOTH languages', (tester) async {
    final langs = LangController();
    final themes = ThemeController();

    await pumpPage(tester, UploadPage(themes: themes, langs: langs), langs, themes);
    expect(tester.takeException(), isNull, reason: 'English threw');
    expect(minTextOpacity(tester), greaterThan(0.9),
        reason: 'English Upload page is not fully visible');

    langs.set(NorchaLang.am);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull, reason: 'Amharic threw');
    expect(minTextOpacity(tester), greaterThan(0.9),
        reason: 'Amharic Upload page rendered at low opacity — the blank-page bug');
  });

  testWidgets('every product family renders its Amharic label', (tester) async {
    // The label comes from pricing.dart, not the string table. If a family's
    // Amharic label were blank the selector would show empty chips.
    for (final family in NorchaData.products.keys) {
      final p = NorchaData.products[family]!;
      expect(p.label.am.trim(), isNotEmpty, reason: '$family has no Amharic label');
      expect(p.label.en.trim(), isNotEmpty, reason: '$family has no English label');
    }
  });

  testWidgets('switching back to English does not leave the page blank',
      (tester) async {
    final langs = LangController();
    final themes = ThemeController();

    await pumpPage(tester, OrderPage(themes: themes, langs: langs), langs, themes);
    langs.set(NorchaLang.am);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    langs.set(NorchaLang.en);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(minTextOpacity(tester), greaterThan(0.9),
        reason: 'page stayed blank after switching back to English');
  });
}

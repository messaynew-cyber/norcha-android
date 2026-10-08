// Can a TextField survive an Amharic locale at the MaterialApp level?
//
// 🔴 WHY THIS FILE EXISTS — THE GAP IT CLOSES
// test/lang_render_test.dart already pumps the Order and Upload pages in
// Amharic. It did not catch this bug, and the reason is precise: it mounts a
// bare MaterialApp and flips the LangController. It never gives that MaterialApp
// a `locale`, so Flutter stayed English underneath and every Material lookup
// resolved. The real app DOES set `locale:` — and that difference is the bug.
//
// So this test reproduces the REAL app's MaterialApp configuration:
//
//     locale: Locale('am')
//     supportedLocales: [Locale('en'), Locale('am')]
//     localizationsDelegates: [...]        <- the line that was missing
//
// WHAT THE BUG LOOKED LIKE
// With `am` in supportedLocales but no GlobalMaterialLocalizations delegate,
// Localizations falls back to DefaultMaterialLocalizations, which only defines
// English. TextField then asks for its decoration, gets null, and throws:
//
//     Null check operator used on a null value
//     text_field.dart:1547 / transitions.dart:1124
//
// The throw is entirely inside Flutter, so the stack trace contains no Norcha
// frame at all — which is why it read as "unexplained grey screen" for two days.
//
// These assertions are deliberately about NO EXCEPTION, not about pixels. A
// grey screen is the corpse; the exception is the cause.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norcha_print/core/lang.dart';

/// The exact MaterialApp shape the real app uses. If this helper drifts from
/// lib/main.dart, the test stops protecting anything — so keep it honest.
Widget _appUnderTest({required Widget child, required NorchaLang lang}) {
  return MaterialApp(
    locale: Locale(lang.code),
    supportedLocales: const [Locale('en'), Locale('am')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

/// A TextField styled the way every field in this app is styled: a label above
/// it taken from the language table (so Ethiopic in Amharic), and Norcha's own
/// InputDecoration. This is the shape that threw.
Widget _norchaField(NorchaLang lang, {Key? key}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(L.t('order.phone', lang)),
      const SizedBox(height: 8),
      TextField(
        key: key,
        decoration: const InputDecoration(
          hintText: 'NR-0000',
        ),
      ),
    ],
  );
}

void main() {
  group('TextField under an Amharic MaterialApp', () {
    testWidgets('English locale builds a field without throwing',
        (tester) async {
      await tester.pumpWidget(
        _appUnderTest(
          lang: NorchaLang.en,
          child: _norchaField(NorchaLang.en),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
        '🔴 Amharic locale builds a field without throwing — the regression',
        (tester) async {
      await tester.pumpWidget(
        _appUnderTest(
          lang: NorchaLang.am,
          child: _norchaField(NorchaLang.am),
        ),
      );
      // pumpAndSettle, not pump: the failure only surfaced after the
      // AnimatedBuilder inside TextField had built its decoration.
      await tester.pumpAndSettle();

      final ex = tester.takeException();
      expect(
        ex,
        isNull,
        reason: 'Amharic TextField threw: $ex\n'
            'If this is "Null check operator used on a null value", the '
            'localizationsDelegates are missing from the MaterialApp that '
            'this helper mirrors. See lib/main.dart.',
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('MaterialLocalizations actually resolves for Amharic',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _appUnderTest(
          lang: NorchaLang.am,
          child: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      );
      await tester.pumpAndSettle();

      // The real assertion: a localizations object EXISTS and is not the
      // English-only default. Before the fix this returned the fallback and
      // every Material widget downstream was living on borrowed time.
      final loc = MaterialLocalizations.of(ctx);
      expect(loc, isNotNull);
      expect(
        loc.runtimeType.toString(),
        isNot(contains('DefaultMaterialLocalizations')),
        reason: 'Amharic is resolving to the English-only default. The '
            'GlobalMaterialLocalizations delegate is not in the tree.',
      );
    });

    testWidgets('switching en -> am at runtime keeps the field alive',
        (tester) async {
      Widget build(NorchaLang l) => _appUnderTest(
            lang: l,
            child: _norchaField(l, key: ValueKey('order-field-${l.code}')),
          );

      await tester.pumpWidget(build(NorchaLang.en));
      await tester.pumpAndSettle();

      // This is the exact user action that broke it: the toggle.
      await tester.pumpWidget(build(NorchaLang.am));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}

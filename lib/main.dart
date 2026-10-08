// Norcha Print — entry point.
//
// Flutter's build looks for lib/main.dart and nowhere else. Keeping the entry
// here means `flutter create .`, IDE run configs and anyone joining later all
// work without a special case. This was trap #3 in the README — do not move it.
//
// v0.4 — dual language, Ethiopian motif layer, proportional size selector,
// motion throughout. Two controllers are created here and threaded down: theme
// and language. A provider package for two ChangeNotifiers would be furniture.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 🔴 REQUIRED, AND ITS ABSENCE WAS A SHIPPED BUG.
// Material's own widgets — TextField above all — resolve their decoration
// through MaterialLocalizations.of(context). Without these delegates the
// Localizations widget falls back to DefaultMaterialLocalizations, which
// only speaks English. Setting `locale: Locale('am')` in supportedLocales
// then makes that lookup resolve to NOTHING, and TextField throws
// 'Null check operator used on a null value' inside text_field.dart.
//
// This is a DIFFERENT bug from the stale-InputConnection grey (#B6B6B6)
// fixed by the ValueKey on the Order and Upload fields. Same symptom,
// same two widgets, different cause. Both are now covered by tests.
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/lang.dart';
import 'features/about/about_page.dart';
import 'features/home/home_page.dart';
import 'features/order/order_page.dart';
import 'features/quote/quote_page.dart';
import 'features/shell/app_shell.dart';
import 'features/upload/upload_page.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/diagnostic_banner.dart';

/// 🔴 DIAGNOSTIC HOOK — the app reports on itself.
///
/// A bug was reported twice — Order and Upload painting as a flat grey
/// rectangle in Amharic — and two fixes were attempted from reading source
/// code. Both were wrong. The failure does not reproduce in a test (Flutter's
/// test font has imaginary metrics and there are no platform views), so the
/// only reliable witness is the device itself.
///
/// Everything caught here goes to Diagnostics, which the banner in
/// widgets/diagnostic_banner.dart draws ON TOP of the page. That means a
/// screenshot carries the cause instead of just the symptom, which is the
/// difference between this round and the last two.
void _installErrorLogger() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    Diagnostics.record(
      'BUILD${details.context == null ? '' : ' — ${details.context}'}',
      details.exceptionAsString(),
      details.stack,
    );
    previous?.call(details);
  };

  // Errors outside a build — async work, platform channels, image decode —
  // arrive here instead. A platform-channel failure is a prime suspect for a
  // surface that never paints, so these matter as much as build errors.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    Diagnostics.record('ASYNC', error, stack);
    return true;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorLogger();

  // Reminders were built in Phase 1 and still work — they are the one thing the
  // website cannot do. Failure here must never block the app from opening: a
  // customer at the counter needs prices, not a notification dialog.
  try {
    await NotificationService.init();
  } catch (_) {
    // Deliberately swallowed. Notifications are a bonus, not a dependency.
  }

  final themes = ThemeController();
  await themes.load();

  final langs = LangController();
  await langs.load();

  runApp(NorchaApp(themes: themes, langs: langs));
}

class NorchaApp extends StatefulWidget {
  final ThemeController themes;
  final LangController langs;

  const NorchaApp({super.key, required this.themes, required this.langs});

  @override
  State<NorchaApp> createState() => _NorchaAppState();
}

class _NorchaAppState extends State<NorchaApp> {
  NorchaColors get _c => widget.themes.colors;

  @override
  void initState() {
    super.initState();
    widget.themes.addListener(_onChanged);
    widget.langs.addListener(_onChanged);
    _applySystemChrome();
  }

  @override
  void dispose() {
    widget.themes.removeListener(_onChanged);
    widget.langs.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    _applySystemChrome();
    setState(() {});
  }

  /// Status and navigation bars must follow the theme, or a dark app ends up
  /// with black-on-black system chrome — the tell that a theme switch was
  /// bolted on rather than built in.
  void _applySystemChrome() {
    final dark = _c.isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _c.ground,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(
      controller: widget.langs,
      child: MaterialApp(
        // 🔴 DiagnosticHost goes in `builder:`, NOT around MaterialApp.
        //
        // It was wrapped AROUND MaterialApp first, which put it above
        // Directionality, MediaQuery and Theme. DiagnosticHost builds a Stack
        // with Positioned children, and a Positioned requires a text
        // direction — so the app threw on its first build and showed a blank
        // white screen. Worse, the banner could not report the error, because
        // the widget that draws the banner was inside the thing that threw.
        //
        // `builder:` runs BELOW MaterialApp, so the overlay inherits
        // Directionality, MediaQuery and Theme. It also keeps the overlay
        // ABOVE the Navigator, so it survives page changes.
        builder: (context, child) =>
            DiagnosticHost(child: child ?? const SizedBox.shrink()),
        title: 'Norcha Print',
        debugShowCheckedModeBanner: false,
        theme: NorchaThemeData.build(_c),
        themeMode: _c.isDark ? ThemeMode.dark : ThemeMode.light,
        themeAnimationDuration: Motion.medium,
        themeAnimationCurve: Curves.easeInOutCubic,
        // 🔴 THE DELEGATES ARE NOT OPTIONAL. See the import comment above.
        // `locale` alone makes Flutter ACCEPT 'am' and then fail to RESOLVE
        // it, which is worse than not setting it at all.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Amharic needs a locale set or Flutter's own widgets (the date picker,
        // long-press menus) stay English underneath an Amharic screen.
        locale: Locale(widget.langs.lang.code),
        supportedLocales: const [Locale('en'), Locale('am')],
        home: AppShell(
          themes: widget.themes,
          langs: widget.langs,
          initialIndex: NorchaTab.home,
          pages: [
            HomePage(themes: widget.themes, langs: widget.langs),
            QuotePage(themes: widget.themes, langs: widget.langs),
            OrderPage(themes: widget.themes, langs: widget.langs),
            UploadPage(themes: widget.themes, langs: widget.langs),
            AboutPage(themes: widget.themes, langs: widget.langs),
          ],
        ),
      ),   // MaterialApp
    );
  }
}

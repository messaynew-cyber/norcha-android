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

/// 🔴 DIAGNOSTIC HOOK — added 2026-10-07 while chasing a bug where the Order
/// and Upload bodies paint as a flat grey rectangle in Amharic, a colour that
/// appears nowhere in this app's palette. Nothing in the widget tree throws in
/// a test, so the failure is device-only. This catches it where it happens and
/// prints the first line of the real error to logcat, so the next screenshot
/// comes with a cause attached instead of a guess.
void _installErrorLogger() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    // `context` is where the failing widget was in the tree, which is the
    // whole point — it names the widget, not just the exception.
    debugPrint('[NORCHA-ERROR] ${details.exceptionAsString()}');
    if (details.context != null) {
      debugPrint('[NORCHA-ERROR-CONTEXT] ${details.context}');
    }
    if (details.stack != null) {
      debugPrint('[NORCHA-ERROR-STACK] ${details.stack.toString().split("\n").take(6).join(" | ")}');
    }
    previous?.call(details);
  };
  // Errors that happen outside a build — async, platform channels, image
  // decode — surface here instead, and a platform-channel failure is a prime
  // suspect for a surface that never paints.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[NORCHA-ASYNC-ERROR] $error');
    debugPrint('[NORCHA-ASYNC-STACK] ${stack.toString().split("\n").take(6).join(" | ")}');
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
        title: 'Norcha Print',
        debugShowCheckedModeBanner: false,
        theme: NorchaThemeData.build(_c),
        themeMode: _c.isDark ? ThemeMode.dark : ThemeMode.light,
        themeAnimationDuration: Motion.medium,
        themeAnimationCurve: Curves.easeInOutCubic,
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
      ),
    );
  }
}

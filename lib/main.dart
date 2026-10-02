// Norcha Print — entry point.
//
// Flutter's build looks for lib/main.dart and nowhere else. Keeping the entry
// here means `flutter create .`, IDE run configs and anyone joining later all
// work without a special case. This was trap #3 in the README — do not move it.
//
// v0.3 — light AND dark, switchable; a drawn loading mark; Ge'ez ghost numerals;
// motion throughout. The theme controller is created once here and threaded
// down, because a provider package for forty lines of state would be furniture.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/about/about_page.dart';
import 'features/home/home_page.dart';
import 'features/order/order_page.dart';
import 'features/quote/quote_page.dart';
import 'features/shell/app_shell.dart';
import 'features/upload/upload_page.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(NorchaApp(themes: themes));
}

class NorchaApp extends StatefulWidget {
  final ThemeController themes;
  const NorchaApp({super.key, required this.themes});

  @override
  State<NorchaApp> createState() => _NorchaAppState();
}

class _NorchaAppState extends State<NorchaApp> {
  NorchaColors get _c => widget.themes.colors;

  @override
  void initState() {
    super.initState();
    widget.themes.addListener(_onThemeChanged);
    _applySystemChrome();
  }

  @override
  void dispose() {
    widget.themes.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
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
    return MaterialApp(
      title: 'Norcha Print',
      debugShowCheckedModeBanner: false,
      theme: NorchaThemeData.build(_c),
      // themeMode is driven entirely by the controller; the resolved colours
      // are passed explicitly so there is one source of truth, not two that can
      // disagree mid-transition.
      themeMode: _c.isDark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Motion.medium,
      themeAnimationCurve: Curves.easeInOutCubic,
      home: AppShell(
        themes: widget.themes,
        initialIndex: NorchaTab.home,
        pages: [
          HomePage(themes: widget.themes),
          QuotePage(themes: widget.themes),
          OrderPage(themes: widget.themes),
          UploadPage(themes: widget.themes),
          AboutPage(themes: widget.themes),
        ],
      ),
    );
  }
}

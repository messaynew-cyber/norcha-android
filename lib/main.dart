// Norcha Print — entry point.
//
// Flutter's build looks for lib/main.dart and nowhere else. Keeping the entry
// here (rather than in a feature folder) means `flutter create .`, IDE run
// configs and anyone joining later all work without a special case. This was
// trap #3 in the README — do not move it.
//
// v0.2 — the app is five pages behind a shell now, and it talks to the live
// site. The bone structure lives here so it is obvious what the product is
// without opening six files.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/about/about_page.dart';
import 'features/home/home_page.dart';
import 'features/order/order_page.dart';
import 'features/quote/quote_page.dart';
import 'features/shell/app_shell.dart';
import 'features/upload/upload_page.dart';
import 'services/notification_service.dart';
import 'theme/norcha_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reminders were built in Phase 1 and still work — they are the one thing the
  // website cannot do. Failure here must never block the app from opening: a
  // customer at the counter needs prices, not a notification permission dialog.
  try {
    await NotificationService.init();
  } catch (_) {
    // Deliberately swallowed. Notifications are a bonus, not a dependency.
  }

  runApp(const NorchaApp());
}

class NorchaApp extends StatelessWidget {
  const NorchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Light, and locked to light. The dark build was accepted once, but the
    // shop's own identity — and its website — is netela cream. See the note at
    // the top of norcha_theme.dart.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: NorchaPalette.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      title: 'Norcha Print',
      debugShowCheckedModeBanner: false,
      theme: NorchaTheme.light(),
      themeMode: ThemeMode.light,
      home: const AppShell(
        initialIndex: NorchaTab.home,
        pages: [
          HomePage(),
          QuotePage(),
          OrderPage(),
          UploadPage(),
          AboutPage(),
        ],
      ),
    );
  }
}

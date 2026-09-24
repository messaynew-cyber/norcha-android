// Norcha Print — entry point.
//
// Flutter's build looks for lib/main.dart and nowhere else. Keeping the entry
// here (rather than in a feature folder) means `flutter create .`, IDE run
// configs and anyone joining later all work without a special case. This was
// trap #3 in the README — do not move it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/quote/quote_page.dart';
import 'theme/norcha_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The app is a dark editorial design; forcing a light system UI would fight
  // the palette on every device.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NorchaPalette.void_,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const NorchaApp());
}

class NorchaApp extends StatelessWidget {
  const NorchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Google Fonts rather than the website's woff2 files: Flutter cannot load
    // woff2, and converting it needs brotli, which this ARM64 authoring device
    // cannot install. Same character — editorial serif + clean sans — a
    // different cut. Swapping in the site's exact fonts later touches no layout.
    GoogleFonts.config.allowRuntimeFetching = true;

    return MaterialApp(
      title: 'Norcha Print',
      debugShowCheckedModeBanner: false,
      theme: buildNorchaTheme(),
      home: const QuotePage(),
    );
  }
}

// Norcha Print — entry point.
//
// Flutter's build resolves lib/main.dart and nothing else. Keep it here.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/quote/quote_page.dart';
import 'theme/norcha_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: PaperPalette.ground,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const NorchaApp());
}

class NorchaApp extends StatelessWidget {
  const NorchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // EB Garamond for display: a book face, and the same family the website
    // uses. Inter for everything functional. Fetched at runtime and cached —
    // see README for why the site's woff2 files cannot be bundled.
    GoogleFonts.config.allowRuntimeFetching = true;

    return MaterialApp(
      title: 'Norcha Print',
      debugShowCheckedModeBanner: false,
      theme: buildPaperTheme(),
      home: const QuotePage(),
    );
  }
}

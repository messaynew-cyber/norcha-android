// Norcha Print — app entry.
//
// SAMPLE BUILD. This is deliberately a thin shell over the real pricing core:
// the point of this build is to prove the pipeline works end to end (authoring
// on an ARM64 phone → GitHub Actions → installable APK), and to let Feven and
// the Architect hold the quote engine in their hands.
//
// The UI here is honest, not final. If a price looks wrong, the fix belongs in
// lib/core/pricing.dart — the UI never does its own maths.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/pricing.dart';
import 'features/quote/quote_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const NorchaApp());
}

/// Palette lifted from norchaprint.com so the app and the site are visibly the
/// same shop. Cream ground, antique-gold thread, ink text.
class NorchaColors {
  static const cream = Color(0xFFF8F4EE);
  static const creamDark = Color(0xFFEFE8DD);
  static const gold = Color(0xFFA88648);
  static const ink = Color(0xFF2A241C);
  static const inkSoft = Color(0xFF6B6157);
}

class NorchaApp extends StatelessWidget {
  const NorchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Norcha Print',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: NorchaColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NorchaColors.gold,
          primary: NorchaColors.gold,
          surface: NorchaColors.cream,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: NorchaColors.cream,
          foregroundColor: NorchaColors.ink,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: NorchaColors.ink,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(color: NorchaColors.ink),
        ),
      ),
      home: const QuotePage(),
    );
  }
}

/// Shared small components — kept here so screens stay readable.
class NorchaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const NorchaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NorchaColors.gold.withOpacity(0.28)),
      ),
      child: child,
    );
  }
}

/// The temporary-price banner.
///
/// Deliberately loud and deliberately not dismissible. Every price in this app
/// is unconfirmed until Feven reads the sheet — the build should say so on the
/// screen rather than only in a code comment nobody reads.
class TemporaryPriceBanner extends StatelessWidget {
  const TemporaryPriceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Shop.pricesAreTemporary) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0xFF7A2E1E),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sample build — prices are not yet confirmed with the shop',
              style: TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

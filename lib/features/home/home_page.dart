// Norcha Print — Home.
//
// Three questions, in order: how much is a print, will it be ready before X,
// where are you. This page answers those and nothing else.
//
// THE IMAGE IS BACK, AND IT LEADS.
// The previous version was a price table with no photography, which is how a
// print studio's app ends up looking like a spreadsheet. The hero image is the
// first thing on the page and every product card carries its own photograph —
// the images were in the repo the whole time and nothing referenced them.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/holidays.dart';
import '../../core/pricing.dart';
import '../../theme/app_theme.dart';
import '../../theme/ghost_numerals.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/cloth_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../shell/app_shell.dart';

class HomePage extends StatelessWidget {
  final ThemeController themes;
  const HomePage({super.key, required this.themes});

  @override
  Widget build(BuildContext context) {
    final occasion = NorchaHolidays.current(DateTime.now());
    final families = NorchaData.products.keys.toList();

    return PageScaffold(
      chapter: 1,
      eyebrow: 'Norcha Print · Bole',
      title: 'Photo printing,\ndone properly.',
      amharic: 'የፎቶ ህትመት በቦሌ',
      ghostStyle: GhostStyle.soft,
      trailing: ThemeButton(themes: themes),
      children: [
        // The hero. Full-bleed image with the studio's name set over it and a
        // scrim, because a photograph behind text with no scrim is unreadable
        // on a bad screen in daylight — which is where this app is used.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _Hero(),
        ),

        if (occasion != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _DeadlineBanner(occasion: occasion),
          ),

        const Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 10),
          child: _SectionRule(label: 'WHAT WE MAKE'),
        ),

        for (var i = 0; i < families.length; i++)
          Padding(
            padding: EdgeInsets.fromLTRB(24, i == 0 ? 0 : 10, 24, 0),
            child: _FamilyCard(family: families[i]),
          ),

        const Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 10),
          child: _SectionRule(label: 'FIND US'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _VisitCard(),
        ),
      ],
    );
  }
}

/// The hero. The prints photograph, scrimmed, with the shop's promise set over
/// it in the display serif.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radius.lg),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/prints.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(color: c.card),
            ),
            // Scrim: strong at the bottom where the text sits, light at the top
            // so the photograph still reads.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            // The selvedge, at the top edge of the image — the site's device,
            // scaled to a card.
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 3, decoration: const BoxDecoration(gradient: Brand.selvedge)),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SAME-DAY PICKUP',
                    style: TextStyle(
                      fontFamily: NorchaTypeFace.body,
                      fontSize: 10,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your photos,\nprinted properly.',
                    style: TextStyle(
                      fontFamily: NorchaTypeFace.display,
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionRule extends StatelessWidget {
  final String label;
  const _SectionRule({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Row(
      children: [
        Text(label, style: NorchaType.sectionLabel(c)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: c.line)),
      ],
    );
  }
}

/// One product family: its photograph, its cheapest price, one tap from a quote.
class _FamilyCard extends StatelessWidget {
  final String family;
  const _FamilyCard({required this.family});

  static const _images = {
    'prints': 'assets/images/prints.jpg',
    'canvas': 'assets/images/canvas.jpg',
    'books': 'assets/images/books.jpg',
    'frames': 'assets/images/frames.jpg',
    'calendars': 'assets/images/calendar.jpg',
    'mugs': 'assets/images/mugs.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final p = NorchaData.products[family]!;
    final cheapest = p.sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b);
    final accent = Accent.forFamily(family);
    final leadLabel = p.lead == 0
        ? 'same day'
        : '${p.lead} day${p.lead == 1 ? '' : 's'}';

    return Pressable(
      onTap: () => AppShell.of(context)?.selectTab(NorchaTab.quote),
      child: ClothSurface(
        padding: EdgeInsets.zero,
        accent: accent.colour,
        child: Row(
          children: [
            // The photograph, square, clipped into the card's left edge.
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(17)), // Radius.md (18) minus the 1px edge
              child: Image.asset(
                _images[family]!,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 92,
                  height: 92,
                  color: c.groundDeep,
                  alignment: Alignment.center,
                  child: Text(
                    GeezNumeral.at(p.sizes.length),
                    style: TextStyle(
                      fontFamily: NorchaTypeFace.amharic,
                      fontSize: 26,
                      color: c.inkFaint,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label.en,
                        style: NorchaType.title(c).copyWith(fontSize: 18)),
                    const SizedBox(height: 5),
                    Text('${p.sizes.length} sizes · $leadLabel',
                        style: NorchaType.bodySmall(c)),
                    const SizedBox(height: 8),
                    Text(
                      NorchaData.money(cheapest),
                      style: NorchaType.title(c).copyWith(
                        fontSize: 19,
                        color: accent.colour,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: c.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineBanner extends StatelessWidget {
  final Occasion occasion;
  const _DeadlineBanner({required this.occasion});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final soon = occasion.daysToOrder <= 3;
    final colour = soon ? Brand.warn : Brand.action(c);

    return ClothSurface(
      accent: colour,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: colour.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_outlined, size: 18, color: colour),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(occasion.name('en'),
                    style: NorchaType.title(c).copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  occasion.daysToOrder <= 0
                      ? 'Last day to order is today'
                      : 'Order within ${occasion.daysToOrder} day'
                          '${occasion.daysToOrder == 1 ? '' : 's'}',
                  style: NorchaType.bodySmall(c).copyWith(color: colour),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return ClothSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Shop.city,
              style: NorchaType.bodySmall(c)
                  .copyWith(fontSize: 14, color: c.ink)),
          const SizedBox(height: 4),
          Text(Shop.hours, style: NorchaType.bodySmall(c)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniAction(
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                  filled: true,
                  onTap: () => launchUrl(Uri.parse('https://wa.me/${Shop.wa}'),
                      mode: LaunchMode.externalApplication),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniAction(
                  label: 'Call',
                  icon: Icons.call_outlined,
                  filled: false,
                  onTap: () => launchUrl(Uri.parse('tel:${Shop.wa}'),
                      mode: LaunchMode.externalApplication),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _MiniAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final fg = filled ? Brand.onAction(c) : Brand.action(c);

    return Material(
      color: filled ? Brand.action(c) : Colors.transparent,
      borderRadius: BorderRadius.circular(Radius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radius.sm),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radius.sm),
            border: filled ? null : Border.all(color: c.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(label,
                  style: NorchaType.bodySmall(c).copyWith(
                      color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

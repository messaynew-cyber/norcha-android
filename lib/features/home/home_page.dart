// Norcha Print — Home.
//
// WHAT THIS PAGE IS FOR
// A customer opens this at the counter or on the way there. The three questions
// they actually have, in order: (1) how much is a print, (2) will it be ready
// before X, (3) where are you. This page answers those and nothing else — a
// landing page that also tries to be a brochure gets read by nobody.
//
// The price grid is deliberately the LOUDEST thing here. It is the number one
// reason anyone opens a print shop's app, and hiding it behind a tap would be
// a design choice that costs the shop a customer.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/holidays.dart';
import '../../core/pricing.dart';
import '../../theme/netela.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/cloth_surface.dart';
import '../../widgets/motion_budget.dart';
import '../shell/app_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final occasion = NorchaHolidays.current(DateTime.now());

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          const SliverToBoxAdapter(
            child: NorchaHeader(
              eyebrow: 'Norcha Print · Bole',
              title: 'Photo printing,\ndone properly.',
              amharic: 'የፎቶ ህትመት በቦሌ',
            ),
          ),

          // The deadline card only exists when a holiday is actually close —
          // the engine returns null deliberately often. A permanent countdown
          // is noise, and noise stops being read.
          if (occasion != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _DeadlineBanner(occasion: occasion),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                children: [
                  const Text('PRICES', style: NorchaType.sectionLabel),
                  const SizedBox(width: 10),
                  Cloth.tibeb(width: 32),
                ],
              ),
            ),
          ),

          // Six families, each one tap from a real quote.
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.separated(
              itemCount: NorchaData.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final family = NorchaData.products.keys.elementAt(i);
                final p = NorchaData.products[family]!;
                return StaggeredReveal(
                  index: i,
                  child: _FamilyRow(
                    product: p,
                    accent: Accent.forFamily(family),
                    onTap: () => AppShell.of(context)?.selectTab(NorchaTab.quote),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _VisitCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// The holiday deadline. Green when comfortable, amber when it is getting
/// tight — the engine already computes how many days are left to order.
class _DeadlineBanner extends StatelessWidget {
  final Occasion occasion;
  const _DeadlineBanner({required this.occasion});

  @override
  Widget build(BuildContext context) {
    final soon = occasion.daysToOrder <= 3;
    final colour = soon ? NorchaPalette.warn : NorchaPalette.pine;

    return ClothSurface(
      accent: colour,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colour.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_outlined, size: 19, color: colour),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occasion.name('en'),
                  style: NorchaType.title.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  occasion.daysToOrder <= 0
                      ? 'Last day to order is today'
                      : 'Order within ${occasion.daysToOrder} day'
                          '${occasion.daysToOrder == 1 ? '' : 's'}',
                  style: NorchaType.bodySmall.copyWith(color: colour),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One product family, with its cheapest price visible.
///
/// Showing "from X" rather than every size is the right density for a summary
/// list: the full ladder belongs on the quote screen, where the customer is
/// actually choosing.
class _FamilyRow extends StatelessWidget {
  final Product product;
  final Accent accent;
  final VoidCallback onTap;

  const _FamilyRow({
    required this.product,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cheapest = product.sizes
        .map((s) => s.price)
        .reduce((a, b) => a < b ? a : b);

    // Built here rather than inline: a ternary nested inside a string
    // interpolation is unparseable in Dart, and the analyser is right to
    // refuse it. Readable beats clever.
    final leadLabel = product.lead == 0
        ? 'same day'
        : '${product.lead} day${product.lead == 1 ? '' : 's'}';

    return ClothSurface(
      accent: accent.colour,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.label.en,
                  style: NorchaType.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.sizes.length} sizes · $leadLabel',
                  style: NorchaType.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('from', style: NorchaType.sectionLabel),
              const SizedBox(height: 2),
              // The number, in the display serif. This is the whole point of
              // the row — a price set in serif reads as worth something.
              Text(
                NorchaData.money(cheapest),
                style: NorchaType.title.copyWith(
                  fontSize: 20,
                  color: NorchaPalette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: NorchaPalette.inkFaint),
        ],
      ),
    );
  }
}

/// Address, hours, and the two ways to reach a human.
class _VisitCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClothSurface(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VISIT', style: NorchaType.sectionLabel),
          const SizedBox(height: 12),
          Text('Norcha Print', style: NorchaType.title.copyWith(fontSize: 19)),
          const SizedBox(height: 8),
          _Fact(icon: Icons.place_outlined, text: Shop.city),
          _Fact(icon: Icons.schedule_outlined, text: Shop.hours),
          _Fact(icon: Icons.phone_outlined, text: Shop.phone),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniAction(
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                  primary: true,
                  onTap: () => launchUrl(
                    Uri.parse('https://wa.me/${Shop.wa}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniAction(
                  label: 'Call',
                  icon: Icons.call_outlined,
                  primary: false,
                  onTap: () => launchUrl(
                    Uri.parse('tel:${Shop.wa}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: NorchaPalette.inkFaint),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: NorchaType.bodySmall)),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _MiniAction({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? NorchaPalette.card : NorchaPalette.pine;
    final bg = primary ? NorchaPalette.pine : Colors.transparent;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(NorchaShape.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NorchaShape.sm),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NorchaShape.sm),
            border: primary
                ? null
                : Border.all(color: NorchaPalette.pine.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(
                label,
                style: NorchaType.bodySmall.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

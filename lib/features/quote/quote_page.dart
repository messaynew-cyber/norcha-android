// Norcha Print — the quote screen.
//
// REBUILT. The first version was a correct form and it looked like a tax
// return: chips, radio rows, a stepper, a card. This is the version worth
// showing someone.
//
// The composition is editorial. A chapter number, a gold hairline, a display
// serif headline, an image carousel, and then the number — set large, rolling,
// because a price that moves when you change quantity is doing the selling for
// you. Space is used as a signal rather than filled.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/pricing.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/gold_button.dart';
import '../deadlines/deadline_card.dart';
import '../../widgets/gold_sheet.dart';
import '../../widgets/kinetic_number.dart';
import 'product_carousel.dart';
import 'size_grid.dart';

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  String _family = 'prints';
  late String _sizeKey = NorchaData.products[_family]!.sizes.first.key;
  int _qty = 1;

  Product get _product => NorchaData.products[_family]!;
  Quote get _quote => NorchaData.quote(_family, _sizeKey, _qty)!;

  void _selectFamily(String family) {
    setState(() {
      _family = family;
      _sizeKey = NorchaData.products[family]!.sizes.first.key;
      _qty = 1;
    });
  }

  void _setQty(int v) {
    if (v < 1 || v > 10000) return;
    final prev = _quote.pct;
    setState(() => _qty = v);
    final now = _quote.pct;
    // A tier crossing is a moment — the customer just earned money by ordering
    // more. Say so, physically.
    if (now > prev) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 2200),
            backgroundColor: NorchaPalette.raisedHigh,
            content: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 17, color: NorchaPalette.goldBright),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bulk price unlocked — $now% off',
                    style: NorchaType.bodySmall.copyWith(
                      color: NorchaPalette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _sendOnWhatsApp() async {
    final q = _quote;
    final sizeLabel = _product.sizes.firstWhere((s) => s.key == _sizeKey).label;
    final msg = 'Hello Norcha Print!\n\n'
        '${_product.label.en} — $sizeLabel\n'
        'Quantity: ${q.qty}\n'
        'Quoted: ${NorchaData.money(q.total)}'
        '${q.pct > 0 ? ' (${q.pct}% bulk discount)' : ''}\n\n'
        'Sent from the Norcha app.';
    final uri = Uri.parse(
        'https://wa.me/${Shop.wa}?text=${Uri.encodeComponent(msg)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C0B0F), NorchaPalette.void_],
            stops: [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (Shop.pricesAreTemporary) const _SampleRibbon(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // ---------- MASTHEAD ----------
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'NORCHA',
                                  style: NorchaType.title.copyWith(
                                    fontSize: 20,
                                    letterSpacing: 6.5,
                                    color: NorchaPalette.goldBright,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('ፕሪንት',
                                    style: NorchaType.bodySmall.copyWith(
                                      fontSize: 13,
                                      color: NorchaPalette.textTertiary,
                                    )),
                                const Spacer(),
                                Text(
                                  'ADDIS · BOLE',
                                  style: NorchaType.mono.copyWith(
                                    fontSize: 10,
                                    letterSpacing: 2.0,
                                    color: NorchaPalette.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Hairline(opacity: 0.3),
                            const SizedBox(height: 26),
                            Text(
                              'What shall\nwe print?',
                              style: NorchaType.displayXL.copyWith(
                                fontSize: 42,
                                height: 1.04,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Fine printing, canvases and books — made in Bole, '
                              'collected the same day where we can.',
                              style: NorchaType.bodySmall.copyWith(height: 1.5),
                            ),
                            // The deadline card places itself only when an
                            // Ethiopian occasion is genuinely close. Today
                            // matters to whether you can order, so it sits
                            // above the choosing rather than at the bottom.
                            const SizedBox(height: 18),
                            DeadlineStrip(now: DateTime.now()),
                          ],
                        ),
                      ),
                    ),

                    // ---------- I. THE PIECE ----------
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(22, 34, 22, 14),
                        child: ChapterHeading(numeral: 'I', label: 'The piece'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 22),
                        child: ProductCarousel(
                          selected: _family,
                          onSelect: _selectFamily,
                        ),
                      ),
                    ),

                    // ---------- II. THE SIZE ----------
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(22, 34, 22, 14),
                        child: ChapterHeading(
                          numeral: 'II',
                          label: 'The size',
                          trailing: 'shown to scale',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverToBoxAdapter(
                        child: SizeGrid(
                          product: _product,
                          selected: _sizeKey,
                          onSelect: (k) => setState(() => _sizeKey = k),
                        ),
                      ),
                    ),

                    // ---------- III. THE QUANTITY ----------
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(22, 34, 22, 14),
                        child: ChapterHeading(numeral: 'III', label: 'How many'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: _QuantityRow(
                          qty: _qty,
                          onSet: _setQty,
                        ),
                      ),
                    ),

                    // ---------- THE SUM ----------
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
                        child: _TheSum(quote: q, sizeLabel:
                            _product.sizes.firstWhere((s) => s.key == _sizeKey).label),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
                        child: Column(
                          children: [
                            GoldButton(
                              label: 'Send this quote',
                              icon: Icons.chat_bubble_outline_rounded,
                              onPressed: _sendOnWhatsApp,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${Shop.phone}  ·  ${Shop.hours}',
                              textAlign: TextAlign.center,
                              style: NorchaType.mono.copyWith(
                                fontSize: 11,
                                color: NorchaPalette.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _leadLine(q.lead),
                              textAlign: TextAlign.center,
                              style: NorchaType.mono.copyWith(
                                fontSize: 11,
                                color: NorchaPalette.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _leadLine(int days) {
    if (days == 0) return 'ready the same day — order before ${Shop.cutoffHour}:00';
    if (days == 1) return 'ready in 1 working day';
    return 'ready in $days working days';
  }
}

/// The unconfirmed-price ribbon. Quiet, but it does not go away.
class _SampleRibbon extends StatelessWidget {
  const _SampleRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: NorchaPalette.danger.withOpacity(0.14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 14, color: NorchaPalette.warn),
          const SizedBox(width: 8),
          Text(
            'SAMPLE — PRICES NOT YET CONFIRMED',
            style: NorchaType.sectionLabel.copyWith(
              fontSize: 9.5,
              letterSpacing: 1.8,
              color: NorchaPalette.warn,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quantity — a very large number that rolls, with unobtrusive controls and
/// the tier shortcuts below it.
class _QuantityRow extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onSet;
  const _QuantityRow({required this.qty, required this.onSet});

  static const _quick = [1, 10, 50, 100, 500];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GoldSheet(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              _SquareBtn(
                icon: Icons.remove_rounded,
                onTap: () => onSet(qty - 1),
                enabled: qty > 1,
              ),
              Expanded(
                child: Center(
                  child: KineticNumber(
                    value: '$qty',
                    style: NorchaType.displayXL.copyWith(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: NorchaPalette.goldBright,
                    ),
                  ),
                ),
              ),
              _SquareBtn(
                icon: Icons.add_rounded,
                onTap: () => onSet(qty + 1),
                enabled: qty < 10000,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quick.map((n) {
            final on = n == qty;
            return GestureDetector(
              onTap: () => onSet(n),
              child: AnimatedContainer(
                duration: NorchaMotion.fast,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: on ? NorchaPalette.gold : Colors.transparent,
                  borderRadius: NorchaShape.chip,
                  border: Border.all(
                    color: on
                        ? NorchaPalette.gold
                        : NorchaPalette.gold.withOpacity(0.22),
                  ),
                ),
                child: Text(
                  '$n',
                  style: NorchaType.price.copyWith(
                    fontSize: 13,
                    color: on
                        ? NorchaPalette.void_
                        : NorchaPalette.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _SquareBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: NorchaMotion.fast,
        opacity: enabled ? 1 : 0.3,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: NorchaPalette.raisedHigh,
            borderRadius: BorderRadius.circular(NorchaShape.sm),
            border: Border.all(color: NorchaPalette.gold.withOpacity(0.16)),
          ),
          child: Icon(icon, color: NorchaPalette.goldBright, size: 22),
        ),
      ),
    );
  }
}

/// The sum. The payoff. Display serif, rolling, with the discount line only
/// when there is one — an empty "0% discount" row is noise.
class _TheSum extends StatelessWidget {
  final Quote quote;
  final String sizeLabel;
  const _TheSum({required this.quote, required this.sizeLabel});

  @override
  Widget build(BuildContext context) {
    return GoldSheet(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      radius: NorchaShape.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('THE SUM', style: NorchaType.sectionLabel),
              SizedBox(width: 10),
              Expanded(child: Hairline()),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$sizeLabel  ×  ${quote.qty}',
                style: NorchaType.bodySmall,
              ),
              Text(NorchaData.money(quote.gross),
                  style: NorchaType.mono.copyWith(
                    decoration: quote.pct > 0 ? TextDecoration.lineThrough : null,
                    color: quote.pct > 0
                        ? NorchaPalette.textTertiary
                        : NorchaPalette.textSecondary,
                  )),
            ],
          ),
          if (quote.pct > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bulk — ${quote.pct}% off',
                    style: NorchaType.bodySmall
                        .copyWith(color: NorchaPalette.success)),
                Text('− ${NorchaData.money(quote.discount)}',
                    style: NorchaType.mono
                        .copyWith(color: NorchaPalette.success)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Hairline(opacity: 0.28),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: KineticNumber(
                  value: NorchaData.money(quote.total),
                  style: NorchaType.displayXL.copyWith(
                    fontSize: 40,
                    color: NorchaPalette.goldBright,
                  ),
                ),
              ),
              Text('ETB',
                  style: NorchaType.sectionLabel.copyWith(
                    fontSize: 11,
                    color: NorchaPalette.textTertiary,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

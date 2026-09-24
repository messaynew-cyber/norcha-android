// Norcha Print — the quote screen. THE PAPER SHOP.
//
// THE ARGUMENT THIS SCREEN MAKES
// The dark version says: *we do beautiful work, take your time.* Quiet, gold,
// after hours.
//
// This says: *this is a real print shop and we know paper.* Daylight, kraft and
// ink, sample swatches, a price list set like a printed one. The customer is
// standing at a counter being shown stock, not browsing a boutique.
//
// Not an inversion of the dark theme — inverting a palette gives you a
// washed-out copy of the same idea. Different ground, different type
// (Garamond, a book face), different shadow model (a stack, not a glow),
// different corners (paper is square), and a layout that reads top-down like a
// job sheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/pricing.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/paper_sheet.dart';
import '../../widgets/stamp_button.dart';
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
    HapticFeedback.selectionClick();
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
    if (now > prev) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 2200),
            content: Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 17, color: PaperPalette.ground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bulk rate applied — $now% off',
                    style: PaperType.bodySmall.copyWith(
                      color: PaperPalette.ground,
                      fontWeight: FontWeight.w600,
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
    final si = _product.sizes.firstWhere((s) => s.key == _sizeKey);

    return Scaffold(
      backgroundColor: PaperPalette.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (Shop.pricesAreTemporary) const _UnconfirmedStrip(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ---------- SHOP PLATE ----------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Norcha',
                                style: PaperType.display.copyWith(fontSize: 30),
                              ),
                              const SizedBox(width: 8),
                              Text('ፕሪንት',
                                  style: PaperType.bodySmall.copyWith(
                                      fontSize: 13)),
                              const Spacer(),
                              Text('BOLE · ADDIS',
                                  style: PaperType.sectionLabel.copyWith(
                                      fontSize: 9.5)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('FINE PRINTING  ·  EST. BOLE',
                                  style: PaperType.sectionLabel.copyWith(
                                      fontSize: 9.5,
                                      color: PaperPalette.rust)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const RuleLine(strong: true),
                          const SizedBox(height: 26),
                          Text(
                            'Choose your\nprint, size and\nquantity.',
                            style: PaperType.displayXL.copyWith(fontSize: 38),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Photographs, canvases, books and gifts — made in Bole. '
                            'Prices include the bulk rate automatically; the more '
                            'you order, the less each one costs.',
                            style: PaperType.bodySmall.copyWith(height: 1.55),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),

                  // ---------- 1. STOCK ----------
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 30, 20, 14),
                      child: PressHeading(numeral: '1.', label: 'What you want printed'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: ProductCarousel(
                        selected: _family,
                        onSelect: _selectFamily,
                      ),
                    ),
                  ),

                  // ---------- 2. SIZE ----------
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 30, 20, 14),
                      child: PressHeading(
                        numeral: '2.',
                        label: 'Size',
                        trailing: 'shown to scale',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: SizeGrid(
                        product: _product,
                        selected: _sizeKey,
                        onSelect: (k) {
                          HapticFeedback.selectionClick();
                          setState(() => _sizeKey = k);
                        },
                      ),
                    ),
                  ),

                  // ---------- 3. QUANTITY ----------
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 30, 20, 14),
                      child: PressHeading(numeral: '3.', label: 'How many'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _QuantityBlock(qty: _qty, onSet: _setQty),
                    ),
                  ),

                  // ---------- JOB SHEET ----------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                      child: _JobSheet(
                        quote: q,
                        sizeLabel: si.label,
                        familyLabel: _product.label.en,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                      child: Column(
                        children: [
                          StampButton(
                            label: 'Send this to the shop',
                            icon: Icons.send_outlined,
                            onPressed: _sendOnWhatsApp,
                          ),
                          const SizedBox(height: 16),
                          const RuleLine(),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(Shop.phone,
                                  style: PaperType.mono.copyWith(fontSize: 11.5)),
                              Text(_leadLine(q.lead),
                                  style: PaperType.mono.copyWith(fontSize: 11.5)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(Shop.hours,
                              style: PaperType.mono.copyWith(
                                  fontSize: 11,
                                  color: PaperPalette.inkFaint)),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _leadLine(int days) {
    if (days == 0) return 'same day · before ${Shop.cutoffHour}:00';
    if (days == 1) return 'ready in 1 working day';
    return 'ready in $days working days';
  }
}

/// The unconfirmed-price strip. A printed warning notice, not a red banner —
/// this theme does not shout, it states.
class _UnconfirmedStrip extends StatelessWidget {
  const _UnconfirmedStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: PaperPalette.kraftDeep,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 14, color: PaperPalette.warn),
          const SizedBox(width: 8),
          Text(
            'SAMPLE EDITION — PRICES AWAITING THE SHOP',
            style: PaperType.sectionLabel.copyWith(
              fontSize: 9,
              letterSpacing: 1.6,
              color: PaperPalette.warn,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quantity — set as a figure on a printed form, with the bulk breaks listed
/// underneath the way a price list would print them.
class _QuantityBlock extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onSet;
  const _QuantityBlock({required this.qty, required this.onSet});

  static const _quick = [1, 10, 50, 100, 500];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PaperSheet(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              _PaperStepBtn(icon: Icons.remove, onTap: () => onSet(qty - 1), enabled: qty > 1),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: PaperMotion.fast,
                    child: Text(
                      '$qty',
                      key: ValueKey(qty),
                      style: PaperType.priceLarge.copyWith(fontSize: 46),
                    ),
                  ),
                ),
              ),
              _PaperStepBtn(icon: Icons.add, onTap: () => onSet(qty + 1), enabled: qty < 10000),
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
                duration: PaperMotion.fast,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: on ? PaperPalette.rust : PaperPalette.sheet,
                  borderRadius: PaperShape.chip,
                  border: Border.all(
                    color: on ? PaperPalette.rust : PaperPalette.rule,
                  ),
                ),
                child: Text(
                  '$n',
                  style: PaperType.price.copyWith(
                    fontSize: 13.5,
                    color: on ? PaperPalette.sheet : PaperPalette.ink,
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

class _PaperStepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _PaperStepBtn({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: PaperMotion.fast,
        opacity: enabled ? 1 : 0.32,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PaperPalette.kraft,
            borderRadius: PaperShape.card,
            border: Border.all(color: PaperPalette.ruleStrong),
          ),
          child: Icon(icon, color: PaperPalette.ink, size: 21),
        ),
      ),
    );
  }
}

/// A job sheet. This is the visual anchor of the theme: a docket the shop would
/// tear off and keep, with the line items set on rules and the total underlined
/// like a handwritten sum.
class _JobSheet extends StatelessWidget {
  final Quote quote;
  final String sizeLabel;
  final String familyLabel;
  const _JobSheet({
    required this.quote,
    required this.sizeLabel,
    required this.familyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return PaperSheet(
      elevated: true,
      radius: PaperShape.lg,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('JOB SHEET'.toUpperCase(), style: PaperType.sectionLabel),
              const Spacer(),
              Text('No. ${quote.qty.toString().padLeft(4, '0')}',
                  style: PaperType.mono.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          const RuleLine(strong: true),
          const SizedBox(height: 14),
          _row(familyLabel, sizeLabel),
          const SizedBox(height: 8),
          _row('Unit price', NorchaData.money(quote.unit)),
          const SizedBox(height: 8),
          _row('Quantity', '× ${quote.qty}'),
          const SizedBox(height: 8),
          _row('Subtotal', NorchaData.money(quote.gross),
              strikethrough: quote.pct > 0),
          if (quote.pct > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bulk rate — ${quote.pct}% off',
                    style: PaperType.bodySmall.copyWith(
                      color: PaperPalette.sage,
                      fontWeight: FontWeight.w600,
                    )),
                Text('− ${NorchaData.money(quote.discount)}',
                    style: PaperType.mono.copyWith(color: PaperPalette.sage)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const RuleLine(strong: true),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: PaperType.sectionLabel.copyWith(fontSize: 11)),
              AnimatedSwitcher(
                duration: PaperMotion.medium,
                child: Text(
                  NorchaData.money(quote.total),
                  key: ValueKey(quote.total),
                  style: PaperType.priceLarge.copyWith(fontSize: 38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool strikethrough = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: PaperType.bodySmall),
        Text(
          value,
          style: PaperType.price.copyWith(
            decoration: strikethrough ? TextDecoration.lineThrough : null,
            color: strikethrough ? PaperPalette.inkFaint : PaperPalette.ink,
          ),
        ),
      ],
    );
  }
}

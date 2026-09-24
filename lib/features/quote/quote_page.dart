// The quote screen — pick a product, pick a size, set a quantity, see the price.
//
// This is the whole reason the app exists: it works with NO INTERNET. The
// website needs a connection; a shop in Bole does not always have one, and a
// customer standing at the counter should never hear "let me check the site".

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/main.dart';
import '../../core/pricing.dart';

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
    });
  }

  void _step(int delta) {
    final next = _qty + delta;
    if (next < 1 || next > 10000) return;
    setState(() => _qty = next);
  }

  /// Hand the order to a human. This is how Bole actually buys — the app ends
  /// in a WhatsApp conversation, not a checkout form.
  Future<void> _sendOnWhatsApp() async {
    final q = _quote;
    final sizeLabel = _product.sizes.firstWhere((s) => s.key == _sizeKey).label;
    final msg = 'Hello Norcha Print! I would like:\n\n'
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
    final size = _product.sizes.firstWhere((s) => s.key == _sizeKey);

    return Scaffold(
      appBar: AppBar(title: const Text('Norcha Print')),
      body: Column(
        children: [
          const TemporaryPriceBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'What can we print for you?',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: NorchaColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bole, Addis Ababa · Mon–Sat 8:30–19:00',
                  style: TextStyle(fontSize: 13, color: NorchaColors.inkSoft),
                ),
                const SizedBox(height: 16),
                _FamilyPicker(
                  selected: _family,
                  onSelect: _selectFamily,
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Size'),
                const SizedBox(height: 8),
                _SizePicker(
                  product: _product,
                  selected: _sizeKey,
                  onSelect: (k) => setState(() => _sizeKey = k),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Quantity'),
                const SizedBox(height: 8),
                _QuantityStepper(
                  qty: _qty,
                  onStep: _step,
                  onSet: (v) => setState(() => _qty = v),
                ),
                const SizedBox(height: 20),
                _PriceBreakdown(quote: q, sizeLabel: size.label),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _sendOnWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  style: FilledButton.styleFrom(
                    backgroundColor: NorchaColors.gold,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'Send this quote on WhatsApp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Production takes ${_leadText(q.lead)}',
                    style: const TextStyle(
                        fontSize: 12.5, color: NorchaColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _leadText(int days) {
    if (days == 0) return 'same day (order before ${Shop.cutoffHour}:00)';
    if (days == 1) return '1 working day';
    return '$days working days';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: NorchaColors.inkSoft,
        ),
      );
}

class _FamilyPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _FamilyPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NorchaData.products.values.map((p) {
        final on = p.family == selected;
        return ChoiceChip(
          label: Text(p.label.en),
          selected: on,
          onSelected: (_) => onSelect(p.family),
          showCheckmark: false,
          backgroundColor: Colors.white,
          selectedColor: NorchaColors.gold.withValues(alpha: 0.16),
          side: BorderSide(
            color: on ? NorchaColors.gold : NorchaColors.gold.withValues(alpha: 0.3),
          ),
          labelStyle: TextStyle(
            color: on ? NorchaColors.ink : NorchaColors.inkSoft,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

class _SizePicker extends StatelessWidget {
  final Product product;
  final String selected;
  final ValueChanged<String> onSelect;
  const _SizePicker({
    required this.product,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: product.sizes.map((s) {
        final on = s.key == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onSelect(s.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: on
                    ? NorchaColors.gold.withValues(alpha: 0.10)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: on
                      ? NorchaColors.gold
                      : NorchaColors.gold.withValues(alpha: 0.28),
                  width: on ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    on
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 19,
                    color: on ? NorchaColors.gold : NorchaColors.inkSoft,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      s.label,
                      style: const TextStyle(
                          fontSize: 15, color: NorchaColors.ink),
                    ),
                  ),
                  Text(
                    NorchaData.money(s.price),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: on ? NorchaColors.ink : NorchaColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onStep;
  final ValueChanged<int> onSet;
  const _QuantityStepper({
    required this.qty,
    required this.onStep,
    required this.onSet,
  });

  static const _quick = [1, 10, 50, 100, 500];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepButton(icon: Icons.remove, onTap: () => onStep(-1)),
            Container(
              width: 104,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: NorchaColors.gold.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$qty',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: NorchaColors.ink,
                ),
              ),
            ),
            _StepButton(icon: Icons.add, onTap: () => onStep(1)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _quick.map((n) {
            final on = n == qty;
            return GestureDetector(
              onTap: () => onSet(n),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: on ? NorchaColors.gold : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: NorchaColors.gold.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: on ? Colors.white : NorchaColors.inkSoft,
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

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: NorchaColors.gold.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: NorchaColors.gold),
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final Quote quote;
  final String sizeLabel;
  const _PriceBreakdown({required this.quote, required this.sizeLabel});

  @override
  Widget build(BuildContext context) {
    return NorchaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${quote.unit} × ${quote.qty}',
                style: const TextStyle(
                    fontSize: 14.5, color: NorchaColors.inkSoft),
              ),
              Text(
                NorchaData.money(quote.gross),
                style: const TextStyle(
                    fontSize: 14.5, color: NorchaColors.inkSoft),
              ),
            ],
          ),
          if (quote.pct > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bulk discount (${quote.pct}%)',
                  style: const TextStyle(
                      fontSize: 14.5, color: Color(0xFF2E6B45)),
                ),
                Text(
                  '− ${NorchaData.money(quote.discount)}',
                  style: const TextStyle(
                      fontSize: 14.5, color: Color(0xFF2E6B45)),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0x33A88648)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: NorchaColors.ink,
                ),
              ),
              Text(
                NorchaData.money(quote.total),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: NorchaColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

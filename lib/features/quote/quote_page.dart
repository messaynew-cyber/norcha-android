// Norcha Print — the quote screen.
//
// THE PAGE THE APP EXISTS FOR
// Everything else is convenience. This is where a customer finds out what their
// job costs, and it has to answer three things in one screen without scrolling
// past the answer: what am I printing, how many, and what is the number.
//
// THE COMPOSITION
// Editorial, like a printed price list rather than a calculator. A chapter
// heading, a tibeb rule, the family chips, the size grid, then the quantity —
// and the TOTAL set large in the display serif, because a price that moves when
// you change quantity is doing the selling for you.
//
// WHY THE TOTAL IS PINNED
// The number is the product. Scrolling to find it is the single worst thing a
// quote screen can do, so it lives in a floating bar that never leaves.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/delivery.dart';
import '../../core/holidays.dart';
import '../../core/pricing.dart';
import '../../theme/netela.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/cloth_surface.dart';
import '../../widgets/kinetic_number.dart';
import '../shell/app_shell.dart';

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  String _family = 'prints';
  late String _sizeKey = NorchaData.products[_family]!.sizes.first.key;
  int _qty = 1;
  DateTime? _wantedBy;

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
    // Crossing a tier is a moment: the customer just earned money by ordering
    // more. Say so, physically, and say it once — see the motion budget.
    if (now > prev) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          backgroundColor: NorchaPalette.pine,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 96),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NorchaShape.sm)),
          content: Text(
            'Volume tier unlocked — ${now}% off',
            style: NorchaType.bodySmall.copyWith(
                color: NorchaPalette.card, fontWeight: FontWeight.w600),
          ),
        ));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _wantedBy ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: NorchaPalette.pine,
            surface: NorchaPalette.card,
            onSurface: NorchaPalette.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _wantedBy = picked);
  }

  Future<void> _sendOnWhatsApp() async {
    final q = _quote;
    final sizeLabel =
        _product.sizes.firstWhere((s) => s.key == _sizeKey).label;
    final assessment =
        NorchaDelivery.assess(DateTime.now(), _wantedBy, _product.lead);

    final msg = StringBuffer()
      ..writeln('Hello Norcha Print!')
      ..writeln()
      ..writeln('I would like:')
      ..writeln('• ${_product.label.en} — $sizeLabel')
      ..writeln('• Quantity: $_qty')
      ..writeln('• Estimate: ${NorchaData.money(q.total)}')
      ..writeln('• Earliest ready: ${NorchaDelivery.fmt(assessment.ready, "en")}');
    if (_wantedBy != null) {
      msg.writeln('• I need it by: ${NorchaDelivery.fmt(_wantedBy!, "en")}');
      msg.writeln(assessment.ok
          ? '• That works.'
          : '• (I know that date is tight — let me know.)');
    }

    await launchUrl(
      Uri.parse('https://wa.me/${Shop.wa}?text=${Uri.encodeComponent(msg.toString())}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;
    final assessment =
        NorchaDelivery.assess(DateTime.now(), _wantedBy, _product.lead);
    final occasion = NorchaHolidays.current(DateTime.now());
    final accent = Accent.forFamily(_family);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const NorchaHeader(
                  eyebrow: 'Build a job',
                  title: 'What are we\nprinting?',
                  amharic: 'ምን እናተም?',
                ),

                // Family.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in NorchaData.products.keys)
                        _Chip(
                          label: NorchaData.products[f]!.label.en,
                          colour: Accent.forFamily(f).colour,
                          selected: _family == f,
                          onTap: () => _selectFamily(f),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                _Label('SIZE', trailing: '${_product.lead == 0 ? 'same day' : '${_product.lead} day${_product.lead == 1 ? '' : 's'}'}'),
                const SizedBox(height: 12),

                // Size grid. Two columns, price visible on each — the customer
                // is comparing, so the numbers must be side by side.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.75,
                    ),
                    itemCount: _product.sizes.length,
                    itemBuilder: (_, i) {
                      final s = _product.sizes[i];
                      return _SizeTile(
                        size: s,
                        accent: accent,
                        selected: _sizeKey == s.key,
                        onTap: () => setState(() => _sizeKey = s.key),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 26),
                const _Label('HOW MANY'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _QuantityControl(
                    qty: _qty,
                    onChanged: _setQty,
                    accent: accent,
                  ),
                ),

                if (q.pct > 0) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '${q.pct}% volume discount applied — saving '
                      '${NorchaData.money(q.discount)}',
                      style: NorchaType.bodySmall.copyWith(
                          fontSize: 13, color: NorchaPalette.pine),
                    ),
                  ),
                ],

                const SizedBox(height: 26),
                const _Label('WHEN DO YOU NEED IT?'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _WantedBy(
                    wanted: _wantedBy,
                    assessment: assessment,
                    onPick: _pickDate,
                    onClear: () => setState(() => _wantedBy = null),
                  ),
                ),

                if (occasion != null) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClothSurface(
                      accent: occasion.daysToOrder <= 3
                          ? NorchaPalette.warn
                          : NorchaPalette.pine,
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        '${occasion.name('en')}: last day to order is '
                        '${occasion.daysToOrder <= 0 ? 'today' : 'in ${occasion.daysToOrder} days'}.',
                        style: NorchaType.bodySmall.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 26),
                _Label('THE BREAKDOWN'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClothSurface(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _Line('Unit price', NorchaData.money(q.unit)),
                        _Line('Quantity', '${q.qty}'),
                        _Line('Subtotal', NorchaData.money(q.gross)),
                        if (q.discount > 0)
                          _Line('Discount (${q.pct}%)',
                              '− ${NorchaData.money(q.discount)}',
                              highlight: true),
                      ],
                    ),
                  ),
                ),

                if (Shop.pricesAreTemporary) ...[
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _TemporaryNotice(),
                  ),
                ],
                const SizedBox(height: 90),
              ],
            ),
          ),

          // The pinned total. This never leaves the screen — the number is the
          // product, and making someone scroll to find it is the worst thing a
          // quote screen can do.
          _TotalBar(
            total: q.total,
            assessment: assessment,
            onSend: _sendOnWhatsApp,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final String? trailing;
  const _Label(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(text, style: NorchaType.sectionLabel),
          const SizedBox(width: 10),
          Cloth.tibeb(width: 26),
          const Spacer(),
          if (trailing != null)
            Text(trailing!, style: NorchaType.bodySmall.copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colour.withOpacity(0.10) : NorchaPalette.card,
      borderRadius: BorderRadius.circular(NorchaShape.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NorchaShape.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NorchaShape.pill),
            border: Border.all(
              color: selected ? colour : NorchaPalette.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: NorchaType.bodySmall.copyWith(
              fontSize: 13,
              color: selected ? colour : NorchaPalette.inkSoft,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// One size, with its price. The price is the reason this tile is worth its
/// space — a size picker without prices forces the customer to tap each one.
class _SizeTile extends StatelessWidget {
  final PrintSize size;
  final Accent accent;
  final bool selected;
  final VoidCallback onTap;

  const _SizeTile({
    required this.size,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClothSurface(
      onTap: onTap,
      accent: selected ? accent.colour : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            size.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NorchaType.bodySmall.copyWith(
              fontSize: 13,
              color: NorchaPalette.ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NorchaData.money(size.price),
            style: NorchaType.title.copyWith(fontSize: 17),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  final Accent accent;

  const _QuantityControl({
    required this.qty,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareBtn(
          icon: Icons.remove_rounded,
          onTap: qty > 1 ? () => onChanged(qty - 1) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClothSurface(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                '$qty',
                style: NorchaType.display.copyWith(fontSize: 26),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SquareBtn(
          icon: Icons.add_rounded,
          onTap: () => onChanged(qty + 1),
        ),
      ],
    );
  }
}

class _SquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SquareBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: NorchaPalette.card,
      borderRadius: BorderRadius.circular(NorchaShape.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NorchaShape.sm),
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NorchaShape.sm),
            border: Border.all(color: NorchaPalette.line),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? NorchaPalette.pine : NorchaPalette.inkFaint,
          ),
        ),
      ),
    );
  }
}

/// The requested-by date, with the engine's honest verdict.
class _WantedBy extends StatelessWidget {
  final DateTime? wanted;
  final DeliveryAssessment assessment;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _WantedBy({
    required this.wanted,
    required this.assessment,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (wanted == null) {
      return ClothSurface(
        onTap: onPick,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                size: 18, color: NorchaPalette.pine),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Pick a date (optional)',
                  style: NorchaType.bodySmall.copyWith(fontSize: 14)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: NorchaPalette.inkFaint),
          ],
        ),
      );
    }

    final ok = assessment.ok;
    final colour = ok ? NorchaPalette.pine : NorchaPalette.warn;

    String note;
    if (ok) {
      note = 'Earliest ready ${NorchaDelivery.fmt(assessment.ready, 'en')}';
      if (assessment.slack != null && assessment.slack! > 0) {
        note += ' · ${assessment.slack} working day'
            '${assessment.slack == 1 ? '' : 's'} of room';
      }
    } else {
      switch (assessment.reason) {
        case 'past':
          note = 'That date has passed.';
          break;
        case 'sunday':
          note = 'The shop is shut on Sundays.';
          break;
        default:
          note = 'That is tight — earliest ready is '
              '${NorchaDelivery.fmt(assessment.ready, 'en')}.';
      }
    }

    return ClothSurface(
      accent: colour,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.event_available_outlined : Icons.event_busy_outlined,
              size: 18, color: colour),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need it by ${NorchaDelivery.fmt(wanted!, 'en')}',
                  style: NorchaType.bodySmall.copyWith(
                      fontSize: 14,
                      color: NorchaPalette.ink,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(note, style: NorchaType.bodySmall.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded,
                size: 17, color: NorchaPalette.inkFaint),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Line(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: NorchaType.bodySmall.copyWith(fontSize: 13.5)),
          ),
          Text(
            value,
            style: NorchaType.bodySmall.copyWith(
              fontSize: 14,
              color: highlight ? NorchaPalette.pine : NorchaPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔴 Honesty marker. Every price in this app is marked temporary and must be
/// confirmed before it is shown to a real customer. This is non-dismissible on
/// purpose — a dismissible notice gets dismissed and then forgotten.
class _TemporaryNotice extends StatelessWidget {
  const _TemporaryNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NorchaPalette.goldSoft,
        borderRadius: BorderRadius.circular(NorchaShape.sm),
        border: Border.all(color: NorchaPalette.gold.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 17, color: NorchaPalette.warn),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prices are not yet confirmed by the studio. Please confirm on '
              'WhatsApp before ordering.',
              style: NorchaType.bodySmall.copyWith(
                  fontSize: 12.5, color: NorchaPalette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pinned total. The number, the ready date, and the one action that
/// matters. Deliberately not a full-width gold button — gold is ornament, and
/// a big flat gold fill would make the brand look like a discount sticker.
class _TotalBar extends StatelessWidget {
  final int total;
  final DeliveryAssessment assessment;
  final VoidCallback onSend;

  const _TotalBar({
    required this.total,
    required this.assessment,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NorchaPalette.paper,
        border: Border(top: BorderSide(color: NorchaPalette.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('TOTAL', style: NorchaType.sectionLabel),
                    const SizedBox(height: 2),
                    // KineticNumber: the total animates when it changes, so the
                    // number reads as a live thing rather than a label. This is
                    // one of the two expressive moments on this screen.
                    KineticNumber(
                      value: NorchaData.money(total),
                      style: NorchaType.display.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NorchaDelivery.readyPhrase(assessment, 'en'),
                      style: NorchaType.bodySmall.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Material(
                color: NorchaPalette.pine,
                borderRadius: BorderRadius.circular(NorchaShape.sm),
                child: InkWell(
                  onTap: onSend,
                  borderRadius: BorderRadius.circular(NorchaShape.sm),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_outlined,
                            size: 17, color: NorchaPalette.card),
                        const SizedBox(width: 9),
                        Text(
                          'Send',
                          style: NorchaType.body.copyWith(
                            color: NorchaPalette.card,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

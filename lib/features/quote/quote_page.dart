// Norcha Print — the quote screen.
//
// THE PAGE THE APP EXISTS FOR
// A customer finds out what their job costs. Three answers, one screen: what am
// I printing, how many, and what is the number.
//
// THE COMPOSITION IS EDITORIAL
// A chapter mark, the family chips, a price-visible size grid, the quantity,
// then the total set large in the display serif — because a price that moves
// when you change quantity is doing the selling for you.
//
// WHY THE TOTAL IS PINNED
// The number is the product. Making someone scroll to find it is the worst
// thing a quote screen can do, so it lives in a bar that never leaves.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/delivery.dart';
import '../../core/holidays.dart';
import '../../core/pricing.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/cloth_surface.dart';
import '../../widgets/kinetic_number.dart';
import '../../widgets/page_scaffold.dart';
import '../../theme/ghost_numerals.dart';

class QuotePage extends StatefulWidget {
  final ThemeController themes;
  const QuotePage({super.key, required this.themes});

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

  void _setQty(int v) {
    if (v < 1 || v > 10000) return;
    final prev = _quote.pct;
    setState(() => _qty = v);
    final now = _quote.pct;
    if (now > prev) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final c = NorchaColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _wantedBy ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme(
            brightness: c.isDark ? Brightness.dark : Brightness.light,
            primary: Brand.action(c),
            onPrimary: Brand.onAction(c),
            secondary: Brand.gold,
            onSecondary: c.ink,
            surface: c.card,
            onSurface: c.ink,
            error: Brand.red,
            onError: c.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _wantedBy = picked);
  }

  Future<void> _send() async {
    final q = _quote;
    final sizeLabel = _product.sizes.firstWhere((s) => s.key == _sizeKey).label;
    final a = NorchaDelivery.assess(DateTime.now(), _wantedBy, _product.lead);

    final msg = StringBuffer()
      ..writeln('Hello Norcha Print!')
      ..writeln()
      ..writeln('I would like:')
      ..writeln('• ${_product.label.en} — $sizeLabel')
      ..writeln('• Quantity: $_qty')
      ..writeln('• Estimate: ${NorchaData.money(q.total)}')
      ..writeln('• Earliest ready: ${NorchaDelivery.fmt(a.ready, "en")}');
    if (_wantedBy != null) {
      msg.writeln('• I need it by: ${NorchaDelivery.fmt(_wantedBy!, "en")}');
      msg.writeln(a.ok ? '• That works.' : '• (I know that is tight — let me know.)');
    }

    await launchUrl(
      Uri.parse('https://wa.me/${Shop.wa}?text=${Uri.encodeComponent(msg.toString())}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final q = _quote;
    final a = NorchaDelivery.assess(DateTime.now(), _wantedBy, _product.lead);
    final occasion = NorchaHolidays.current(DateTime.now());
    final accent = Accent.forFamily(_family);
    final leadLabel = _product.lead == 0
        ? 'same day'
        : '${_product.lead} day${_product.lead == 1 ? '' : 's'}';

    return PageScaffold(
      chapter: 2,
      eyebrow: 'Build a job',
      title: 'What are we\nprinting?',
      amharic: 'ምን እናተም?',
      ghostStyle: GhostStyle.outline,
      trailing: ThemeButton(themes: widget.themes),
      bottomBar: _TotalBar(
        total: q.total,
        assessment: a,
        onSend: _send,
      ),
      children: [
        // Families.
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
                  onTap: () => setState(() {
                    _family = f;
                    _sizeKey = NorchaData.products[f]!.sizes.first.key;
                    _qty = 1;
                  }),
                ),
            ],
          ),
        ),

        const SizedBox(height: 26),
        _Label(text: 'SIZE', trailing: leadLabel),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.8,
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
        const _Label(text: 'HOW MANY'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _Quantity(qty: _qty, onChanged: _setQty),
        ),

        if (q.pct > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: AnimatedSize(
              duration: Motion.fast,
              curve: Curves.easeOut,
              child: Text(
                '${q.pct}% volume discount applied — saving ${NorchaData.money(q.discount)}',
                style: NorchaType.bodySmall(c)
                    .copyWith(fontSize: 13, color: Brand.action(c)),
              ),
            ),
          ),

        const SizedBox(height: 26),
        const _Label(text: 'WHEN DO YOU NEED IT?'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _WantedBy(
            wanted: _wantedBy,
            assessment: a,
            onPick: _pickDate,
            onClear: () => setState(() => _wantedBy = null),
          ),
        ),

        if (occasion != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: ClothSurface(
              accent: occasion.daysToOrder <= 3 ? Brand.warn : Brand.action(c),
              padding: const EdgeInsets.all(15),
              child: Text(
                '${occasion.name('en')}: last day to order is '
                '${occasion.daysToOrder <= 0 ? 'today' : 'in ${occasion.daysToOrder} days'}.',
                style: NorchaType.bodySmall(c).copyWith(fontSize: 13),
              ),
            ),
          ),

        const SizedBox(height: 26),
        const _Label(text: 'THE BREAKDOWN'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClothSurface(
            child: Column(
              children: [
                _Line('Unit price', NorchaData.money(q.unit)),
                _Line('Quantity', '${q.qty}'),
                _Line('Subtotal', NorchaData.money(q.gross)),
                if (q.discount > 0)
                  _Line('Discount (${q.pct}%)',
                      '− ${NorchaData.money(q.discount)}', highlight: true),
              ],
            ),
          ),
        ),

        if (Shop.pricesAreTemporary)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: _TemporaryNotice(),
          ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final String? trailing;
  const _Label({required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(text, style: NorchaType.sectionLabel(c)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: c.line)),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(trailing!, style: NorchaType.bodySmall(c).copyWith(fontSize: 11.5)),
          ],
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
    final c = NorchaColors.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colour.withOpacity(0.10) : c.card,
          borderRadius: BorderRadius.circular(Corners.pill),
          border: Border.all(
            color: selected ? colour : c.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: NorchaType.bodySmall(c).copyWith(
            fontSize: 13,
            color: selected ? colour : c.inkSoft,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

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
    final c = NorchaColors.of(context);
    return Pressable(
      onTap: onTap,
      child: ClothSurface(
        accent: selected ? accent.colour : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              size.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NorchaType.bodySmall(c).copyWith(
                fontSize: 12.5,
                color: c.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Text(NorchaData.money(size.price),
                style: NorchaType.title(c).copyWith(fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

class _Quantity extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const _Quantity({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Row(
      children: [
        _SquareBtn(
            icon: Icons.remove_rounded,
            onTap: qty > 1 ? () => onChanged(qty - 1) : null),
        const SizedBox(width: 10),
        Expanded(
          child: ClothSurface(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              // The count is a number, so it gets the display serif. It also
              // animates, because watching the number move is what makes a
              // stepper feel responsive rather than merely functional.
              KineticNumber(
                value: '$qty',
                style: NorchaType.display(c).copyWith(fontSize: 26),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SquareBtn(icon: Icons.add_rounded, onTap: () => onChanged(qty + 1)),
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
    final c = NorchaColors.of(context);
    final enabled = onTap != null;

    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(color: c.line),
        ),
        child: Icon(icon,
            size: 20, color: enabled ? Brand.action(c) : c.inkFaint),
      ),
    );
  }
}

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
    final c = NorchaColors.of(context);

    if (wanted == null) {
      return ClothSurface(
        onTap: onPick,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 18, color: Brand.action(c)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Pick a date (optional)',
                  style: NorchaType.bodySmall(c).copyWith(fontSize: 14)),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.inkFaint),
          ],
        ),
      );
    }

    final ok = assessment.ok;
    final colour = ok ? Brand.action(c) : Brand.warn;

    String note;
    if (ok) {
      note = 'Earliest ready ${NorchaDelivery.fmt(assessment.ready, 'en')}';
      final slack = assessment.slack;
      if (slack != null && slack > 0) {
        note += ' · $slack working day${slack == 1 ? '' : 's'} of room';
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

    return AnimatedSwitcher(
      duration: Motion.fast,
      child: ClothSurface(
        key: ValueKey('$wanted-$ok'),
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
                  Text('Need it by ${NorchaDelivery.fmt(wanted!, 'en')}',
                      style: NorchaType.bodySmall(c).copyWith(
                          fontSize: 14,
                          color: c.ink,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(note, style: NorchaType.bodySmall(c).copyWith(fontSize: 12.5)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 17, color: c.inkFaint),
              ),
            ),
          ],
        ),
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
    final c = NorchaColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: NorchaType.bodySmall(c).copyWith(fontSize: 13.5)),
          ),
          Text(
            value,
            style: NorchaType.bodySmall(c).copyWith(
              fontSize: 14,
              color: highlight ? Brand.action(c) : c.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemporaryNotice extends StatelessWidget {
  const _TemporaryNotice();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.isDark ? c.cardRaised : Brand.goldSoft,
        borderRadius: BorderRadius.circular(Corners.sm),
        border: Border.all(color: Brand.gold.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 17, color: Brand.warn),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prices are not yet confirmed by the studio. Please confirm on '
              'WhatsApp before ordering.',
              style: NorchaType.bodySmall(c)
                  .copyWith(fontSize: 12.5, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pinned total. The number, the ready date, the one action that matters.
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
    final c = NorchaColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.ground,
        border: Border(top: BorderSide(color: c.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TOTAL', style: NorchaType.sectionLabel(c)),
                    const SizedBox(height: 2),
                    KineticNumber(
                      value: NorchaData.money(total),
                      style: NorchaType.display(c).copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 2),
                    Text(NorchaDelivery.readyPhrase(assessment, 'en'),
                        style: NorchaType.bodySmall(c).copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Pressable(
                onTap: onSend,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Brand.action(c),
                    borderRadius: BorderRadius.circular(Corners.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_outlined,
                          size: 17, color: Brand.onAction(c)),
                      const SizedBox(width: 9),
                      Text(
                        'Send',
                        style: NorchaType.body(c).copyWith(
                          color: Brand.onAction(c),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

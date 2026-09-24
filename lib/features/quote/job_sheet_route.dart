// The job sheet, as its own destination.
//
// WHY THIS IS A ROUTE AND NOT A SECTION
// The total used to be the bottom of a long scroll — you had to arrive at it.
// A quote is the moment the customer came for, so it gets its own surface,
// reached deliberately and dismissed deliberately. It also gives the shop
// something to hand over: a docket with a reference on it.
//
// The transition is a spring, not the default Android slide, because this is
// the one navigation in the app that should feel like a physical object being
// raised.

import 'package:flutter/material.dart';

import '../../core/pricing.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/gold_sheet.dart';
import '../../widgets/kinetic_number.dart';

/// A spring-driven route. Overshoots very slightly on entry — enough to feel
/// alive, not enough to look broken.
class JobSheetRoute extends PageRouteBuilder {
  final Widget child;

  JobSheetRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (_, animation, __, c) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.14),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: animation, child: c),
            );
          },
        );
}

class JobSheetPage extends StatelessWidget {
  final Quote quote;
  final String familyLabel;
  final String sizeLabel;
  final VoidCallback onSend;

  const JobSheetPage({
    super.key,
    required this.quote,
    required this.familyLabel,
    required this.sizeLabel,
    required this.onSend,
  });

  /// A human-quotable reference. Not the order code — that is issued by the
  /// shop when an order is actually placed. This is just so a customer can say
  /// "I had a quote for..." on the phone.
  String get _reference {
    final seed = '${familyLabel.length}${sizeLabel.length}'
        '${quote.qty}${quote.total}';
    final n = seed.hashCode.abs() % 100000;
    return 'Q-${n.toString().padLeft(5, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NorchaPalette.void_,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 21),
                    color: NorchaPalette.textSecondary,
                  ),
                  const Spacer(),
                  Text('QUOTE', style: NorchaType.sectionLabel),
                  const SizedBox(width: 10),
                  Text(_reference,
                      style: NorchaType.mono.copyWith(
                          fontSize: 11.5, color: NorchaPalette.gold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
                children: [
                  Text('Your quote', style: NorchaType.display),
                  const SizedBox(height: 8),
                  Text(
                    'Show this at the counter or send it to us on WhatsApp. '
                    'The reference lets us find it again.',
                    style: NorchaType.bodySmall.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  const Hairline(opacity: 0.3),
                  const SizedBox(height: 22),
                  _line('Item', familyLabel),
                  _line('Size', sizeLabel),
                  _line('Unit price', NorchaData.money(quote.unit)),
                  _line('Quantity', '× ${quote.qty}'),
                  _line('Subtotal', NorchaData.money(quote.gross),
                      struck: quote.pct > 0),
                  if (quote.pct > 0)
                    _line('Bulk rate', '− ${NorchaData.money(quote.discount)}',
                        accent: NorchaPalette.success,
                        label: 'Bulk rate — ${quote.pct}% off'),
                  const SizedBox(height: 16),
                  const Hairline(opacity: 0.28),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL', style: NorchaType.sectionLabel),
                      KineticNumber(
                        value: NorchaData.money(quote.total),
                        style: NorchaType.displayXL.copyWith(
                          fontSize: 38,
                          color: NorchaPalette.goldBright,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  GoldSheet(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 18, color: NorchaPalette.gold),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            _leadText(quote.lead),
                            style: NorchaType.bodySmall.copyWith(
                                fontSize: 12.5,
                                color: NorchaPalette.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: GoldButton(
                label: 'Send to the shop',
                icon: Icons.send_rounded,
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value,
      {bool struck = false, Color? accent}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: NorchaType.bodySmall.copyWith(
                color: accent ?? NorchaPalette.textSecondary,
                fontWeight: accent != null ? FontWeight.w600 : null,
              )),
          Text(
            value,
            style: NorchaType.price.copyWith(
              decoration: struck ? TextDecoration.lineThrough : null,
              color: accent ??
                  (struck ? NorchaPalette.textTertiary : NorchaPalette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  static String _leadText(int days) {
    if (days == 0) return 'Ready the same day — order before ${Shop.cutoffHour}:00';
    if (days == 1) return 'Ready in 1 working day';
    return 'Ready in $days working days';
  }
}

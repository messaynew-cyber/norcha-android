// The holiday deadline card.
//
// THE MOST VALUABLE THING IN THIS APP
// The website can show this too, but the app can do it in the one place the
// web cannot reach: a notification, in the customer's pocket, before they
// forget. That is the whole reason a Norcha app exists beyond convenience.
//
// It shows itself ONLY when an occasion is close (see NorchaHolidays.current).
// A permanently-visible countdown is noise, and noise stops being read — so
// when there is nothing to say, this renders nothing at all.

import 'package:flutter/material.dart';

import '../../core/holidays.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/gold_sheet.dart';

class DeadlineCard extends StatelessWidget {
  final Occasion occasion;
  final VoidCallback? onTap;

  const DeadlineCard({super.key, required this.occasion, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final m = NorchaHolidays.message(occasion, lang);
    // The overdue case is not a warning, it is an apology — it must not be
    // dressed as urgency in the shop's colour.
    final overdue = occasion.daysToOrder < 0;
    final urgent = occasion.daysToOrder <= 1;
    final accent = overdue
        ? NorchaPalette.textTertiary
        : (urgent ? NorchaPalette.warn : NorchaPalette.gold);

    return GoldSheet(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      radius: NorchaShape.md,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 13, top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Icon(
              overdue ? Icons.hourglass_disabled : Icons.event_outlined,
              size: 17,
              color: accent,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.message,
                  style: NorchaType.label.copyWith(fontSize: 14.5, height: 1.3),
                ),
                const SizedBox(height: 3),
                Text(
                  m.sub,
                  style: NorchaType.bodySmall.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      NorchaHolidays.fmt(occasion.orderBy, lang),
                      style: NorchaType.mono.copyWith(
                        fontSize: 11.5,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text('·  order by',
                        style: NorchaType.mono.copyWith(
                            fontSize: 11, color: NorchaPalette.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The card, or nothing. Encapsulates the "should we show anything at all"
/// decision so the page never has to think about it.
class DeadlineStrip extends StatelessWidget {
  final DateTime now;
  final int horizonDays;
  final void Function(Occasion)? onTap;

  const DeadlineStrip({
    super.key,
    required this.now,
    this.horizonDays = NorchaHolidays.defaultHorizon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final occasion = NorchaHolidays.current(now, horizonDays: horizonDays);
    if (occasion == null) return const SizedBox.shrink();
    return DeadlineCard(
      occasion: occasion,
      onTap: onTap == null ? null : () => onTap!(occasion),
    );
  }
}

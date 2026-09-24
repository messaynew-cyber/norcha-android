// A sheet of paper. The fundamental surface of this theme.
//
// On the dark version a card was a lifted surface with a gold hairline — depth
// from light. Here depth is a *stack*: a hard offset shadow with no blur, the
// way one sheet sits on another on a desk. And the top edge carries the faint
// line a guillotine leaves when it cuts.

import 'package:flutter/material.dart';

import '../theme/norcha_theme.dart';

class PaperSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.elevated = false,
    this.radius = PaperShape.md,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? PaperPalette.sheet,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: PaperPalette.rule, width: 1),
        boxShadow: elevated ? PaperElevation.lifted : PaperElevation.sheet,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// A printer's caption. Number, rule, small-caps label — the device that makes
/// a screen read as *set* rather than laid out.
class PressHeading extends StatelessWidget {
  final String numeral;
  final String label;
  final String? trailing;

  const PressHeading({
    super.key,
    required this.numeral,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              numeral,
              style: PaperType.title.copyWith(
                fontSize: 13,
                color: PaperPalette.rust,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label.toUpperCase(), style: PaperType.sectionLabel)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(trailing!, style: PaperType.mono.copyWith(fontSize: 11.5)),
            ],
          ],
        ),
        const SizedBox(height: 7),
        const RuleLine(),
      ],
    );
  }
}

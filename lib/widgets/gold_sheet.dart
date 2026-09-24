// The surface everything sits on.
//
// On a near-black ground a drop shadow does nothing, so a "card" is really a
// slightly lifted surface with a gold hairline catching the top edge — the
// same trick a foil-stamped invitation uses.

import 'package:flutter/material.dart';

import '../theme/norcha_theme.dart';

class GoldSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final double radius;
  final VoidCallback? onTap;

  const GoldSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.elevated = false,
    this.radius = NorchaShape.md,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NorchaPalette.raised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: NorchaPalette.gold.withOpacity(elevated ? 0.28 : 0.14),
        ),
        boxShadow: elevated ? NorchaElevation.lifted : NorchaElevation.soft,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// A numbered chapter heading — the editorial device that makes a screen feel
/// composed rather than assembled. Roman numeral, hairline, label.
class ChapterHeading extends StatelessWidget {
  final String numeral;
  final String label;
  final String? trailing;

  const ChapterHeading({
    super.key,
    required this.numeral,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          numeral,
          style: NorchaType.title.copyWith(
            fontSize: 15,
            color: NorchaPalette.gold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(label.toUpperCase(), style: NorchaType.sectionLabel),
              const SizedBox(width: 10),
              const Expanded(child: Hairline()),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Text(trailing!, style: NorchaType.mono),
        ],
      ],
    );
  }
}

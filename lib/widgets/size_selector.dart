// Size selection — proportional rectangles, not a list of strings.
//
// RESTORED FROM THE ORIGINAL DARK BUILD, deliberately and intact, because the
// reasoning in it was the best thing about that design and I lost it in the
// rewrite.
//
// WHY SHAPES AND NOT TEXT
// The first design was a radio list of "20 × 30 cm" strings. That makes the
// customer do the geometry in their head — nobody can picture what 40 × 60
// feels like on a wall, but everybody can look at a rectangle and know it is
// the one they want. Showing the shape at its TRUE aspect ratio turns the size
// choice into a visual one, which is the only kind most people can actually
// make.
//
// Each tile therefore carries three things at once: the SHAPE (at real
// proportion), the LABEL (for the people who do think in numbers), and the
// PRICE. The shape is the part that does the selling; the other two are there
// so nobody has to ask.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/lang.dart';
import '../core/pricing.dart';
import '../theme/app_theme.dart';

/// Aspect ratio (w/h) per size key. Anything unlisted falls back to a neutral
/// 4:5 so the grid never has a hole in it — a missing shape is worse than an
/// approximate one.
const Map<String, double> _kAspect = {
  'std-10x15': 10 / 15, 'std-13x18': 13 / 18, 'std-15x21': 15 / 21,
  'std-20x30': 20 / 30, 'std-a4': 21 / 30, 'std-a3': 30 / 42,
  'canvas-30x40': 30 / 40, 'canvas-40x60': 40 / 60,
  'canvas-60x80': 60 / 80, 'canvas-80x120': 80 / 120,
  'frame-a4': 21 / 30, 'frame-a3': 30 / 42, 'frame-40x60': 40 / 60,
  'cal-a4': 21 / 30, 'cal-a3': 30 / 42,
};

class SizeSelector extends StatelessWidget {
  final Product product;
  final String selected;
  final ValueChanged<String> onSelect;
  final NorchaLang lang;

  const SizeSelector({
    super.key,
    required this.product,
    required this.selected,
    required this.onSelect,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        // Taller than wide: the shape needs vertical room to read at these
        // aspect ratios. Squashing it defeats the whole device.
        childAspectRatio: 1.35,
      ),
      itemCount: product.sizes.length,
      itemBuilder: (_, i) {
        final s = product.sizes[i];
        return SizeTile(
          size: s,
          aspect: _kAspect[s.key] ?? 0.8,
          selected: s.key == selected,
          onTap: () => onSelect(s.key),
        );
      },
    );
  }
}

class SizeTile extends StatelessWidget {
  final PrintSize size;
  final double aspect;
  final bool selected;
  final VoidCallback onTap;

  const SizeTile({
    super.key,
    required this.size,
    required this.aspect,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(Corners.md),
          border: Border.all(
            color: selected ? Brand.action(c) : c.line,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Brand.action(c).withOpacity(c.isDark ? 0.22 : 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // ── the shape, at true proportion ──────────────────────────
            SizedBox(
              width: 44,
              height: 58,
              child: Center(
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Curves.easeOutCubic,
                  width: aspect >= 1 ? 40 : 40 * aspect / 1.0,
                  height: aspect >= 1 ? 40 / aspect : 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? Brand.action(c).withOpacity(0.16)
                        : c.groundDeep,
                    border: Border.all(
                      color: selected ? Brand.action(c) : c.line,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  // The check only appears once chosen, so the tile stays
                  // quiet until it has something to say.
                  child: selected
                      ? Icon(Icons.check_rounded,
                          size: 13, color: Brand.action(c))
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── label and price ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    size.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: NorchaType.bodySmall(c).copyWith(
                      fontSize: 12.5,
                      color: c.ink,
                      height: 1.25,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    NorchaData.money(size.price),
                    style: NorchaType.title(c).copyWith(
                      fontSize: 16,
                      color: selected ? Brand.action(c) : c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Size selection — a set of paper swatches.
//
// In the dark theme this grid showed each size as an outlined rectangle glowing
// against black. Here the tile *is* the paper: cream stock, a cut edge, a hard
// shadow. The customer is looking at a sample book, which is exactly the
// decision they are making.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pricing.dart';
import '../../theme/norcha_theme.dart';

const Map<String, double> _kAspect = {
  'std-10x15': 10 / 15,
  'std-13x18': 13 / 18,
  'std-15x21': 15 / 21,
  'std-20x30': 20 / 30,
  'std-a4': 21 / 30,
  'std-a3': 30 / 42,
  'canvas-30x40': 30 / 40,
  'canvas-40x60': 40 / 60,
  'canvas-60x80': 60 / 80,
  'canvas-80x120': 80 / 120,
  'frame-a4': 21 / 30,
  'frame-a3': 30 / 42,
  'frame-40x60': 40 / 60,
  'cal-a4': 21 / 30,
  'cal-a3': 30 / 42,
};

class SizeGrid extends StatelessWidget {
  final Product product;
  final String selected;
  final ValueChanged<String> onSelect;
  const SizeGrid({
    super.key,
    required this.product,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: product.sizes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        final s = product.sizes[i];
        return _Swatch(
          size: s,
          aspect: _kAspect[s.key] ?? 0.8,
          selected: s.key == selected,
          onTap: () => onSelect(s.key),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  final PrintSize size;
  final double aspect;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({
    required this.size,
    required this.aspect,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PaperMotion.medium,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? PaperPalette.kraft : PaperPalette.sheet,
          borderRadius: BorderRadius.circular(PaperShape.md),
          border: Border.all(
            color: selected ? PaperPalette.rust : PaperPalette.rule,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected ? PaperElevation.lifted : PaperElevation.sheet,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // The sample swatch. Plain Container, explicit size, no
              // LayoutBuilder and no Expanded — the grid tile already has
              // bounded dimensions, so re-measuring inside it was redundant.
              SizedBox(
                height: 78,
                child: Center(
                  child: Container(
                      // .toDouble() is not decoration: num.clamp() returns num,
                      // and Dart will not narrow it to double implicitly. An
                      // explicit conversion is the honest way to say 'this is a
                      // double', rather than a cast that could hide a real bug.
                      width: (78 * aspect).clamp(20.0, 62.0).toDouble(),
                      height: (78.0).clamp(20.0, 78.0).toDouble(),
                      decoration: BoxDecoration(
                        color: PaperPalette.sheet,
                        border: Border.all(
                          color: selected
                              ? PaperPalette.rustDeep
                              : PaperPalette.ruleStrong,
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                size.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: PaperType.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: PaperPalette.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                NorchaData.money(size.price),
                style: PaperType.price.copyWith(
                  fontSize: 14,
                  color: selected ? PaperPalette.rust : PaperPalette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Size selection — proportional rectangles, not a radio list.
//
// The first design used a radio-button list of six "10 × 15 cm" strings. That
// makes the customer do the geometry in their head. Showing the shape at the
// real aspect ratio means the choice is visual: people pick the size they can
// picture, which is the size they actually want.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pricing.dart';
import '../../theme/norcha_theme.dart';

/// Aspect ratios (w/h) for the known size keys. Anything unlisted falls back
/// to a neutral 4:5 so the grid never has a hole in it.
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
        childAspectRatio: 1.16,
      ),
      itemBuilder: (context, i) {
        final s = product.sizes[i];
        return _SizeTile(
          size: s,
          aspect: _kAspect[s.key] ?? 0.8,
          selected: s.key == selected,
          onTap: () => onSelect(s.key),
        );
      },
    );
  }
}

class _SizeTile extends StatelessWidget {
  final PrintSize size;
  final double aspect;
  final bool selected;
  final VoidCallback onTap;
  const _SizeTile({
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
        duration: NorchaMotion.medium,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? NorchaPalette.raisedHigh : NorchaPalette.ink,
          borderRadius: BorderRadius.circular(NorchaShape.md),
          border: Border.all(
            color: selected
                ? NorchaPalette.gold
                : NorchaPalette.gold.withOpacity(0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The printed shape, at true proportion.
                  LayoutBuilder(
                    builder: (context, c) {
                      const maxH = 54.0;
                      final maxW = c.maxWidth * 0.42;
                      var w = maxH * aspect;
                      var h = maxH;
                      if (w > maxW) {
                        w = maxW;
                        h = maxW / aspect;
                      }
                      return AnimatedContainer(
                        duration: NorchaMotion.medium,
                        curve: Curves.easeOutCubic,
                        width: w,
                        height: h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: selected
                                ? NorchaPalette.goldBright
                                : NorchaPalette.textTertiary,
                            width: 1.2,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: NorchaPalette.gold.withOpacity(0.28),
                                    blurRadius: 14,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      size.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NorchaType.bodySmall.copyWith(
                        fontSize: 12,
                        color: selected
                            ? NorchaPalette.textPrimary
                            : NorchaPalette.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NorchaData.money(size.price),
                    style: NorchaType.price.copyWith(
                      fontSize: 14,
                      color: selected
                          ? NorchaPalette.goldBright
                          : NorchaPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: NorchaPalette.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: NorchaPalette.void_),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

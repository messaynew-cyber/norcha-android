// The product picker — a horizontal carousel of image cards.
//
// Replaces the choice-chip row, which was the single worst thing in the first
// design. A chip reading "Canvas prints" tells you a word. A card showing the
// actual product, at 200pt wide with the name set in serif underneath, tells
// you what you are buying.
//
// Images are the website's own product photography, copied into assets.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pricing.dart';
import '../../theme/norcha_theme.dart';

/// Family key → asset image. The website's photography, reused so the app and
/// the site show the same objects.
const Map<String, String> kFamilyImages = {
  'prints': 'assets/images/prints.jpg',
  'canvas': 'assets/images/canvas.jpg',
  'books': 'assets/images/books.jpg',
  'frames': 'assets/images/frames.jpg',
  'calendars': 'assets/images/calendar.jpg',
  'mugs': 'assets/images/mugs.jpg',
};

class ProductCarousel extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const ProductCarousel({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  late final PageController _controller;
  late final List<Product> _items;

  @override
  void initState() {
    super.initState();
    _items = NorchaData.products.values.toList();
    final idx = _items.indexWhere((p) => p.family == widget.selected);
    _controller = PageController(viewportFraction: 0.62, initialPage: idx < 0 ? 0 : idx);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      child: PageView.builder(
        controller: _controller,
        itemCount: _items.length,
        padEnds: false,
        onPageChanged: (i) {
          HapticFeedback.selectionClick();
          widget.onSelect(_items[i].family);
        },
        itemBuilder: (context, i) {
          final p = _items[i];
          return _ProductCard(
            product: p,
            selected: p.family == widget.selected,
            onTap: () => _controller.animateToPage(
              i,
              duration: PaperMotion.medium,
              curve: Curves.easeOutCubic,
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool selected;
  final VoidCallback onTap;
  const _ProductCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = kFamilyImages[product.family];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PaperMotion.medium,
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PaperShape.lg),
          border: Border.all(
            color: selected
                ? PaperPalette.rust
                : PaperPalette.rust.withOpacity(0.10),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected ? PaperElevation.lifted : PaperElevation.soft,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PaperShape.lg - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (img != null)
                Image.asset(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: PaperPalette.kraft))
              else
                const ColoredBox(color: PaperPalette.kraft),
              // Scrim so the serif stays legible over any photograph.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x22000000), Color(0xE608070A)],
                    stops: [0.35, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.label.en,
                      style: PaperType.title.copyWith(
                        fontSize: 19,
                        color: selected
                            ? PaperPalette.rustBright
                            : PaperPalette.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'from ${NorchaData.money(product.sizes.first.price)}',
                      style: PaperType.mono.copyWith(
                        fontSize: 11.5,
                        color: PaperPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: PaperPalette.rust,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: PaperPalette.rust.withOpacity(0.5),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 16, color: PaperPalette.ink),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

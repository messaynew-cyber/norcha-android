// Product detail — the photography, at full size, where it can actually sell.
//
// WHY THIS PAGE EXISTS
// In the carousel the product images are 150pt thumbnails behind a scrim. That
// wastes the best asset the shop has: real photographs of real work. A customer
// deciding between a canvas and a framed print is making a visual decision, and
// a visual decision deserves a full-bleed image.
//
// Reached with a Hero animation from the carousel card, so the photograph
// appears to lift out of the row into place. That continuity is the whole point
// of the transition — it tells you that what you tapped is what you are now
// looking at.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pricing.dart';
import '../../theme/norcha_theme.dart';
import 'product_carousel.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final VoidCallback onChoose;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final img = kFamilyImages[product.family];
    return Scaffold(
      backgroundColor: NorchaPalette.void_,
      body: CustomScrollView(
        slivers: [
          // ---- full-bleed hero, with the back button floating over it ----
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: NorchaPalette.void_,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: _GlassCircle(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (img != null)
                    Hero(
                      tag: 'product-${product.family}',
                      child: Image.asset(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: NorchaPalette.raisedHigh),
                      ),
                    )
                  else
                    const ColoredBox(color: NorchaPalette.raisedHigh),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x6608070A),
                          Color(0x0008070A),
                          Color(0xCC08070A),
                          Color(0xFF08070A),
                        ],
                        stops: [0.0, 0.35, 0.82, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.label.en, style: NorchaType.display),
                  const SizedBox(height: 6),
                  Text(product.label.am,
                      style: NorchaType.bodySmall.copyWith(fontSize: 14)),
                  const SizedBox(height: 14),
                  const Hairline(opacity: 0.26),
                  const SizedBox(height: 16),
                  Text(
                    _blurb(product.family),
                    style: NorchaType.bodySmall.copyWith(height: 1.6, fontSize: 13.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 15, color: NorchaPalette.gold),
                      const SizedBox(width: 8),
                      Text(_lead(product.lead),
                          style: NorchaType.mono.copyWith(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Row(
                    children: [
                      Text('AVAILABLE SIZES', style: NorchaType.sectionLabel),
                      SizedBox(width: 10),
                      Expanded(child: Hairline()),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ---- every size, with its price, as a scannable list ----
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverList.builder(
              itemCount: product.sizes.length,
              itemBuilder: (context, i) {
                final s = product.sizes[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _SizeRow(size: s),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
              child: _ChooseButton(
                label: 'Choose a size',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onChoose();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _blurb(String family) {
    switch (family) {
      case 'prints':
        return 'Standard photographic prints on archival paper, cut to size. '
            'The everyday one — school photos, family frames, passport sets.';
      case 'canvas':
        return 'Gallery-wrapped canvas over a solid frame, printed with '
            'pigment ink that holds its colour. Hung without glass.';
      case 'books':
        return 'Hardcover photo books, printed on lay-flat stock so a spread '
            'opens flat. Weddings, first years, graduations, memorials.';
      case 'frames':
        return 'Framed prints, mounted and ready to hang. A4 through 40 × 60.';
      case 'calendars':
        return 'Wall calendars from your own photographs — twelve months, '
            'printed and bound. Popular as a New Year gift.';
      case 'mugs':
        return 'Photo mugs printed with a dye that survives a dishwasher. '
            'Sold in packs of one, two or four.';
      default:
        return '';
    }
  }

  static String _lead(int days) {
    if (days == 0) return 'Same day';
    if (days == 1) return '1 working day';
    return '$days working days';
  }
}

/// A translucent circular button that floats over photography. Used instead of
/// a plain icon so it stays visible over both light and dark images.
class _GlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NorchaPalette.void_.withOpacity(0.55),
          border: Border.all(color: NorchaPalette.gold.withOpacity(0.28)),
        ),
        child: Icon(icon, size: 20, color: NorchaPalette.textPrimary),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final PrintSize size;
  const _SizeRow({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: NorchaPalette.raised,
        borderRadius: NorchaShape.card,
        border: Border.all(color: NorchaPalette.gold.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(size.label, style: NorchaType.body.copyWith(fontSize: 14.5)),
          ),
          Text(NorchaData.money(size.price),
              style: NorchaType.price.copyWith(color: NorchaPalette.goldBright)),
        ],
      ),
    );
  }
}

class _ChooseButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChooseButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: NorchaShape.chip,
          border: Border.all(color: NorchaPalette.gold.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(label,
              style: NorchaType.label.copyWith(
                  fontSize: 15, color: NorchaPalette.goldBright)),
        ),
      ),
    );
  }
}

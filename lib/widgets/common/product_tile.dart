import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../models/tire.dart';
import '../../views/product_view.dart';

/// Universal Reusable Product Tile.
/// Fixed-size consistent rectangle: Picture (top) -> Name (middle) -> Price in PHP (bottom).
/// Tapping navigates to ProductView.
class ProductTile extends StatelessWidget {
  final Tire tire;
  final VoidCallback? onTap;

  const ProductTile({
    super.key,
    required this.tire,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => ProductView(tire: tire)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141B2D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderDark),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Picture (Top) with discount badge and stock state
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: tire.isOutOfStock ? 0.38 : 1.0,
                      child: Hero(
                        tag: 'tire-${tire.id}',
                        child: Image.asset(
                          tire.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.album_rounded,
                                color: AppTheme.textSecondary,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (tire.isOutOfStock)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.accentOrange.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '-${tire.discountPercentage}%',
                        style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 2. Name (Middle): Brand + Model
            Text(
              tire.brand.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              tire.model,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // 3. Price (Bottom) in PHP (₱)
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    tire.formattedPrice,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (tire.originalPriceInPhp != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      tire.formattedOriginalPrice,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

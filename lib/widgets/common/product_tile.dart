import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../models/tire.dart';
import '../../views/product_view.dart';

/// Product card used in every grid: image, name and price.
/// Tapping opens the product page.
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
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderDark),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with stock badge
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
                                color: AppTheme.inputBg,
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
                    const Positioned(
                      top: 0,
                      left: 0,
                      child: Text(
                        'SOLD OUT',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Brand and model
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
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Price
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderDark,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    tire.formattedPrice,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ pc',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
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

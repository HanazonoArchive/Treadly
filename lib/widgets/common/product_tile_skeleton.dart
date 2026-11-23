import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Loading placeholder with the same layout as ProductTile.
class ProductTileSkeleton extends StatefulWidget {
  const ProductTileSkeleton({super.key});

  static Widget grid({int count = 6}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) => const ProductTileSkeleton(),
    );
  }

  @override
  State<ProductTileSkeleton> createState() => _ProductTileSkeletonState();
}

class _ProductTileSkeletonState extends State<ProductTileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.04, end: 0.12).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final shimmerColor = const Color(0xFFE2E8F0).withValues(alpha: 0.4 + (_shimmerAnim.value * 5).clamp(0.0, 0.6));

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderDark),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Brand
              Container(
                width: 50,
                height: 9,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),

              // Name
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),

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
                child: Container(
                  width: 70,
                  height: 16,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

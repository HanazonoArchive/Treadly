import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';
import '../../core/app_theme.dart';
import '../../models/tire.dart';
import '../../views/product_view.dart';

/// Best seller carousel on Home (top 5), with page dots.
class TopBestsellersCard extends StatelessWidget {
  const TopBestsellersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Obx(() {
        if (controller.isLoading.value) {
          return Container(
            height: 170,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.accentOrange),
            ),
          );
        }

        final bestsellers = controller.topBestsellers;
        if (bestsellers.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 170,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderDark,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: controller.pageController,
                itemCount: bestsellers.length,
                onPageChanged: controller.onSlideChanged,
                itemBuilder: (context, index) {
                  final tire = bestsellers[index];
                  return _buildSlide(tire, index + 1);
                },
              ),

              // Page dots
              Positioned(
                bottom: 12,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(bestsellers.length, (index) {
                    final isActive = controller.currentSlide.value == index;
                    return GestureDetector(
                      onTap: () => controller.setSlide(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 5),
                        width: isActive ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.accentOrange
                              : AppTheme.borderDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSlide(Tire tire, int rank) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(() => ProductView(tire: tire)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Text
          Expanded(
            flex: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Best Seller #$rank',
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),

                Text(
                  tire.brand.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),

                Text(
                  tire.model,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      tire.formattedPrice,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/ pc',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Image
          Expanded(
            flex: 45,
            child: Center(
              child: Transform.rotate(
                angle: 0.1, // subtle angled perspective
                child: Image.asset(
                  tire.imageAsset,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.album_rounded,
                        color: AppTheme.textSecondary,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';
import '../../core/app_theme.dart';
import '../../views/product_view.dart';
import '../common/product_tile.dart';
import '../common/product_tile_skeleton.dart';

/// 2-Column Product Grid for Home Showcase.
/// Reuses universal ProductTile and ProductTileSkeleton.
class HomeProductGrid extends StatelessWidget {
  const HomeProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Products',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Products Grid (Pure Showcase)
          Obx(() {
            if (controller.isLoading.value) {
              return ProductTileSkeleton.grid(count: 6);
            }

            final items = controller.tires;
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Text(
                  'No tires available',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78, // Consistent rectangle
              ),
              itemBuilder: (context, index) {
                final tire = items[index];
                return ProductTile(
                  tire: tire,
                  onTap: () {
                    Get.to(() => ProductView(tire: tire));
                  },
                );
              },
            );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

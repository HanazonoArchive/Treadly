import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cart/cart_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/app_theme.dart';
import 'product_view.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: const BoxDecoration(
                color: AppTheme.headerDark,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderDark, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Text(
                      'My Cart (${cartController.totalItemCount})',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (cartController.items.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: cartController.clearCart,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Cart Items List / Empty State
            Expanded(
              child: Obx(() {
                if (cartController.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 40,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Explore our catalog and find the right tires for your vehicle.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Get.find<NavigationController>().changeTab(0); // Go to Home
                            },
                            child: const Text(
                              'Start Shopping',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: cartController.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartController.items[index];
                    final tire = item.tire;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Tire Thumbnail
                          GestureDetector(
                            onTap: () => Get.to(() => ProductView(tire: tire)),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                tire.imageAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.album_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tire.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tire.size,
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.isSetOfFour
                                            ? AppTheme.accentOrange.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.isSetOfFour ? 'Set of 4 (-10%)' : 'Single Tire',
                                        style: TextStyle(
                                          color: item.isSetOfFour
                                              ? AppTheme.accentOrange
                                              : const Color(0xFF94A3B8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.formattedTotalPrice,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    // Quantity Stepper
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.borderDark),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              cartController.updateQuantity(index, item.quantity - 1);
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 14, color: Colors.white),
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              cartController.updateQuantity(index, item.quantity + 1);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),

            // Bottom Checkout Summary (if items present)
            Obx(() {
              if (cartController.items.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.headerDark,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderDark, width: 1.5),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cartController.formattedSubtotal,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          cartController.processCheckout();
                        },
                        child: const Text(
                          'Checkout',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

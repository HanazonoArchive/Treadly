import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cart/cart_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/search/search_controller.dart';
import '../core/app_theme.dart';
import '../views/search_input_view.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController nav = Get.find<NavigationController>();
    final CartController cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);

    return Obx(
      () => NavigationBar(
        selectedIndex: nav.currentTab.value,
        onDestinationSelected: (index) {
          if (index == 1) {
            // When user taps Search on the bottom bar, open the dedicated search input screen (Shopee-style)
            final searchController = Get.isRegistered<SearchCatalogController>()
                ? Get.find<SearchCatalogController>()
                : null;
            Get.to(() => SearchInputView(
                  initialQuery: searchController?.searchQuery.value ?? '',
                ));
          } else {
            nav.changeTab(index);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Obx(() {
              final count = cartController.totalItemCount;
              final isIndicating = cartController.hasRecentAddition.value;
              return AnimatedScale(
                scale: isIndicating ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Badge(
                  isLabelVisible: count > 0,
                  backgroundColor: AppTheme.accentOrange,
                  textColor: Colors.black,
                  label: Text(
                    '$count',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: isIndicating ? AppTheme.accentOrange : null,
                  ),
                ),
              );
            }),
            selectedIcon: Obx(() {
              final count = cartController.totalItemCount;
              return Badge(
                isLabelVisible: count > 0,
                backgroundColor: AppTheme.accentOrange,
                textColor: Colors.black,
                label: Text(
                  '$count',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                ),
                child: const Icon(Icons.shopping_cart),
              );
            }),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}



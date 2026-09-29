import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../widgets/app_bottom_nav.dart';
import 'search_view.dart';
import 'wishlist_view.dart';
import 'cart_view.dart';
import 'profile_view.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final NavigationController nav = Get.put(NavigationController());

  static const List<Widget> _pages = [
    SafeArea(child: Center(child: Text('Home Catalog Screen'))),
    SearchView(),
    WishlistView(),
    CartView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: nav.currentTab.value.clamp(0, _pages.length - 1),
          children: _pages,
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}



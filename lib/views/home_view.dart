import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_feed_view.dart';
import 'inquiries_view.dart';
import 'profile_view.dart';
import 'search_view.dart';
import 'shop/shop_dashboard_view.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final NavigationController nav = Get.put(NavigationController());

  static const List<Widget> _pages = [
    HomeFeedView(),
    SearchView(),
    InquiriesView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      // 2-System Architecture triggered by account email domain:
      // Accounts with @treadly.com are Shop Staff and see the Shop Desk Portal.
      // All other accounts (or guests) see the Client Tire Retail App.
      if (!auth.isGuest.value && auth.isStaff) {
        return const ShopDashboardView();
      }

      return Scaffold(
        body: Obx(
          () => IndexedStack(
            index: nav.currentTab.value.clamp(0, _pages.length - 1),
            children: _pages,
          ),
        ),
        bottomNavigationBar: const AppBottomNav(),
      );
    });
  }
}

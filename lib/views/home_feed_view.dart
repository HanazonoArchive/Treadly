import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home/home_controller.dart';
import '../core/app_theme.dart';
import '../widgets/home/home_action_grid.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_product_grid.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/top_bestsellers_card.dart';

/// Tab 0: Home Catalog Feed
/// Clean, simple, and practical shopping experience:
/// 1. TREADLY Brand Wordmark
/// 2. Search Bar with Filter
/// 3. Top 5 Bestsellers Box (left-to-right slide with bottom-right indicator circles)
/// 4. Fixed 4-Column Action Buttons (Flash Sale, Deals, Save Big, Set of 4)
/// 5. Consistent Rectangular Products Grid (Picture -> Name -> Price in PHP)
class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure HomeController is initialized
    Get.put(HomeController(), permanent: true);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accentOrange,
          backgroundColor: AppTheme.surfaceDark,
          onRefresh: () async {
            await Get.find<HomeController>().loadTires();
          },
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Brand Header
                HomeHeader(),

                // 2. Search Bar
                HomeSearchBar(),

                // 3. Top 5 Bestsellers Single Box
                TopBestsellersCard(),

                // 4. Fixed Row/Column Action Buttons
                HomeActionGrid(),

                // 5. Products Grid
                HomeProductGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home/home_controller.dart';
import '../core/app_theme.dart';
import '../widgets/home/home_action_grid.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_product_grid.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/top_bestsellers_card.dart';

/// Home tab: header, search bar, best sellers, category shortcuts and
/// product grid. Pull down to reload the catalog.
class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key});

  @override
  Widget build(BuildContext context) {
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
                HomeHeader(),

                HomeSearchBar(),

                TopBestsellersCard(),

                HomeActionGrid(),

                HomeProductGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

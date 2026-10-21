import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/navigation_controller.dart';
import '../../controllers/search/search_controller.dart';
import '../../core/app_theme.dart';

/// Top Search Bar on Home feed:
/// Directs the user to Tab 1 (Search view) with pre-keywords.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: GestureDetector(
        onTap: () {
          final searchController = Get.isRegistered<SearchCatalogController>()
              ? Get.find<SearchCatalogController>()
              : Get.put(SearchCatalogController());
          searchController.clearSearchQuery(resetCategory: true);
          if (Get.isRegistered<NavigationController>()) {
            Get.find<NavigationController>().changeTab(1);
          }
          searchController.focusSearchField();
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: const Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search brand, model, size (e.g. 225/45 R18)...',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

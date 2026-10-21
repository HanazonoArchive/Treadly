import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/search/search_controller.dart';
import '../core/app_theme.dart';
import '../views/product_view.dart';
import '../widgets/common/product_tile.dart';
import '../widgets/common/product_tile_skeleton.dart';

/// Tab 1: Search & Filter Catalog View.
/// - Before typing/searching: Opens search with pre-keywords (Recent & Popular searches).
/// - When typing or selecting a keyword: Shows search results, sort, category filters & products.
class SearchView extends StatelessWidget {
  const SearchView({super.key});

  static const List<String> _categories = [
    'All',
    'Flash Sale',
    'Deals',
    'Save Big',
    'Set of 4',
  ];

  static IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.relevance:
        return Icons.auto_awesome_rounded;
      case SortOption.latest:
        return Icons.access_time_rounded;
      case SortOption.topSales:
        return Icons.local_fire_department_rounded;
      case SortOption.priceHighToLow:
        return Icons.arrow_downward_rounded;
      case SortOption.priceLowToHigh:
        return Icons.arrow_upward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SearchCatalogController controller = Get.put(SearchCatalogController());

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar with interactive search input
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.headerDark,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderDark, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  // Return / Back Button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.accentOrange,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final hasQuery = controller.searchQuery.value.isNotEmpty ||
                          controller.selectedCategory.value != 'All';
                      if (hasQuery) {
                        controller.clearSearchQuery(resetCategory: true);
                      } else {
                        if (Get.isRegistered<NavigationController>()) {
                          Get.find<NavigationController>().changeTab(0);
                        } else {
                          Get.back();
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 10),

                  // Active Search Box
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accentOrange.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller.textController,
                              focusNode: controller.searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onChanged: (val) {
                                controller.onSearchChanged(val);
                              },
                              onSubmitted: (val) {
                                controller.submitSearch(val);
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search brand, model, size...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          Obx(() {
                            if (controller.searchQuery.value.isEmpty &&
                                controller.textController.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return GestureDetector(
                              onTap: () {
                                controller.clearSearchQuery(resetCategory: true);
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 16,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Trailing Action: Sort button when searching; "Search" submit button when pre-search
                  Obx(() {
                    final bool isSearchActive = controller.searchQuery.value.trim().isNotEmpty ||
                        controller.selectedCategory.value != 'All';

                    if (isSearchActive) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          _buildSortButton(context, controller),
                        ],
                      );
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            controller.submitSearch(controller.textController.text);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: const Text(
                              'Search',
                              style: TextStyle(
                                color: AppTheme.accentOrange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // Body: Pre-Keywords OR Search Results
            Expanded(
              child: Obx(() {
                final bool isSearchActive = controller.searchQuery.value.trim().isNotEmpty ||
                    controller.selectedCategory.value != 'All';

                if (!isSearchActive) {
                  return _buildPreKeywordsView(controller);
                }

                return _buildSearchResultsView(context, controller);
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Pre-Keywords View: Shows recent searches & popular searches before typing/searching
  Widget _buildPreKeywordsView(SearchCatalogController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches Section
          Obx(() {
            final recents = controller.recentSearches;
            if (recents.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Searches',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.clearRecentSearches,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFF64748B),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recents.map((keyword) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => controller.selectKeyword(keyword),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                keyword,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => controller.removeRecentSearch(keyword),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),

          // Popular Searches Section
          const Text(
            'Popular Searches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SearchCatalogController.popularSearches.map((keyword) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => controller.selectKeyword(keyword),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.borderDark,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: AppTheme.accentOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        keyword,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 2. Search Results View: Shows category chips, filters banner, and products grid
  Widget _buildSearchResultsView(BuildContext context, SearchCatalogController controller) {
    return Column(
      children: [
        // Category Chips (All, Flash Sale, Deals, Save Big, Set of 4) + Right Filter Button
        Container(
          color: AppTheme.headerDark,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Obx(() {
                          final isSelected = controller.selectedCategory.value == cat;
                          return GestureDetector(
                            onTap: () => controller.selectCategory(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentOrange
                                    : AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accentOrange
                                      : AppTheme.borderDark,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Dedicated Filter Button
              GestureDetector(
                onTap: controller.openFilterSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        color: AppTheme.accentOrange,
                        size: 18,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Filter',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Active Filters Banner (shows if custom sizing or sorting is active)
        Obx(() {
          if (!controller.hasActiveFilters) return const SizedBox.shrink();

          final isCustomSort = controller.sortOption.value != SortOption.relevance;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCustomSort
                      ? '${controller.searchResults.length} Tires • ${controller.sortOption.value.label}'
                      : '${controller.searchResults.length} Tires Found',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: controller.clearAllFilters,
                  child: const Text(
                    'Reset Filters',
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Products Grid
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: ProductTileSkeleton.grid(count: 6),
              );
            }

            final results = controller.searchResults;
            if (results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 54,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No tires match your criteria',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Try clearing your filters or search keywords.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: results.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final tire = results[index];
                return ProductTile(
                  tire: tire,
                  onTap: () {
                    Get.to(() => ProductView(
                          tire: tire,
                          initialSetOfFour: controller.selectedCategory.value == 'Set of 4',
                        ));
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }

  /// Sort dropdown button
  Widget _buildSortButton(BuildContext context, SearchCatalogController controller) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: AppTheme.surfaceElevated,
      ),
      child: PopupMenuButton<SortOption>(
        tooltip: 'Sort by',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        color: AppTheme.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.borderDark, width: 1.2),
        ),
        onSelected: controller.setSortOption,
        itemBuilder: (BuildContext context) {
          return SortOption.values.map((SortOption option) {
            final isSelected = controller.sortOption.value == option;
            return PopupMenuItem<SortOption>(
              value: option,
              height: 44,
              child: Row(
                children: [
                  Icon(
                    _getSortIcon(option),
                    size: 16,
                    color: isSelected
                        ? AppTheme.accentOrange
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accentOrange : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppTheme.accentOrange,
                      size: 18,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Obx(() {
          final isCustomSort = controller.sortOption.value != SortOption.relevance;
          return Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isCustomSort
                  ? AppTheme.accentOrange.withValues(alpha: 0.15)
                  : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCustomSort
                    ? AppTheme.accentOrange
                    : AppTheme.borderDark,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.swap_vert_rounded,
                  color: AppTheme.accentOrange,
                  size: 22,
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: isCustomSort ? AppTheme.accentOrange : const Color(0xFF94A3B8),
                  size: 18,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

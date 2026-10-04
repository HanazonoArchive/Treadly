import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/search/search_controller.dart';
import '../core/app_theme.dart';
import '../views/product_view.dart';
import '../views/search_input_view.dart';
import '../widgets/common/product_tile.dart';
import '../widgets/common/product_tile_skeleton.dart';

/// Tab 1: Search & Filter Catalog View.
/// Features a dedicated top app bar matching the reference design:
/// - Row 1: Return button + Search Box + Outside Up/Down Sort Icon
/// - Row 2: Exactly 3 buttons (All, Flash Sale, Deals) + Dedicated Filter Button at far right
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
            // Dedicated Top Header Bar (like a bottom navigation bar)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF101625),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderDark, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  // Row 1: Return Button + Search Box + Outside Up/Down Sort Icon
                  Row(
                    children: [
                      // Return Button (at left side)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.accentOrange,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          // Return to Home tab (Tab 0)
                          Get.find<NavigationController>().changeTab(0);
                        },
                      ),
                      const SizedBox(width: 10),

                      // Dedicated Search Box (in the middle) - reflects search query & opens SearchInputView on tap
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => SearchInputView(
                              initialQuery: controller.searchQuery.value,
                            ));
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF141B2D),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.accentOrange.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF64748B),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Obx(() {
                                    final q = controller.searchQuery.value;
                                    return Text(
                                      q.isEmpty ? 'Search brand, model, size...' : q,
                                      style: TextStyle(
                                        color: q.isEmpty ? const Color(0xFF64748B) : Colors.white,
                                        fontSize: 13,
                                        fontWeight: q.isEmpty ? FontWeight.w400 : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }),
                                ),
                                Obx(() {
                                  if (controller.searchQuery.value.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      controller.clearSearchQuery();
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
                      ),
                      const SizedBox(width: 10),

                      // Relevance / Sort Drop Box (Outside the search bar)
                      Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: const Color(0xFF141B2D),
                        ),
                        child: PopupMenuButton<SortOption>(
                          tooltip: 'Sort by',
                          position: PopupMenuPosition.under,
                          offset: const Offset(0, 6),
                          color: const Color(0xFF141B2D),
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
                                    : const Color(0xFF141B2D),
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
                                  Icon(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Categories (All, Flash Sale, Deals, Save Big, Set of 4) + Right Filter Button
                  Row(
                    children: [
                      // Scrollable category chips
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
                                            : const Color(0xFF141B2D),
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

                      // Dedicated Filter Button at the right part
                      GestureDetector(
                        onTap: controller.openFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_alt_outlined,
                                color: AppTheme.accentOrange,
                                size: 18,
                              ),
                              const SizedBox(height: 2),
                              const Text(
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

            // Products Grid using reusable ProductTile and ProductTileSkeleton
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
        ),
      ),
    );
  }
}

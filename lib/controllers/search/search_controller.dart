import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../models/tire.dart';
import '../../services/tire_repository.dart';

enum SortOption {
  relevance,
  latest,
  topSales,
  priceHighToLow,
  priceLowToHigh,
}

extension SortOptionExt on SortOption {
  String get label {
    switch (this) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.latest:
        return 'Latest';
      case SortOption.topSales:
        return 'Top Sales';
      case SortOption.priceHighToLow:
        return 'Sort by Price: High to Low';
      case SortOption.priceLowToHigh:
        return 'Sort by Price: Low to High';
    }
  }
}

class SearchCatalogController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxList<Tire> allTires = <Tire>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final Rx<SortOption> sortOption = SortOption.relevance.obs;

  // Sizing filter states
  final Rx<int?> selectedWidth = Rx<int?>(null);
  final Rx<int?> selectedRatio = Rx<int?>(null);
  final Rx<int?> selectedRim = Rx<int?>(null);
  final RxBool inStockOnly = false.obs;

  // Recent search queries for Shopee-style search input screen
  final RxList<String> recentSearches = <String>[
    'Michelin Pilot Sport 5',
    '225/45 R18',
    'Bridgestone Potenza',
    'Summer tires',
  ].obs;

  final TextEditingController textController = TextEditingController();

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    recentSearches.remove(trimmed);
    recentSearches.insert(0, trimmed);
    if (recentSearches.length > 10) {
      recentSearches.removeLast();
    }
  }

  void removeRecentSearch(String query) {
    recentSearches.remove(query);
  }

  void clearRecentSearches() {
    recentSearches.clear();
  }

  @override
  void onInit() {
    super.onInit();
    loadTires();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> loadTires() async {
    isLoading.value = true;
    try {
      final loadedTires = await TireRepository.instance.fetchTires();
      allTires.assignAll(loadedTires);
    } catch (e) {
      debugPrint('[SearchCatalogController] Error loading tires: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Called when redirected from Home page or SearchInputView
  void applyExternalSearch({String query = '', String category = 'All', bool openFilter = false}) {
    final trimmedQuery = query.trim();
    searchQuery.value = trimmedQuery;
    textController.text = trimmedQuery;
    if (trimmedQuery.isNotEmpty) {
      addRecentSearch(trimmedQuery);
    }

    if (category.isNotEmpty) {
      selectedCategory.value = category;
    }
    if (openFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openFilterSheet();
      });
    }
  }

  /// Clears the search text and optionally resets the category filter to 'All'
  void clearSearchQuery({bool resetCategory = false}) {
    searchQuery.value = '';
    textController.clear();
    if (resetCategory) {
      selectedCategory.value = 'All';
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query.trim();
  }

  void selectCategory(String cat) {
    selectedCategory.value = cat;
  }

  /// Sets the sort option directly from the dropdown / popup menu
  void setSortOption(SortOption option) {
    sortOption.value = option;
  }

  /// Toggles through available sort options (fallback)
  void toggleSortOrder() {
    final nextIndex = (sortOption.value.index + 1) % SortOption.values.length;
    sortOption.value = SortOption.values[nextIndex];
  }

  void clearAllFilters() {
    searchQuery.value = '';
    textController.clear();
    selectedCategory.value = 'All';
    selectedWidth.value = null;
    selectedRatio.value = null;
    selectedRim.value = null;
    inStockOnly.value = false;
    sortOption.value = SortOption.relevance;
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategory.value != 'All' ||
      selectedWidth.value != null ||
      selectedRatio.value != null ||
      selectedRim.value != null ||
      inStockOnly.value ||
      sortOption.value != SortOption.relevance;

  /// Computed Results list
  List<Tire> get searchResults {
    var list = allTires.toList();

    // 1. Text Search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((t) {
        return t.fullName.toLowerCase().contains(q) ||
            t.size.toLowerCase().contains(q) ||
            t.brand.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q);
      }).toList();
    }

    // 2. In-Stock Only filter
    if (inStockOnly.value) {
      list = list.where((t) => !t.isOutOfStock).toList();
    }

    // 3. Category filters: All, Flash Sale, Deals, Save Big, Set of 4
    if (selectedCategory.value == 'Flash Sale') {
      list = list.where((t) => t.originalPrice != null && !t.isOutOfStock).toList();
    } else if (selectedCategory.value == 'Deals') {
      list = list.where((t) => t.originalPrice != null).toList();
    } else if (selectedCategory.value == 'Save Big') {
      list = list.where((t) => t.originalPrice != null).toList();
      list.sort((a, b) {
        final savingsA = (a.originalPriceInPhp ?? a.priceInPhp) - a.priceInPhp;
        final savingsB = (b.originalPriceInPhp ?? b.priceInPhp) - b.priceInPhp;
        return savingsB.compareTo(savingsA);
      });
    } else if (selectedCategory.value == 'Set of 4') {
      list = list.where((t) => t.stock >= 4).toList();
    }

    // 4. Sizing specifications
    if (selectedWidth.value != null) {
      list = list.where((t) => t.width == selectedWidth.value).toList();
    }
    if (selectedRatio.value != null) {
      list = list.where((t) => t.aspectRatio == selectedRatio.value).toList();
    }
    if (selectedRim.value != null) {
      list = list.where((t) => t.rimSize == selectedRim.value).toList();
    }

    // 4. Sort
    switch (sortOption.value) {
      case SortOption.relevance:
        // Default catalog ranking
        break;
      case SortOption.latest:
        list.sort((a, b) {
          final yearA = a.dotYear ?? 2020;
          final yearB = b.dotYear ?? 2020;
          final comp = yearB.compareTo(yearA);
          if (comp != 0) return comp;
          return b.reviewsCount.compareTo(a.reviewsCount);
        });
        break;
      case SortOption.topSales:
        list.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
        break;
      case SortOption.priceHighToLow:
        list.sort((a, b) => b.priceInPhp.compareTo(a.priceInPhp));
        break;
      case SortOption.priceLowToHigh:
        list.sort((a, b) => a.priceInPhp.compareTo(b.priceInPhp));
        break;
    }

    return list;
  }

  /// Opens sizing filter bottom sheet
  void openFilterSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.borderDark, width: 1.5),
          ),
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Tire Sizing',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      selectedWidth.value = null;
                      selectedRatio.value = null;
                      selectedRim.value = null;
                      inStockOnly.value = false;
                      Get.back();
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: AppTheme.accentOrange, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // In-Stock Only Switch
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: inStockOnly.value
                        ? AppTheme.accentOrange.withValues(alpha: 0.45)
                        : AppTheme.borderDark,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.inventory_2_outlined, color: AppTheme.accentOrange, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'In-Stock Tires Only',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: inStockOnly.value,
                      activeThumbColor: AppTheme.accentOrange,
                      activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                      inactiveThumbColor: AppTheme.textSecondary,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                      onChanged: (val) => inStockOnly.value = val,
                    ),
                  ],
                ),
              ),

              // Width selector
              const Text('Width (mm)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [205, 215, 225, 235, 245, 265].map((w) {
                  final isSelected = selectedWidth.value == w;
                  return ChoiceChip(
                    label: Text('$w'),
                    selected: isSelected,
                    selectedColor: AppTheme.accentOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: AppTheme.bgDark,
                    onSelected: (val) {
                      selectedWidth.value = val ? w : null;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Rim size selector
              const Text('Rim Diameter (inches)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [16, 17, 18, 19, 20].map((r) {
                  final isSelected = selectedRim.value == r;
                  return ChoiceChip(
                    label: Text('$r"'),
                    selected: isSelected,
                    selectedColor: AppTheme.accentOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: AppTheme.bgDark,
                    onSelected: (val) {
                      selectedRim.value = val ? r : null;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

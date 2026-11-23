import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/tire.dart';
import '../../services/tire_repository.dart';
import '../../widgets/search/tire_sizing_studio_sheet.dart';

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

  /// Whether search has been explicitly submitted (allows empty search to load all tires)
  final RxBool isSearchSubmitted = false.obs;

  bool get isSearchActive =>
      isSearchSubmitted.value ||
      searchQuery.isNotEmpty ||
      selectedCategory.value != 'All' ||
      selectedWidth.value != null ||
      selectedRatio.value != null ||
      selectedRim.value != null ||
      inStockOnly.value;

  // Recent search queries for search input screen
  final RxList<String> recentSearches = <String>[
    'Michelin Pilot Sport 5',
    '225/45 R18',
    'Bridgestone Potenza',
    'Summer tires',
  ].obs;

  static const List<String> popularSearches = [
    'Michelin Pilot Sport 5',
    '225/45 R18',
    '245/40 R18',
    'Bridgestone Potenza',
    'Pirelli P Zero',
    'Continental Extreme Contact',
    'Summer tires',
    'Run-Flat',
    'Set of 4',
  ];

  final TextEditingController textController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  void focusSearchField() {
    searchFocusNode.requestFocus();
  }

  void selectKeyword(String keyword) {
    textController.text = keyword;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    searchQuery.value = keyword;
    isSearchSubmitted.value = true;
    addRecentSearch(keyword);
  }

  void submitSearch(String query) {
    final trimmed = query.trim();
    searchQuery.value = trimmed;
    isSearchSubmitted.value = true;
    if (trimmed.isNotEmpty) {
      addRecentSearch(trimmed);
    }
  }

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
    searchFocusNode.dispose();
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
    isSearchSubmitted.value = true;
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
    isSearchSubmitted.value = false;
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
    isSearchSubmitted.value = false;
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
        final matchesCars = t.compatibleCars != null &&
            t.compatibleCars!.any((c) => c.toLowerCase().contains(q));
        return t.fullName.toLowerCase().contains(q) ||
            t.size.toLowerCase().contains(q) ||
            t.brand.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            matchesCars;
      }).toList();
    }

    // 2. In-Stock Only filter
    if (inStockOnly.value) {
      list = list.where((t) => !t.isOutOfStock).toList();
    }

    // 3. Category filters: All, Set of 4, Performance, All-Season, SUV & 4x4
    if (selectedCategory.value == 'Set of 4') {
      list = list.where((t) => t.stock >= 4).toList();
    } else if (selectedCategory.value == 'Performance') {
      list = list.where((t) {
        final cat = t.category.toLowerCase();
        final full = t.fullName.toLowerCase();
        return cat.contains('performance') ||
            cat.contains('sport') ||
            cat.contains('track') ||
            full.contains('sport') ||
            full.contains('potenza') ||
            full.contains('p zero');
      }).toList();
    } else if (selectedCategory.value == 'All-Season') {
      list = list.where((t) {
        final season = t.season.toLowerCase();
        final cat = t.category.toLowerCase();
        // All-season and all-weather tires, plus non-summer touring tires.
        // Summer tires are never listed as All-Season.
        if (season.contains('summer')) return false;
        return season.contains('all') ||
            cat.contains('touring') ||
            cat.contains('all-season');
      }).toList();
    } else if (selectedCategory.value == 'SUV & 4x4') {
      list = list.where((t) {
        final cat = t.category.toLowerCase();
        final full = t.fullName.toLowerCase();
        // Match whole words only: a bare contains('at') used to catch names
        // like "Cinturato" and "Marathon".
        return cat.contains('suv') ||
            cat.contains('terrain') ||
            cat.contains('4x4') ||
            cat.contains('truck') ||
            full.contains('terrain') ||
            RegExp(r'\b(suv|4x4|a/t|m/t)\b').hasMatch(full);
      }).toList();
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

  /// Opens interactive sizing studio & blueprint visualizer bottom sheet
  void openFilterSheet() {
    Get.bottomSheet(
      const TireSizingStudioSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

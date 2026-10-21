import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/search/search_controller.dart';
import '../core/app_theme.dart';

/// Dedicated Shopee-style Search Input View.
/// Contains:
/// - Top bar: Return button + Autofocused Search Field + Search action button
/// - Body: Recent keywords chips (with clear option) + Popular searches
/// On submit: Saves keyword, navigates to SearchView (Tab 1), and reflects query at the top.
class SearchInputView extends StatefulWidget {
  final String initialQuery;

  const SearchInputView({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<SearchInputView> createState() => _SearchInputViewState();
}

class _SearchInputViewState extends State<SearchInputView> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  static const List<String> _popularSearches = [
    'Michelin Pilot Sport 5',
    '225/45 R18',
    '245/40 R18',
    'Bridgestone Potenza',
    'Pirelli P Zero',
    'Continental Extreme Contact',
    'Summer tires',
    'Run-Flat',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    // Select all text if initialQuery was provided so user can easily replace it
    if (widget.initialQuery.isNotEmpty) {
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialQuery.length,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final searchController = Get.isRegistered<SearchCatalogController>()
        ? Get.find<SearchCatalogController>()
        : Get.put(SearchCatalogController(), permanent: true);

    searchController.applyExternalSearch(query: trimmed);

    // Switch to Search View (Tab 1)
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().changeTab(1);
    }

    // Dismiss this screen to return to the catalog
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final searchController = Get.isRegistered<SearchCatalogController>()
        ? Get.find<SearchCatalogController>()
        : Get.put(SearchCatalogController(), permanent: true);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Return Button + Search Box + Search Text Button
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.headerDark,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderDark, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              child: Row(
                children: [
                  // Return Button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.accentOrange,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 10),

                  // Search Box with Autofocus
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accentOrange.withValues(alpha: 0.6),
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
                              controller: _textController,
                              focusNode: _focusNode,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _submitSearch,
                              onChanged: (_) => setState(() {}),
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
                          if (_textController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _textController.clear();
                                setState(() {});
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Search Submit Button (Shopee style)
                  GestureDetector(
                    onTap: () => _submitSearch(_textController.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: const Text(
                        'Search',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content below: Recent searches & Popular searches (fits above keyboard)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Searches Section
                    Obx(() {
                      final recents = searchController.recentSearches;
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
                                onTap: searchController.clearRecentSearches,
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
                                  onTap: () => _submitSearch(keyword),
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
                                          onTap: () => searchController.removeRecentSearch(keyword),
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
                      children: _popularSearches.map((keyword) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _submitSearch(keyword),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

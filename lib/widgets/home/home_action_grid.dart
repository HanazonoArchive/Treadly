import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/navigation_controller.dart';
import '../../controllers/search/search_controller.dart';
import '../../core/app_theme.dart';

/// Fixed 4-column action buttons grid (NO swiping needed).
/// Tapping redirects to Tab 1 (SearchView) with that category pre-filtered.
class HomeActionGrid extends StatelessWidget {
  const HomeActionGrid({super.key});

  static const List<_ActionItemData> _items = [
    _ActionItemData(
      label: 'Flash Sale',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFEF4444),
    ),
    _ActionItemData(
      label: 'Deals',
      icon: Icons.local_offer_rounded,
      color: AppTheme.accentOrange,
    ),
    _ActionItemData(
      label: 'Save Big',
      icon: Icons.savings_rounded,
      color: Color(0xFF10B981),
    ),
    _ActionItemData(
      label: 'Set of 4',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF00E5FF),
    ),
  ];

  void _redirectToSearchCategory(String category) {
    final searchController = Get.isRegistered<SearchCatalogController>()
        ? Get.find<SearchCatalogController>()
        : Get.put(SearchCatalogController());

    searchController.applyExternalSearch(category: category, query: '');
    Get.find<NavigationController>().changeTab(1); // Switch to Tab 1 (Search Tab)
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        children: _items.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _redirectToSearchCategory(item.label),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141B2D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderDark,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFCBD5E1),
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionItemData {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionItemData({
    required this.label,
    required this.icon,
    required this.color,
  });
}

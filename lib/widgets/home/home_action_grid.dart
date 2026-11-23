import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/navigation_controller.dart';
import '../../controllers/search/search_controller.dart';
import '../../core/app_theme.dart';

/// Category shortcuts on Home; each opens Search with that category.
class HomeActionGrid extends StatelessWidget {
  const HomeActionGrid({super.key});

  static const List<_ActionItemData> _items = [
    _ActionItemData(
      label: 'Set of 4',
      icon: Icons.directions_car_rounded,
      color: AppTheme.accentOrange,
    ),
    _ActionItemData(
      label: 'Performance',
      icon: Icons.speed_rounded,
      color: Color(0xFF38BDF8),
    ),
    _ActionItemData(
      label: 'All-Season',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFF10B981),
    ),
    _ActionItemData(
      label: 'SUV & 4x4',
      icon: Icons.terrain_rounded,
      color: Color(0xFFA855F7),
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
                        color: AppTheme.surfaceDark,
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
                        color: AppTheme.textPrimary,
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
